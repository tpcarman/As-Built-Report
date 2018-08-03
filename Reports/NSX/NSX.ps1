#requires -Modules PowerNSX

<#
.SYNOPSIS
    PowerShell script which documents the configuration of VMware NSX in Word/HTML/XML/Text formats
    This is an extension of New-AsBuiltReport.ps1 and cannot be run independantly
#>

#region Script Parameters
[CmdletBinding(SupportsShouldProcess = $False)]
Param(

    [Parameter(Position = 0, Mandatory = $true, HelpMessage = 'Please provide the IP/FQDN of vCenter Server')]
    [ValidateNotNullOrEmpty()]
    [String]$VIServer,

    [parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    [PSCredential]$Credentials
)

$script:NSXManager = Connect-NsxServer -vCenterServer $VIServer -Credential $Credentials

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
        $NSXSummaryHash = @{
            'NSXManager'            = $NSXManager.Server
            'NSXManagerVersion'     = $NSXManager.Version
            'NSXManagerBuildNumber' = $NSXManager.BuildNumber
            'NSXControllerCount'    = $NSXControllers.count
            'NSXEdgeCount'          = $NSXEdges.count
            'NSXLogicalRouterCount' = $NSXLogicalRouters.count
        }
        $NSXSummary = $NSXSummaryHash | Select-Object @{L='NSX Manager Address'; E={$_.NSXManager}}, @{L='NSX Manager Version'; E={$_.NSXManagerVersion}}, @{L='NSX Manager Build Number'; E={$_.NSXManagerBuildNumber}}, `
        @{L='NSX Controller Count'; E={$_.NSXControllerCount}}, @{L='NSX Edge Count'; E={$_.NSXEdgeCount}}, @{L='NSX Logical Router Count'; E={$_.NSXLogicalRouterCount}}
        $NSXSummary | Table -Name 'NSX Information' -List

        #Provide a summary of the NSX Controllers
        section -Style Heading3 'NSX Controller Settings' {
            $NSXControllerSettings = $NSXControllers | Select-Object @{L='Name'; E={$_.Name}},@{L='ID'; E={$_.ID}},@{L='IP Address'; E={$_.IPAddress}},@{L='Status'; E={$_.Status}},@{L='Version'; E={$_.Version}},@{L='Is Universal'; E={$_.IsUniversal}}
            $NSXControllerSettings | Table -Name 'NSX controller Information'
        }

        #Create report section for NSX Edges
        Section -Style Heading3 'NSX Edge Settings' {
            #Loop through each Edge to collect information
            foreach ($NSXEdge in $NSXEdges) {
                #Output high level information about the Edge
                Section -Style Heading4 $NSXEdge.Name {
                    $NSXEdgeSettings = $NSXEdge | Select-Object @{L='Name'; E={$_.Name}},@{L='ID'; E={$_.ID}},@{L='Version'; E={$_.Version}},@{L='Status'; E={$_.Status}},@{L='Type'; E={$_.Type}},@{L='Is Universal'; E={$_.IsUniversal}}, @{L='Deploy Appliance'; E={$_.appliances.deployAppliances}}, @{L='Appliance Size'; E={$_.appliances.ApplianceSize}}, @{L='NAT enabled'; E={$_.features.nat.enabled}}, @{L='Layer2 VPN Enabled'; E={$_.features.l2Vpn.enabled}}, @{L='DNS Enabled'; E={$_.features.dns.enabled}}, @{L='Syslog Enabled'; E={$_.features.syslog.enabled}}
                    $NSXEdgeSettings | Table -Name "NSX Edge Information" -List

                    #Loop through all of the vNICs attached to the NSX edge and output information to the report
                    #Show only connected NICs if using Infolevel 1, but show all NICs is InfoLevel is 2 or greater
                    Section -Style Heading5 "Edge vNIC Settings" {
                        if ($InfoLevel.NSX -eq "1") {
                            Section -Style Heading6 "$($NSXEdge.Name) vNIC Settings" {
                            $NSXEdgeVNICSettings = @()
                                foreach ($NSXEdgeVNIC in $NSXEdge.vnics.vnic) {
                                    if ($NSXEdgeVNIC.isConnected -eq "true") {
                                        $NSXEdgeVNICSettings += $NSXEdgeVNIC | Select-Object @{L='Label'; E={$_.label}}, @{L='Name'; E={$_.name}}, @{L='MTU'; E={$_.mtu}}, @{L='Type'; E={$_.type}}, @{L='Connected'; E={$_.isConnected}}, @{L='Portgroup Name'; E={$_.portgroupName}}
                                    }
                                }
                            $NSXEdgeVNICSettings | Table -Name "NSX Edge VNIC Information"
                            }
                        }elseif ($InfoLevel.NSX -ge "2") {
                            Section -Style Heading6 "$($NSXEdge.Name) vNIC Settings" {
                            $NSXEdgeVNICSettings = @()
                                foreach ($NSXEdgeVNIC in $NSXEdge.vnics.vnic) {
                                    $NSXEdgeVNICSettings += $NSXEdgeVNIC | Select-Object @{L='Label'; E={$_.label}}, @{L='Name'; E={$_.name}}, @{L='MTU'; E={$_.mtu}}, @{L='Type'; E={$_.type}}, @{L='Connected'; E={$_.isConnected}}, @{L='Portgroup Name'; E={$_.portgroupName}}
                                }
                            $NSXEdgeVNICSettings | Table -Name "NSX Edge VNIC Information"
                            }
                        }
                    }

                    #Check to see if NAT is enabled on the NSX Edge. If it is, export NAT Rules
                    if ($NSXEdge.features.nat.enabled -eq "true") {
                        Section -Style Heading5 "NAT Settings" {
                            $NSXEdgeNATSettings = $NSXEdge | Select-Object @{L = 'NAT Rules'; E = {$_.features.Nat.natRules}}, @{L = 'NAT64 Rules'; E = {$_.features.Nat64.natRules}}
                            $NSXEdgeNATSettings | Table -Name "$($NSXEdge.Name) NAT Information"
                        }
                    }

                    #Check to see if Layer2 VPN is enabled on the NSX Edge. If it is, export the L2 VPN information
                    if ($NSXEdge.features.l2Vpn.enabled) {

                    }

                    #Check to see if DNS is enabled on the NSX Edge. If it is, export the DNS information
                    if ($NSXEdge.features.dns.enabled -eq "true") {
                        Section -Style Heading5 "DNS Settings" {
                            $NSXEdgeDNSSettings = $NSXEdge | Select-Object @{L = 'DNS Interface'; E = {$_.features.dns.listeners.vnic}}, @{L = 'DNS Servers'; E = {($_.features.dns.dnsViews.dnsView.forwarders.IpAddress) -join ", "}}, @{L = 'Cache Size'; E = {$_.features.dns.cachesize}}, @{L = 'Logging Enabled'; E = {$_.features.dns.logging.enable}}, @{L = 'Logging Level'; E = {$_.features.dns.logging.loglevel}}
                            $NSXEdgeDNSSettings | Table -Name "$($NSXEdge.Name) DNS Information"
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
                            $NSXEdgeSyslogSettings = $NSXEdge | Select-Object @{L = 'Syslog Protocol'; E = {$_.features.Syslog.Protocol}}, @{L = 'Syslog Servers'; E = {($_.features.Syslog.ServerAddresses.ipAddress) -join ", "}}
                            $NSXEdgeSyslogSettings | Table -Name "$($NSXEdge.Name) Syslog Information"
                        }
                    }
                }
            }#End NSX Edge foreach loop
        }#End NSX Edge Settings

        #Document the NSX DFW Sections
        Section -Style Heading3 'NSX Distributed Firewall'{
            if ($NSXFirewallExclusionList){
                Section -Style Heading4 "NSX Distributed Firewall Exclusion List"{
                    $NSXFirewallExclusionList | Select-Object Name | table -Name "NSX Distributed Firewall Exclusion List"
                }
            }
            if ($NSXFirewallSections) {
                Section -Style Heading4 "NSX Firewall Sections"{
                    $NSXFirewallSectionSettings = $NSXFirewallSections | Select-Object @{L='Name'; E={$_.Name}},@{L='ID'; E={$_.ID}},@{L='Stateless'; E={$_.Stateless}},@{L='Type'; E={$_.Type}}, @{L = 'Rules in Section'; E = {$_.rule.count}}, @{L = 'Enable TCP Strict'; E = {$_.tcpStrict}}, @{L = 'Enable User Identity at Source'; E = {$_.useSid}}
                    $NSXFirewallSectionSettings | table -Name "NSX Firewall Section Information" -List
                }
                foreach ($NSXFirewallSection in $NSXFirewallSections){
                    if ($NSXFirewallSection.rule) {
                        Section -Style Heading5 "$($NSXFirewallSection.name) Firewall Rules"{
                            $NSXRuleSummary = @()
                            foreach ($Rule in $NSXFirewallSection.rule){
                            #All of the variables in this foreeach are set to the scope of $Script:, this is due to clear-variable being used at the end of the loop needing the scope to be set,
                            #else it was not finding the name of the variable due to the way this framework was running by calling multiple scripts
                                if ($Rule.Disabled -eq "true"){
                                    $script:RuleStatus = "Disabled"
                                }elseif ($Rule.Disabled -eq "false"){
                                    $script:RuleStatus = "Enabled"
                                }
                            
                                if(!$Rule.services){
                                    $script:RuleService = "any"
                                }else{
                                    foreach($Service in $Rule.services.service){
                                        if($Service.protocolName)
                                        {
                                            $script:RuleService = $service.protocolName + "/" + $service.destinationPort
                                        }
                                    }
                                    $script:RuleService = $Rule.Services.service.name
                                }
                            
                                #Rule Source Information
                                if (!$Rule.sources){
                                    $script:RuleSource = "any"
                                }else{
                                    if ($rule.sources.excluded -eq "True"){
                                        $script:RuleSourceNegate = "true"
                                    }else{
                                        $script:RuleSourceNegate = "false"
                                    }
                                    foreach ($source in $rule.sources.source){
                                        $script:RuleSource = $source.Name
                                        $script:RuleSourceType = $Source.Type
                                    }
                                }
                            
                                #Rule Destination Information
                                if (!$Rule.Destinations){
                                    $script:RuleDestination = "any"
                                }else{
                                    if ($Rule.Destinations.Excluded -eq "True"){
                                        $script:RuleDestinationNegate = "true"
                                    }else{
                                        $script:RuleDestinationNegate = "false"
                                    }
                                    foreach ($Destination in $Rule.Destinations.Destination){
                                        $script:RuleDestination = $Destination.Name
                                        $script:RuleDestinationType = $Destination.Type
                                    }
                                }
                                $NSXRuleHashTable = [Ordered]@{
                                    'Name'               = $Rule.name
                                    'ID'                 = $Rule.ID
                                    'Status'             = $RuleStatus
                                    'Action'             = $Rule.Action
                                    'Direction'          = $Rule.Direction
                                    'Packet Type'        = $Rule.packetType
                                    'Source Negate'      = $RuleSourceNegate
                                    'Source Type'        = $RuleSourcetype
                                    'Source Name'        = $Rulesource
                                    'Destination Negate' = $RuleDestinationNegate
                                    'Destination Type'   = $RuleDestinationType
                                    'Destination Name'   = $RuleDestination
                                    'Service Name'       = ($RuleService -join ", ")
                                    'Applied To'         = $Rule.appliedToList.appliedTo.name
                                    'Log'                = $Rule.logged
                                }
                                $NSXRuleObject = New-Object PSObject -Property $NSXRuleHashTable
                                $NSXRuleSummary += $NSXRuleObject
                                #Clearing all of the variables that were used in this foreach look so that an invalid value doesn't get reused in the next foreach loop
                                Clear-Variable -Name RuleSource,RuleStatus,RuleService,RuleSourceNegate,RuleSourceType,RuleDestination,RuleDestinationNegate,RuleDestinationType
                            }
                            $NSXRuleSummary | table -Name "NSX Firewall Rules"
                        }
                    }#End if NSXFirewallSection
                }#End Foreach NSX Firewall Sections
            }#End if NSX Firewall Sections
        }#End NSX Distributed Firewall Section

        if ($NSXSecurityGroups){
            Section -Style Heading3 'NSX Security Groups'{
                Section -Style Heading4 'NSX Security Group Summary'{
                    $NSXSecurityGroupSummary = @()
                    $StaticNSXSecurityGroups = @()
                    $DynamicNSXSecurityGroups = @()
                    foreach ($NSXSecurityGroup in $NSXSecurityGroups){
                        if ($NSXSecurityGroup.dynamicMemberDefinition){
                            $NSXSecurityGroupHashTable = [Ordered]@{
                                'Name'                  = $NSXSecurityGroup.name
                                'Scope'                 = $NSXSecurityGroup.scope.name
                                'Is Universal'          = $NSXSecurityGroup.IsUniversal
                                'Inheritance Allowed'   = $NSXSecurityGroup.InheritanceAllowed
                                'Object ID'             = $NSXSecurityGroup.objectID
                                'Group Type'            = "Dynamic"
                            }
                            $NSXSecurityGroupObject = New-Object PSObject -Property $NSXSecurityGroupHashTable
                            $NSXSecurityGroupSummary += $NSXSecurityGroupObject
                            $DynamicNSXSecurityGroups += $NSXSecurityGroup
                        }else{
                            $NSXSecurityGroupHashTable = [Ordered]@{
                                'Name'                  = $NSXSecurityGroup.name
                                'Scope'                 = $NSXSecurityGroup.scope.name
                                'Is Universal'          = $NSXSecurityGroup.IsUniversal
                                'Inheritance Allowed'   = $NSXSecurityGroup.InheritanceAllowed
                                'Object ID'             = $NSXSecurityGroup.objectID
                                'Group Type'            = "Static"
                            }
                            $NSXSecurityGroupObject = New-Object PSObject -Property $NSXSecurityGroupHashTable
                            $NSXSecurityGroupSummary += $NSXSecurityGroupObject
                            $StaticNSXSecurityGroups += $NSXSecurityGroup
                        }
                    }
                    $NSXSecurityGroupSummary | table -Name "NSX Security Groups"

                    if ($StaticNSXSecurityGroups){
                        section -Style Heading5 'NSX Static Security Groups'{
                            $StaticNSXSecurityGroupSettings = $StaticNSXSecurityGroups | Select-Object @{L='Name';E={$_.name}},@{L='Description';E={$_.Description}},@{L='Members';E={($_.member.Name) -join ", "}}
                            $StaticNSXSecurityGroupSettings | table -Name "NSX static Security Group Membership"
                        }
                    }

                    if ($DynamicNSXSecurityGroups){
                        section -Style Heading4 'NSX Dynamic Security Groups'{
                            $DynamicNSXSecurityGroupSettings = $DynamicNSXSecurityGroups | Select-Object @{L='Name';E={$_.name}},@{L='Operator';E={$_.dynamicMemberDefinition.DynamicSet.DynamicCriteria.Operator}},@{L='Key';E={$_.dynamicMemberDefinition.DynamicSet.DynamicCriteria.Key}}, @{L='Criteria';E={$_.dynamicMemberDefinition.DynamicSet.DynamicCriteria.Criteria}}, @{L='Value';E={$_.dynamicMemberDefinition.DynamicSet.DynamicCriteria.Value}}
                            $DynamicNSXSecurityGroupSettings | table -Name "NSX Dynamic Security Group Membership"
                        }
                    }
                }
            }
        }#End if NSXSecurityGroups
    }
}

Disconnect-NsxServer