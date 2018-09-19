#requires -Modules PowerNSX

<#
.SYNOPSIS
    PowerShell script which documents the configuration of VMware NSX-V in Word/HTML/XML/Text formats
    This is an extension of New-AsBuiltReport.ps1 and cannot be run independently
.DESCRIPTION
    Documents the configuration of VMware NSX-V in Word/HTML/XML/Text formats using PScribo.
.NOTES
    Version:        0.1.2
    Author:         Matt Allford
    Twitter:        @mattallford
    Github:         mattallford
    Credits:        Iain Brighton (@iainbrighton) - PScribo module

.LINK
    https://github.com/tpcarman/As-Built-Report
#>

#region Script Parameters
[CmdletBinding(SupportsShouldProcess = $False)]
Param(

    [Parameter(Position = 0, Mandatory = $true, HelpMessage = 'Please provide the IP/FQDN of vCenter Server')]
    [ValidateNotNullOrEmpty()]
    [String]$VIServer,

    [parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
    [PSCredential]$Credentials
)

$script:NSXManager = $null
Try { 
    $script:NSXManager = Connect-NsxServer -vCenterServer $VIServer -Credential $Credentials 
} Catch { 
    Write-Verbose "Unable to connect to NSX Manager for the vCenter Server $VIServer."
}


if ($NSXManager) {
    #Gather information about the NSX environment which are used in later sections within the script
    $script:NSXControllers = Get-NsxController
    $script:NSXEdges = Get-NsxEdge
    $script:NSXLogicalRouters = Get-NsxLogicalRouter
    $script:NSXFirewallSections = Get-NSXFirewallSection
    $script:NSXLogicalSwitches = Get-NSXLogicalSwitch
    $script:NSXFirewallExclusionList = Get-NsxFirewallExclusionListMember
    $script:NSXSecurityGroups = Get-NsxSecurityGroup

    #Create major section in the output file for VMware NSX
    section -Style Heading2 'NSX' {
        Paragraph 'The following section provides a summary of the VMware NSX configuration.'
        BlankLine
        #Provide a summary of the NSX Environment
        $NSXSummary = [PSCustomObject] @{
            'NSX Manager Address' = $NSXManager.Server
            'NSX Manager Version' = $NSXManager.Version
            'NSX Manager Build Number' = $NSXManager.BuildNumber
            'NSX Controller Count' = $NSXControllers.count
            'NSX Edge Count' = $NSXEdges.count
            'NSX Logical Router Count' = $NSXLogicalRouters.count
        }
        $NSXSummary | Table -Name 'NSX Information' -List

        #If this NSX Manager has Controllers, provide a summary of the NSX Controllers
        if ($NSXControllers) {
            section -Style Heading3 'NSX Controller Settings' {
                $NSXControllerSettings = foreach ($NSXController in $NSXControllers) {
                    [PSCustomObject] @{
                        Name = $NSXController.Name
                        ID = $NSXController.ID
                        'IP Address' = $NSXController.IPAddress
                        Status = $NSXController.Status
                        Version = $NSXController.Version
                        'Is Universal' = $NSXController.IsUniversal
                    }
                }
                $NSXControllerSettings | Table -Name 'NSX controller Information'
            }
        }

        #Create report section for NSX Edges
        Section -Style Heading3 'NSX Edge Settings' {
            #Loop through each Edge to collect information
            foreach ($NSXEdge in $NSXEdges) {
                Section -Style Heading4 $NSXEdge.Name {
                    $NSXEdgeSettings = [PSCustomObject] @{
                        Name = $NSXEdge.Name
                        ID = $NSXEdge.ID
                        Version = $NSXEdge.Version
                        Status = $NSXEdge.Status
                        Type = $NSXEdge.Type
                        'Connected VNICs' = $NSXEdge.edgeSummary.numberOfConnectedVnics
                        'Edge Status' = $NSXEdge.edgeSummary.edgeStatus
                        'Is Universal' = $NSXEdge.isUniversal
                        'Edge HA Enabled' = $NSXEdge.features.highAvailability.enabled
                        'Deploy Appliance' = $NSXEdge.appliances.deployAppliances
                        'Appliance Size' = $NSXEdge.appliances.ApplianceSize
                        'Syslog Enabled' = $NSXEdge.features.syslog.enabled
                        'SSH Enabled' = $NSXEdge.cliSettings.remoteAccess
                        'Edge Autoconfiguration Enabled' = $NSXEdge.autoConfiguration.enabled
                        'FIPS Enabled' = $NSXEdge.EnableFIPS
                        'NAT Enabled' = $NSXEdge.features.Nat.enabled
                        'Layer 2 VPN Enabled' = $NSXEdge.features.l2Vpn.enabled
                        'DNS Enabled' = $NSXEdge.features.dns.enabled
                        'SSL VPN Enabled' = $NSXEdge.features.sslvpnConfig.enabled
                        'Firewall Enabled' = $NSXEdge.features.firewall.enabled
                        'IPSEC VPN Enabled' = $NSXEdge.features.ipsec.enabled
                        'Load Balancer Enabled' = $NSXEdge.features.loadBalancer.enabled
                        'DHCP Server Enabled' = $NSXEdge.features.dhcp.enabled
                        'Layer 2 Bridges Enabled' = $NSXEdge.features.bridges.enabled
                    }
                    $NSXEdgeSettings | Table -Name "NSX Edge Information" -List

                    #Loop through all of the vNICs attached to the NSX edge and output information to the report
                    #Show only connected NICs if using Infolevel 1, but show all NICs is InfoLevel is 2 or greater
                    Section -Style Heading5 "vNIC Settings" {
                        $NSXEdgeVNICSettings = foreach ($NSXEdgeVNIC in $NSXEdge.vnics.vnic) {
                            [PSCustomObject] @{
                                Label = $NSXEdgeVNIC.Label
                                'VNIC Number' = $NSXEdgeVNIC.index
                                Name = $NSXEdgeVNIC.Name
                                MTU = $NSXEdgeVNIC.mtu
                                Type = $NSXEdgeVNIC.Type
                                Connected = $NSXEdgeVNIC.IsConnected
                                'Portgroup Name' = $NSXEdgeVNIC.portgroupName
                            }
                        }
                        $NSXEdgeVNICSettings | Table -Name "NSX Edge VNIC Information"
                    }

                    #Check to see if NAT is enabled on the NSX Edge. If it is, export NAT Rules
                    $NSXEdgeNATRules = $NSXEdge | Get-NsxEdgeNat | Get-NsxEdgeNatRule
                    if ($NSXEdgeNATRules) {
                        Section -Style Heading5 "NAT Rules" {
                            $SNATRules = $NSXEdgeNATRules | Where-Object {$_.Action -eq "snat"}
                            $DNATRules = $NSXEdgeNATRules | Where-Object {$_.Action -eq "dnat"}
                            Section -Style Heading6 "SNAT Rules" {
                                $SNATRuleConfig = foreach ($SNATRule in $SNATRules) {
                                    [PSCustomObject] @{
                                        'Rule ID' = $SNATRule.RuleId
                                        Action = $SNATRule.Action
                                        Enabled = $SNATRule.Enabled
                                        Description = $SNATRule.Description
                                        RuleType = $SNATRule.RuleType
                                        EdgeNIC = $SNATRule.vnic
                                        OriginalAddress = $SNATRule.OriginalAddress
                                        OriginalPort = $SNATRule.OriginalPort
                                        TranslatedAddress = $SNATRule.TranslatedAddress
                                        TranslatedPort = $SNATRule.TranslatedPort
                                        Protocol = $SNATRule.Protocol
                                        'SNAT Destination Address' = $SNATRule.snatMatchDestinationAddress
                                        'SNAT Destination Port' = $SNATRule.snatMatchDestinationPort
                                        'Logging Enabled' = $SNATRule.loggingEnabled
                                    }
                                }
                                $SNATRuleConfig | Table -Name "SNAT Rules" -List
                            }
                            Section -Style Heading6 "DNAT Rules" {
                                $DNATRuleConfig = foreach ($DNATRule in $DNATRules) {
                                    [PSCustomObject] @{
                                        'Rule ID' = $DNATRule.RuleId
                                        Action = $DNATRule.Action
                                        Enabled = $DNATRule.Enabled
                                        Description = $DNATRule.Description
                                        RuleType = $DNATRule.RuleType
                                        EdgeNIC = $DNATRule.vnic
                                        OriginalAddress = $DNATRule.OriginalAddress
                                        OriginalPort = $DNATRule.OriginalPort
                                        TranslatedAddress = $DNATRule.TranslatedAddress
                                        TranslatedPort = $DNATRule.TranslatedPort
                                        Protocol = $DNATRule.Protocol
                                        'DNAT Source Address' = $DNATRule.dnatMatchSourceAddress
                                        'DNAT Source Port' = $DNATRule.dnatMatchSourcePort
                                        'Logging Enabled' = $DNATRule.loggingEnabled
                                    }
                                }
                                $DNATRuleConfig | Table -Name "DNAT Rules" -List
                            }
                        }#end Section -Style Heading5 "NAT Rules"
                    }#End $NSXEdgeNATRules

                    #Check to see if Layer2 VPN is enabled on the NSX Edge. If it is, export the L2 VPN information
                    if ($NSXEdge.features.l2Vpn.enabled) {

                    }

                    #Check to see if DNS is enabled on the NSX Edge. If it is, export the DNS information
                    if ($NSXEdge.features.dns.enabled -eq "true") {
                        Section -Style Heading5 "DNS Settings" {
                            $NSXEdgeDNSSettings = [PSCustomObject]@{
                                'Edge Interface' = $NSXEdge.features.dns.listeners.vnic
                                'DNS Servers' = ($NSXEdge.features.dns.dnsViews.dnsView.forwarders.IpAddress -join ", ")
                                'Cache Size' = $NSXEdge.features.dns.cachesize
                                'Logging Enabled' = $NSXEdge.features.dns.logging.enable
                                'Logging Level' = $NSXEdge.features.dns.logging.loglevel
                            }
                            $NSXEdgeDNSSettings | Table -Name "$($NSXEdge.Name) DNS Configuration"
                        }
                    }

                    #Check to see if the SSL VPN is enabled on the NSX Edge. If it is, export the SSL VPN information
                    if ($NSXEdge.features.sslvpnConfig.enabled) {

                    }

                    #Check to see if the Edge is deployed with high availability. If it is, export the HA information
                    if ($NSXEdge.features.highAvailability.enabled) {

                    }

                    #Check to see if routing is enabled on the NSX Edge. If it is, export the routing information
                    if ($NSXEdge.features.routing.enabled) {

                    }
                    if ($NSXEdge.features.gslb.enabled) {

                    }
                    if ($NSXEdge.features.firewall.enabled) {

                    }
                    if ($NSXEdge.features.ipsec.enabled) {

                    }
                    if ($NSXEdge.features.loadbalancer.enabled) {

                    }
                    if ($NSXEdge.features.dhcp.enabled) {

                    }
                    if ($NSXEdge.features.bridges.enabled) {

                    }

                    #Check to see if Syslog is enabled on the NSX Edge. If it is, export the Syslog information
                    if ($NSXEdge.features.syslog.enabled -eq "true") {
                        Section -Style Heading5 "Syslog Settings" {
                            $NSXEdgeSyslogSettings = [PSCustomObject]@{
                                'Syslog Protocol' = $NSXEdge.features.Syslog.Protocol
                                'Syslog Servers' = ($NSXEdge.features.Syslog.ServerAddresses.ipAddress -join ", ")
                            }
                            $NSXEdgeSyslogSettings | Table -Name "$($NSXEdge.Name) Syslog Settings"
                        }
                    }
                }
            }#End NSX Edge foreach loop
        }#End NSX Edge Settings

        Section -Style Heading3 'NSX Distributed Firewall' {
            #Check to see if any VMs are excluded from the NSX Distributed Firewall, and if they are, list them here
            if ($NSXFirewallExclusionList) {
                Section -Style Heading4 "NSX Distributed Firewall Exclusion List" {
                    $NSXFirewallExclusionList | Select-Object Name | table -Name "NSX Distributed Firewall Exclusion List"
                }
            }
            #Document the NSX DFW Sections
            if ($NSXFirewallSections) {
                Section -Style Heading4 "NSX Firewall Sections" {
                    $NSXFirewallSectionSettings = foreach ($NSXFirewallSection in $NSXFirewallSections) {
                        [PSCustomObject]@{
                            Name = $NSXFirewallSection.Name
                            ID = $NSXFirewallSection.ID
                            Stateless = $NSXFirewallSection.Stateless
                            Type = $NSXFirewallSection.Type
                            '# of Rules' = $NSXFirewallSection.rule.count
                            'Enable TCP Strict' = $NSXFirewallSection.tcpStrict
                            'Enable User Identity at Source' = $NSXFirewallSection.useSid
                        }
                    }
                    $NSXFirewallSectionSettings | table -Name "NSX Firewall Section Information" -List
                }

                #For each Section in the DFW, loop through to get information about each rule within the secion and document each rule
                foreach ($NSXFirewallSection in $NSXFirewallSections) {
                    #Get all NSX Rules for the current section
                    $NSXDFWRules = $NSXFirewallSection | Get-NsxFirewallRule 
                    if ($NSXDFWRules) {
                        Section -Style Heading4 "$($NSXFirewallSection.name) Firewall Rules" {
                            $NSXDFWRuleInfo = foreach ($NSXDFWRule in $NSXDFWRules) {
                                #Check to see if the current rule is enabled or disabled
                                if ($NSXDFWRule.Disabled -eq "true") {
                                    $NSXDFWRuleStatus = "Disabled"
                                } elseif ($NSXDFWRule.Disabled -eq "false") {
                                    $NSXDFWRuleStatus = "Enabled"
                                }

                                # If there is no source, the source must be any. Else specify the source.
                                if (!$NSXDFWRule.Sources.Source.Name) {
                                    $NSXDFWRuleSource = "Any"
                                } else {
                                    $NSXDFWRuleSource = $NSXDFWRule.Sources.Source.Name
                                }

                                # If there is no destination, the destination must be any. Else specify the destination.
                                if (!$NSXDFWRule.Destinations.Destination.Name) {
                                    $NSXDFWRuleDestination = "Any"
                                } else {
                                    $NSXDFWRuleDestination = $NSXDFWRule.Destinations.Destination.Name
                                }

                                # If there is no service, the service must be any. Else specify the service
                                if (!$NSXDFWRule.Services.service.name) {
                                    $NSXDFWServiceName = "Any"
                                } Else {
                                    $NSXDFWServiceName = ($NSXDFWRule.Services.service.name -join ", ")
                                }

                                [PSCustomObject]@{
                                    Name = $NSXDFWRule.Name
                                    ID = $NSXDFWRule.id
                                    Status = $NSXDFWRuleStatus
                                    Action = $NSXDFWRule.Action
                                    Direction = $NSXDFWRule.Direction
                                    'Packet Type' = $NSXDFWRule.PacketType
                                    'Source' = $NSXDFWRuleSource
                                    'Source Type' = $NSXDFWRule.Sources.Source.Type
                                    'Source Negate' = $NSXDFWRule.Sources.Excluded
                                    'Destination' = $NSXDFWRuleDestination
                                    'Destination Type' = $NSXDFWRule.Destinations.Destination.Type
                                    'Destination Negate' = $NSXDFWRule.Destinations.Excluded
                                    'Service Name' = $NSXDFWServiceName
                                    'Applied To' = $NSXDFWRule.appliedToList.appliedTo.name
                                    'Log Enabled' = $NSXDFWRule.Logged
                                }
                            }
                            $NSXDFWRuleInfo | table -Name "NSX Firewall Rules"
                        }
                    }

                }#End Foreach NSX Firewall Sections
            }#End if NSX Firewall Sections
        }#End NSX Distributed Firewall Section

        #This block of code retrieves information about synamic and static NSX Security groups
        if ($NSXSecurityGroups) {
            Section -Style Heading3 'NSX Security Groups' {
                Section -Style Heading4 'NSX Security Group Summary' {
                    #Create empty arrays that are used in the foreach loops below
                    $NSXSecurityGroupSummary = @()
                    $StaticNSXSecurityGroups = @()
                    $DynamicNSXSecurityGroups = @()
                    foreach ($NSXSecurityGroup in $NSXSecurityGroups) {
                        if ($NSXSecurityGroup.dynamicMemberDefinition) {
                            $NSXSecurityGroupHashTable = [Ordered]@{
                                'Name' = $NSXSecurityGroup.name
                                'Scope' = $NSXSecurityGroup.scope.name
                                'Is Universal' = $NSXSecurityGroup.IsUniversal
                                'Inheritance Allowed' = $NSXSecurityGroup.InheritanceAllowed
                                'Object ID' = $NSXSecurityGroup.objectID
                                'Group Type' = "Dynamic"
                            }
                            $NSXSecurityGroupObject = New-Object PSObject -Property $NSXSecurityGroupHashTable
                            $NSXSecurityGroupSummary += $NSXSecurityGroupObject
                            #Add the security group to the list of Dynamic security groups
                            $DynamicNSXSecurityGroups += $NSXSecurityGroup
                        } else {
                            $NSXSecurityGroupHashTable = [Ordered]@{
                                'Name' = $NSXSecurityGroup.name
                                'Scope' = $NSXSecurityGroup.scope.name
                                'Is Universal' = $NSXSecurityGroup.IsUniversal
                                'Inheritance Allowed' = $NSXSecurityGroup.InheritanceAllowed
                                'Object ID' = $NSXSecurityGroup.objectID
                                'Group Type' = "Static"
                            }
                            $NSXSecurityGroupObject = New-Object PSObject -Property $NSXSecurityGroupHashTable
                            $NSXSecurityGroupSummary += $NSXSecurityGroupObject
                            #Add the security group to the list of Static security groups
                            $StaticNSXSecurityGroups += $NSXSecurityGroup
                        }
                    }
                    #Export the information regarding both dynamic and static security groups
                    $NSXSecurityGroupSummary | table -Name "NSX Security Groups"

                    #If there are any static security groups in the environment, export specific information about the security groups, including the membership
                    if ($StaticNSXSecurityGroups) {
                        section -Style Heading5 'NSX Static Security Groups' {
                            $StaticNSXSecurityGroupSettings = foreach ($StaticNSXSecurityGroup in $StaticNSXSecurityGroups) {
                                [PSCustomObject]@{
                                    Name = $StaticNSXSecurityGroup.Name
                                    Description = $StaticNSXSecurityGroup.Description
                                    Members = ($StaticNSXSecurityGroup.member.Name -join ", ")
                                }
                            }
                            $StaticNSXSecurityGroupSettings | table -Name "NSX static Security Group Membership"
                        }
                    }

                    #If there are any dynamic security groups in the environment, export specific information about the security groups, including the dynamic criteria
                    if ($DynamicNSXSecurityGroups) {
                        section -Style Heading4 'NSX Dynamic Security Groups' {
                            $DynamicNSXSecurityGroupSettings = foreach ($DynamicNSXSecurityGroup in $DynamicNSXSecurityGroups) {
                                [PSCustomObject]@{
                                    Name = $DynamicNSXSecurityGroup.Name
                                    Operator = $DynamicNSXSecurityGroup.dynamicMemberDefinition.DynamicSet.DynamicCriteria.Operator
                                    Key = $DynamicNSXSecurityGroup.dynamicMemberDefinition.DynamicSet.DynamicCriteria.Key
                                    Criteria = $DynamicNSXSecurityGroup.dynamicMemberDefinition.DynamicSet.DynamicCriteria.Criteria
                                    Value = $DynamicNSXSecurityGroup.dynamicMemberDefinition.DynamicSet.DynamicCriteria.Value
                                }
                            }
                            $DynamicNSXSecurityGroupSettings | table -Name "NSX Dynamic Security Group Membership"
                        }
                    }
                }
            }
        }#End if NSXSecurityGroups
    }

    #Disconnect from the NSX Manager Server
    Disconnect-NsxServer
}