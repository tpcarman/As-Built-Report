#requires -Modules @{ModuleName="PScribo";ModuleVersion="0.7.21.110"},CiscoUcsPS

#region Script Help
<#
.SYNOPSIS  
    PowerShell script to document the configuration of Cisco UCS infrastucture in Word/HTML/XML/Text formats
.DESCRIPTION
    Documents the configuration of Cisco UCS infrastucture using the PScribo PowerShell module by @iainbrighton.
    Cisco UCS code provided by Martijn Smit's (@smitmartijn) Cisco UCS inventory scipt.
.NOTES
    Version:        0.1
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
    Credits:        Martijn Smit (@smitmartijn) - Cisco UCS Inventory Script
                    Iain Brighton (@iainbrighton) - PScribo module
.LINK
    https://github.com/tpcarman/Documentation-Scripts
    https://github.com/smitmartijn/Cisco-UCS-Inventory-Script
    https://github.com/iainbrighton/PScribo
.PARAMETER ReportName
    Specifies the report name.
    This parameter is optional.
    By default, the report name is 'Cisco UCS As Built Documentation'.
.PARAMETER ReportType
    (Currently Not in Use)
    Sepecifies the type of report to produce.
    Report types are as follows:
        * Summary
        * Detailed
        * Full
    This parameter is optional.
    By default, the report type is set to 'Detailed'.   
.PARAMETER Author
    Specifies the report's author.
    This parameter is optional and does not have a default value.
.PARAMETER Version
    Specifies the report version number.
    This parameter is optional and does not have a default value.
.PARAMETER Status
    Specifies the report document status.
    This parameter is optional.
    By default, the document status is set to 'Released'.
.PARAMETER Format
    Specifies the output format of the report.
    This parameter is mandatory.
    The supported output formats are WORD, HTML, XML & TEXT.
    Multiple output formats may be specified, separated by a comma.
    By default, the output format will be set to WORD.
.PARAMETER Style
    Specifies the document style of the report.
    This parameter is optional and does not have a default value.
.PARAMETER Path
    Specifies the path to save the report.
    This parameter is optional. If not specified the report will be saved in the User's documents folder.
.PARAMETER AddDateTime
    Specifies whether to append a date/time string to the report filename.
    This parameter is optional. 
    By default, the date/time string is not added to the report filename.
.PARAMETER Healthcheck
    (Currently Not in Use)
    Highlights certain issues within the Cisco UCS environment.
    This parameter is optional and by default is set to $False.
.PARAMETER UCS
    Specifies the IP/FQDN of the Cisco UCS on which to connect.
    This parameter is mandatory.
.PARAMETER CompanyName
    Specifies a Company Name for the report.
    This parameter is optional and does not have a default value.
.PARAMETER CompanyContact
    Specifies the Company Contact's Name.
    This parameter is optional and does not have a default value.
.PARAMETER CompanyEmail
    Specifies the Company Contact's Email Address.
    This parameter is optional and does not have a default value.
.PARAMETER CompanyPhone
    Specifies the Company Contact's Phone Number.
    This parameter is optional and does not have a default value.
.PARAMETER CompanyAddress
    Specifies the Company Office Address
    This parameter is optional and does not have a default value.
.PARAMETER SmtpServer
    (Currently Not in Use)
    Specifies the SMTP server address.
    This parameter is optional and does not have a default value.
.PARAMETER SmtpPort
    (Currently Not in Use)
    Specifies the SMTP port.
    If SmtpServer is used, this is an optional parameter.
	By default, the SMTP port is 25.
.PARAMETER UseSSL
    (Currently Not in Use)
    Specifies whether to use SSL for the SmtpServer.
    If SmtpServer is used, this is an optional parameter.
	Default is $False.
.PARAMETER From
    (Currently Not in Use)
	Specifies the From email address.
	If SmtpServer is used, this is a mandatory parameter.
.PARAMETER To
    (Currently Not in Use)
	Specifies the To email address.
	If SmtpServer is used, this is a mandatory parameter.
.EXAMPLE
    .\UCS As Built.ps1 -UCS 192.168.1.100 -Format HTML,Word
    Creates 'Cisco UCS As Built Documentation' report in HTML & Word formats.
.EXAMPLE
    .\UCS As Built.ps1 -UCS 192.168.1.100 -Format Text -AddDateTime
    Creates Cisco UCS As Built report in Text format and appends the current date and time to the filename Cisco UCS As Built Documentation - 09-03-2018_10.45.30.txt
.EXAMPLE
    .\UCS UCS As Built.ps1 -UCS 192.168.1.100 -Author 'Tim Carman' -CompanyName 'ACME'
    Creates Cisco UCS As Built report report in default format (Word) and includes Author and Company names.
    Company Name is appended to the filename ACME - Cisco UCS As Built Documentation.docx
.EXAMPLE
    .\UCS UCS As Built.ps1 -UCS 192.168.1.100 -Style 'ACME'
    Creates Cisco UCS As Built report report in default format (Word) with customised style
#>
#endregion Script Help

#region Script Parameters
[CmdletBinding(SupportsShouldProcess = $False)]
Param(

    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Please provide the IP/FQDN of the UCS chassis')]
    [ValidateNotNullOrEmpty()]
    [Alias('Name', 'Chassis')]
    [String]$UCS = '',

    [Parameter(Position = 1, Mandatory = $False, HelpMessage = 'Specify the document output format')]
    [ValidateNotNullOrEmpty()]
    [Alias('Output')]
    [ValidateSet('Word', 'Html', 'Text', 'Xml')]
    [Array]$Format = 'Word',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the document report type')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Summary', 'Detailed', 'Full')]
    [String]$ReportType = 'Detailed',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report name')]
    [ValidateNotNullOrEmpty()]
    [String]$ReportName = 'Cisco UCS As Built Documentation',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the document report style')]
    [ValidateNotNullOrEmpty()] 
    [String]$Style = 'Default',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify whether to append a date/time string to the report filename')]
    [Switch]$AddDateTime = $False,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the path to save the report')]
    [ValidateNotNullOrEmpty()]
    [Alias('Folder')] 
    [String]$Path = $env:USERPROFILE + '\Documents',

    [Parameter(Mandatory = $False, HelpMessage = 'Highlights any configuration issues within the report')]
    [Switch]$Healthcheck = $False,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report author name')]
    [ValidateNotNullOrEmpty()]
    [String]$Author = $env:USERNAME,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report version number')]
    [ValidateNotNullOrEmpty()] 
    [String]$Version = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report document status')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Draft', 'Updated', 'Released')] 
    [String]$Status = 'Released',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Name')]
    [ValidateNotNullOrEmpty()]
    [String]$CompanyName = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Address')]
    [ValidateNotNullOrEmpty()] 
    [String]$CompanyAddress = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Contact Name')]
    [ValidateNotNullOrEmpty()] 
    [String]$CompanyContact = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Contact Email Address')]
    [ValidateNotNullOrEmpty()] 
    [String]$CompanyEmail = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Contact Phone Number')]
    [ValidateNotNullOrEmpty()] 
    [String]$CompanyPhone = ''
)
#endregion Script Parameters

Clear-Host

# Add Date & Time to document filename
if ($AddDateTime -and $CompanyName) {
    $Filename = "$CompanyName - $ReportName - " + (Get-Date -Format 'dd-MM-yyyy_HH.mm.ss')
}
elseif ($AddDateTime -and !$CompanyName) {
    $Filename = "$ReportName - " + (Get-Date -Format 'dd-MM-yyyy_HH.mm.ss')
}
elseif ($CompanyName) {
    $Filename = "$CompanyName - $ReportName"
}
else {
    $Filename = $ReportName
}

#region Document Template
$Document = Document $Filename -Verbose {
    # Document Options
    DocumentOption -EnableSectionNumbering -PageSize A4 -DefaultFont 'Calibri' -MarginLeftAndRight 71 -MarginTopAndBottom 71
    
    # Styles
    #region Default Document Style
    if ($Style -eq 'Default') {
        Style -Name 'Title' -Size 24 -Color '005073' -Font 'Calibri' -Align Center
        Style -Name 'Title 2' -Size 18 -Color '049FD9' -Font 'Calibri' -Align Center
        Style -Name 'Title 3' -Size 12 -Color '049FD9' -Font 'Calibri' -Align Left
        Style -Name 'Heading 1' -Size 16 -Color '4D4C4C' -Font 'Calibri'
        Style -Name 'Heading 2' -Size 14 -Color '4D4C4C' -Font 'Calibri'
        Style -Name 'Heading 3' -Size 12 -Color '4D4C4C' -Font 'Calibri'
        Style -Name 'Heading 4' -Size 11 -Color '4D4C4C' -Font 'Calibri'
        Style -Name 'Heading 5' -Size 10 -Color '4D4C4C' -Font 'Calibri' -Italic
        Style -Name 'H1 Exclude TOC' -Size 16 -Color '4D4C4C' -Font 'Calibri'
        Style -Name 'Normal' -Size 10 -Font 'Calibri' -Default
        Style -Name 'TOC' -Size 16 -Color '4D4C4C' -Font 'Calibri'
        Style -Name 'TableDefaultHeading' -Size 10 -Color 'FFFFFF' -BackgroundColor '464547' -Font 'Calibri'
        Style -Name 'TableDefaultRow' -Size 10 -Font 'Calibri'
        Style -Name 'TableDefaultAltRow' -Size 10 -BackgroundColor 'DDDDDD' -Font 'Calibri'
        Style -Name 'Critical' -Size 10 -Font 'Calibri' -BackgroundColor 'EA5054'
        Style -Name 'Warning' -Size 10 -Font 'Calibri' -BackgroundColor 'FFFF00'
        Style -Name 'Info' -Size 10 -Font 'Calibri' -BackgroundColor '9CC2E5'
        Style -Name 'OK' -Size 10 -Font 'Calibri' -BackgroundColor '92D050'

        TableStyle -Id 'TableDefault' -HeaderStyle 'TableDefaultHeading' -RowStyle 'TableDefaultRow' -AlternateRowStyle 'TableDefaultAltRow' -BorderColor '464547' -Align Left -BorderWidth 0.5 -Default
    
        # Cover Page
        BlankLine -Count 11
        Paragraph -Style Title $ReportName
        if ($CompanyName -and $Version) {
            Paragraph -Style Title2 $CompanyName
            BlankLine -Count 27 
            Paragraph -Style Title3 "Author: $Author"
            BlankLine
            Paragraph -Style Title3 "Version: $Version"
            PageBreak
        }
        elseif ($CompanyName) {
            Paragraph -Style Title2 $CompanyName
            BlankLine -Count 27
            Paragraph -Style Title3 "Author: $Author"
            PageBreak
        }
        elseif ($Version) {
            BlankLine -Count 28
            Paragraph -Style Title3 "Author: $Author"
            BlankLine
            Paragraph -Style Title3 "Version: $Version"
            PageBreak
        }
        else {
            BlankLine -Count 28
            Paragraph -Style Title3 "Author: $Author"
            PageBreak
        }
    }
    #endregion Default Document Style
   
    # Table of Contents
    TOC -Name 'Table of Contents'
    PageBreak
    
    #endregion Document Template

    #region Script Variables
    $Credentials = Get-Credential
    $UCSC = Connect-Ucs -Name $UCS -Credential $Credentials

    #endregion Script Variables
    
    #region Script Body
    
    $UcsStatus = Get-UcsStatus
    if ($UcsStatus) {
        Section -Style Heading1 -Name 'Cluster Status' {
            $ClusterStatus = $UcsStatus | Select-Object Name, @{L = 'Virtual IP Address'; E = {$_.VirtualIpv4Address}}, @{L = 'HA Configuration'; E = {$_.HaConfiguration}}, @{L = 'HA Readiness'; E = {$_.HaReadiness}}, @{L = 'HA Ready'; E = {$_.HaReady}}, `
            @{L = 'Ethernet State'; E = {$_.EthernetState}} 
            $ClusterStatus | Table -Name 'Cluster Status' -List -ColumnWidths 50, 50 
            BlankLine

            $UcsStatusFiA = $UcsStatus | Select-Object @{L = 'Fabric Interconnect A Role'; E = {$_.FiALeadership}}, @{L = 'Fabric Interconnect A IP Address'; E = {$_.FiAOobIpv4Address}}, `
            @{L = 'Fabric Interconnect A Subnet Mask'; E = {$_.FiAOobIpv4SubnetMask}}, @{L = 'Fabric Interconnect A Default Gateway'; E = {$_.FiAOobIpv4DefaultGateway}}, @{L = 'Fabric Interconnect A State'; E = {$_.FiAManagementServicesState}}
            $UcsStatusFiA | Table -Name 'FiA Cluster Status' -List -ColumnWidths 50, 50 
            BlankLine

            $UcsStatusFiB = $UcsStatus | Select-Object @{L = 'Fabric Interconnect B Role'; E = {$_.FiBLeadership}}, @{L = 'Fabric Interconnect B IP Address'; E = {$_.FiBOobIpv4Address}}, `
            @{L = 'Fabric Interconnect B Subnet Mask'; E = {$_.FiBOobIpv4SubnetMask}}, @{L = 'Fabric Interconnect B Default Gateway'; E = {$_.FiBOobIpv4DefaultGateway}}, @{L = 'Fabric Interconnect B State'; E = {$_.FiBManagementServicesState}}
            $UcsStatusFiB | Table -Name 'FiB Cluster Status' -List -ColumnWidths 50, 50 
        }
    }
    

    Section -Style Heading1 -Name 'Equipment' {
        Section -Style Heading2 -Name 'Chassis' {
            $UcsChassis = Get-UcsChassis
            if ($UcsChassis) {
                Section -Style Heading3 -Name 'Chassis Inventory' {
                    $UcsChassis = $UcsChassis | Sort-Object Rn | Select-Object @{L = 'Chassis'; E = {$_.Rn}}, Model, @{L = 'Admin State'; E = {$_.AdminState}}, @{L = 'Operational State'; E = {$_.OperState}}, @{L = 'License State'; E = {$_.LicState}}, Power, Thermal, Serial
                    $UcsChassis | Table -Name 'Chassis Inventory' -List -ColumnWidths 50, 50 
                }
            }

            $UcsIom = Get-UcsIom
            if ($UcsIom) {
                Section -Style Heading3 -Name 'IOM Inventory' {
                    $UcsIom = $UcsIom | Sort-Object  Dn | Select-Object @{L = 'Chassis Id'; E = {$_.ChassisId}}, @{L = 'Relative Name'; E = {$_.Rn}}, Model, Discovery, @{L = 'Configuration State'; E = {$_.ConfigState}}, @{L = 'Operational State'; E = {$_.OperState}}, Side, Thermal, Serial
                    $UcsIom | Table -Name 'IOM Inventory' 
                }
            }

            $UcsEtherSwitchIntFIo = Get-UcsEtherSwitchIntFIo
            if ($UcsEtherSwitchIntFIo) {
                Section -Style Heading3 -Name 'Fabric Interconnect to IOM Connections' {
                    $UcsEtherSwitchIntFIo = $UcsEtherSwitchIntFIo | Select-Object @{L = 'Chassis Id'; E = {$_.ChassisId}}, Discovery, Model, @{L = 'Operational State'; E = {$_.OperState}}, @{L = 'Switch Id'; E = {$_.SwitchId}}, @{L = 'Peer Slot Id'; E = {$_.PeerSlotId}}, `
                    @{L = 'Peer Port Id'; E = {$_.PeerPortId}}, @{L = 'Sloy Id'; E = {$_.SlotId}}, @{L = 'Port Id'; E = {$_.PortId}}, XcvrType
                    $UcsEtherSwitchIntFIo | Table -Name 'Fabric Interconnect to IOM Connections' 
                }
            }

            $UcsChassisDiscoveryPolicy = Get-UcsChassisDiscoveryPolicy
            if ($UcsChassisDiscoveryPolicy) {
                Section -Style Heading3 -Name 'Chassis Discovery Policy' {
                    $UcsChassisDiscoveryPolicy = $UcsChassisDiscoveryPolicy | Select-Object Ucs, @{L = 'Relative Name'; E = {$_.Rn}}, @{L = 'Link Aggregation Preference'; E = {$_.LinkAggregationPref}}, Action
                    $UcsChassisDiscoveryPolicy | Table -Name 'Chassis Discovery Policy' 
                }
            }

            Section -Style Heading3 -Name 'Chassis Power Policy' {
                $UcsPowerControlPolicy = Get-UcsPowerControlPolicy | Select-Object Ucs, @{L = 'Relative Name'; E = {$_.Rn}}, Redundancy
                $UcsPowerControlPolicy | Table -Name 'Chassis Power Policy' 
            }

            Section -Style Heading3 -Name 'Blade Server Inventory' {
                $UcsBlade = Get-UcsBlade | Sort-Object ChassisID, SlotID | Select-Object @{L = 'Server Id'; E = {$_.ServerId}}, Model, @{L = 'Available Memory'; E = {$_.AvailableMemory}}, @{L = 'Number of CPUs'; E = {$_.NumOfCpus}}, @{L = 'Number of Cores'; E = {$_.NumOfCores}}, `
                @{L = 'Number of Adapters'; E = {$_.NumOfAdaptors}}, @{L = 'Number of Ethernet Interfaces'; E = {$_.NumOfEthHostIfs}}, @{L = 'Number of FC Host Interfaces'; E = {$_.NumOfFcHostIfs}}, @{L = 'Assigned To'; E = {$_.AssignedToDn}}, Presence, @{L = 'Operational State'; E = {$_.OperState}}, `
                    Operability, @{L = 'Power'; E = {$_.OperPower}}, Serial
                $UcsBlade | Table -Name 'Server Inventory' 
            }

            Section -Style Heading3 -Name 'Server Adaptor Inventory' {
                $UcsAdaptorUnit = Get-UcsAdaptorUnit | Sort-Object Dn | Select-Object @{L = 'Chassis Id'; E = {$_.ChassisId}}, @{L = 'Blade Id'; E = {$_.BladeId}}, @{L = 'Relative Name'; E = {$_.Rn}}, Model
                $UcsAdaptorUnit | Table -Name 'Server Adaptor Inventory' 
            }

            Section -Style Heading3 -Name 'Servers with Adaptor Port Expanders' {
                $UcsAdaptorUnitExtn = Get-UcsAdaptorUnitExtn | Sort-Object Dn | Select-Object Dn, Model, Presence
                $UcsAdaptorUnitExtn | Table -Name 'Servers with Adaptor Port Expanders' 
            }

            Section -Style Heading3 -Name 'Server CPU Inventory' {
                $UcsProcessorUnit = Get-UcsProcessorUnit | Sort-Object Dn | Select-Object Dn, SocketDesignation, Cores, CoresEnabled, Threads, Speed, OperState, Thermal, Model | Where-Object {$_.OperState -ne 'removed'}
                $UcsProcessorUnit | Table -Name 'Server CPU Inventory' 
            }

            Section -Style Heading3 -Name 'Server Memory Inventory' {
                $UcsMemoryUnit = Get-UcsMemoryUnit | Sort-Object Dn, Location | Where-Object {$_.Capacity -ne 'unspecified'} | Select-Object  Dn, Location, Capacity, Clock, OperState, Model
                $UcsMemoryUnit | Table -Name 'Server Memory Inventory' 
            }

            Section -Style Heading3 -Name 'Server Storage Controller Inventory' {
                $UcsStorageController = Get-UcsStorageController | Sort-Object Dn | Select-Object Vendor, Model
                $UcsStorageController | Table -Name 'Server Storage Controller Inventory' 
            }

            Section -Style Heading3 -Name 'Server Local Disk Inventory' {
                $UcsStorageLocalDisk = Get-UcsStorageLocalDisk | Sort-Object Dn | Select-Object @{L = 'Distinguised Name'; E = {$_.Dn}}, Model, Size, Serial | Where-Object {$_.Size -ne 'unknown'}
                $UcsStorageLocalDisk | Table -Name 'Server Storage Controller Inventory' 
            }
        }

        Section -Style Heading2 -Name 'Rack Mounts' {
            Section -Style Heading3 -Name 'Rack Server Inventory' {
                $UcsRackUnit = Get-UcsRackUnit | Sort-Object ChassisID, SlotID | Select-Object @{L = 'Server Id'; E = {$_.ServerId}}, Model, @{L = 'Available Memory'; E = {$_.AvailableMemory}}, @{L = 'Number of CPUs'; E = {$_.NumOfCpus}}, @{L = 'Number of Cores'; E = {$_.NumOfCores}}, `
                @{L = 'Number of Adapters'; E = {$_.NumOfAdaptors}}, @{L = 'Number of Ethernet Interfaces'; E = {$_.NumOfEthHostIfs}}, @{L = 'Number of FC Host Interfaces'; E = {$_.NumOfFcHostIfs}}, @{L = 'Assigned To'; E = {$_.AssignedToDn}}, Presence, @{L = 'Operational State'; E = {$_.OperState}}, `
                    Operability, @{L = 'Power'; E = {$_.OperPower}}, Serial
                $UcsRackUnit | Table -Name 'Server Inventory' 
            }
        }

        Section -Style Heading2 -Name 'Fabric Interconnects' {
            $UcsNetworkElement = Get-UcsNetworkElement | Sort-Object Ucs | Select-Object @{L = 'Relative Name'; E = {$_.Rn}}, @{L = 'IP Address'; E = {$_.OobIfIp}}, @{L = 'Subnet Mask'; E = {$_.OobIfMask}}, @{L = 'Deafult Gateway'; E = {$_.OobIfGw}}, @{L = 'MAC Address'; E = {$_.OobIfMac}}, `
                Operability, Thermal, Model, Serial
            $UcsNetworkElement | Table -Name 'Fabric Interconnects' 

            Section -Style Heading2 -Name 'Fabric Interconnect Modules' {
                $UcsFiModule = Get-UcsFiModule | Sort-Object Ucs, Dn | Select-Object @{L = 'Relative Name'; E = {$_.Rn}}, Model, @{L = 'Description'; E = {$_.Descr}}, @{L = 'Port Count'; E = {$_.NumPorts}}, @{L = 'Operational State'; E = {$_.OperState}}, State, Power, Serial
                $UcsFiModule | Table -Name 'Fabric Interconnect Inventory' 
            }
        }
        <#
        Section Section -Style Heading2 -Name 'Policies' {

            Section Section -Style Heading3 -Name 'Global Policies' {
            }

            Section Section -Style Heading3 -Name 'Autoconfig Policies' {
            }

            Section Section -Style Heading3 -Name 'Server Inheritence Policies' {
            }

            Section Section -Style Heading3 -Name 'Server Discovery Policies' {
            }

            Section Section -Style Heading3 -Name 'SEL Policy' {
            }

            Section Section -Style Heading3 -Name 'Power Groups' {
            }

            Section Section -Style Heading3 -Name 'Port Auto-Discovery Policy' {
            }

            Section Section -Style Heading3 -Name 'Security' {
            }
            #>

    }
    
    Section -Style Heading2 -Name 'Firmware' {
        Section -Style Heading3 -Name 'UCS Manager' {
            $UcsmFirmware = Get-UcsFirmwareRunning | Select-Object @{L = 'Distinguised Name'; E = {$_.Dn}}, Type, Version | Sort-Object Dn | Where-Object {$_.Type -eq 'mgmt-ext'}
            $UcsmFirmware | Table -Name 'UCS Manager Firmware' 
        }

        Section -Style Heading3 -Name 'Fabric Interconnect' {
            $UcsFiFirmware = Get-UcsFirmwareRunning | Select-Object @{L = 'Distinguised Name'; E = {$_.Dn}}, Type, Version | Sort-Object Dn | Where-Object {$_.Type -eq 'switch-kernel' -OR $_.Type -eq 'switch-software'}
            $UcsFiFirmware | Table -Name 'Fabric Interconnect Firmware' 
        }

        Section -Style Heading3 -Name 'IOM' {
            $UcsIomFiFirmware = Get-UcsFirmwareRunning | Select-Object Deployment, Dn, Type, Version | Sort-Object Dn | Where-Object {$_.Type -eq 'iocard'} | Where-Object -FilterScript {$_.Deployment -notlike 'boot-loader'}
            $UcsIomFiFirmware | Table -Name 'IOM Firmware' 
        }

        Section -Style Heading3 -Name 'Server Adapters' {
            $UcsServerAdapterFirmware = Get-UcsFirmwareRunning | Select-Object Deployment, Dn, Type, Version | Sort-Object Dn | Where-Object {$_.Type -eq 'adaptor'} | Where-Object -FilterScript {$_.Deployment -notlike 'boot-loader'}
            $UcsServerAdapterFirmware | Table -Name 'Server Adapter Firmware' 
        }

        Section -Style Heading3 -Name 'Server CIMC' {
            $UcsServerCimcFirmware = Get-UcsFirmwareRunning | Select-Object Deployment, @{L = 'Distinguished Name'; E = {$_.Dn}}, Type, Version | Sort-Object   Dn | Where-Object {$_.Type -eq 'blade-controller'} | Where-Object -FilterScript {$_.Deployment -notlike 'boot-loader'}
            $UcsServerCimcFirmware | Table -Name 'Server CIMC Firmware' 
        }

        Section -Style Heading3 -Name 'Server BIOS' {
            $UcsServerBios = Get-UcsFirmwareRunning | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Type, Version | Sort-Object   Dn | Where-Object {$_.Type -eq 'blade-bios'}
            $UcsServerBios | Table -Name 'Server BIOS' 
        }

        Section -Style Heading3 -Name 'Host Firmware Packages' {
            $UcsFirmwareComputeHostPack = Get-UcsFirmwareComputeHostPack | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, BladeBundleVersion, RackBundleVersion
            $UcsFirmwareComputeHostPack | Table -Name 'Host Firmware Packages' 
        }
    }

    Section -Style Heading1 -Name 'Servers' {

        Section -Style Heading2 -Name 'Service Profiles' {
            $UcsServiceProfile = Get-UcsServiceProfile | Where-Object {$_.Type -eq 'instance'}  | Sort-Object Name | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, OperSrcTemplName, AssocState, PnDn, BiosProfileName, IdentPoolName, Uuid, BootPolicyName, HostFwPolicyName, LocalDiskPolicyName, MaintPolicyName, VconProfileName, OperState
            $UcsServiceProfile | Table -Name 'Service Profiles' -List -ColumnWidths 50, 50 
        }
    
        Section -Style Heading2 -Name 'Service Profile Templates' {
            $UcsServiceProfileTemplate = Get-UcsServiceProfile | Where-Object {$_.Type -ne 'instance'}  | Sort-Object Name | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, BiosProfileName, BootPolicyName, HostFwPolicyName, LocalDiskPolicyName, MaintPolicyName, VconProfileName
            $UcsServiceProfileTemplate | Table -Name 'Service Profile Templates' 
        }

        Section -Style Heading3 -Name 'Service Profile vNIC Placements' {
            $UcsLsVConAssign = Get-UcsLsVConAssign -Transport ethernet | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vnicname, Adminvcon, Order | Sort-Object  Dn
            $UcsLsVConAssign | Table -Name 'Service Profile vNIC Placements' 
        }
    
        Section -Style Heading3 -Name 'Ethernet VLAN to vNIC Mappings' {
            $UcsAdaptorVlan = Get-UcsAdaptorVlan | Sort-Object Dn |Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, Id, SwitchId
            $UcsAdaptorVlan | Table -Name 'Ethernet VLAN to vNIC Mappings' 
        }

        Section -Style Heading2 -Name 'Policies' {
    
            Section -Style Heading3 -Name 'Maintenance Policies' {
                $UcsMaintenancePolicy = Get-UcsMaintenancePolicy | Select-Object Name, @{L = 'Distinguished Name'; E = {$_.Dn}}, UptimeDisr, Descr
                $UcsMaintenancePolicy | Table -Name 'Maintenance Policies' 
            }
    
            Section -Style Heading3 -Name 'Boot Policies' {
                $UcsBootPolicy = Get-UcsBootPolicy | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, Purpose, RebootOnUpdate
                $UcsBootPolicy | Table -Name 'Boot Policies' 
            }

            Section -Style Heading3 -Name 'SAN Boot Policies' {
                $UcsLsbootSanImagePath = Get-UcsLsbootSanImagePath | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Type, Vnicname, Lun, Wwn | Where-Object -FilterScript {$_.Dn -notlike 'sys/chassis*'}
                $UcsLsbootSanImagePath | Table -Name 'SAN Boot Policies' 
            }

            Section -Style Heading3 -Name 'Local Disk Policies' {
                $UcsLocalDiskConfigPolicy = Get-UcsLocalDiskConfigPolicy | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, Mode, Descr
                $UcsLocalDiskConfigPolicy | Table -Name 'Local Disk Policies' 
            }

            Section -Style Heading3 -Name 'Scrub Policies' {
                $UcsScrubPolicy = Get-UcsScrubPolicy | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, BiosSettingsScrub, DiskScrub | Where-Object {$_.Name -ne 'policy'}
                $UcsScrubPolicy | Table -Name 'Scrub Policies' 
            }
        
            Section -Style Heading3 -Name 'BIOS Policies' {
                $UcsBiosPolicy = Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name
                $UcsBiosPolicy | Table -Name 'BIOS Policies' 

                Section -Style Heading4 -Name 'BIOS Policy Settings' {
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfQuietBoot | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfQuietBoot'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfPOSTErrorPause | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfPOSTErrorPause'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfResumeOnACPowerLoss | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfResumeOnACPowerLoss'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfFrontPanelLockout | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfFrontPanelLockout'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosTurboBoost | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy TurboBoost'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosEnhancedIntelSpeedStep | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy EnhancedIntelSpeedStep'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosHyperThreading | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy HyperThreading'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfCoreMultiProcessing | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfCoreMultiProcessing'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosExecuteDisabledBit | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy ExecuteDisabledBit'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfIntelVirtualizationTechnology | Sort-Object  Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfIntelVirtualizationTechnology'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfDirectCacheAccess | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfDirectCacheAccess'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfProcessorCState | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfProcessorCState'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfProcessorC1E | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfProcessorC1E'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfProcessorC3Report | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfProcessorC3Report'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfProcessorC6Report | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfProcessorC6Report'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfProcessorC7Report | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfProcessorC7Report'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfCPUPerformance | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfCPUPerformance'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfMaxVariableMTRRSetting | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfMaxVariableMTRRSetting'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosIntelDirectedIO | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy IntelDirectedIO'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfSelectMemoryRASConfiguration | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfSelectMemoryRASConfiguration'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosNUMA | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy NUMA'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosLvDdrMode | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy LvDdrMode'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfUSBBootConfig | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfUSBBootConfig'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfUSBFrontPanelAccessLock | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfUSBFrontPanelAccessLock'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfUSBSystemIdlePowerOptimizingSetting | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfUSBSystemIdlePowerOptimizingSetting'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfMaximumMemoryBelow4GB | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfMaximumMemoryBelow4GB'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfMemoryMappedIOAbove4GB | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfMemoryMappedIOAbove4GB'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfBootOptionRetry | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfBootOptionRetry'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfIntelEntrySASRAIDModule | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfIntelEntrySASRAIDModule'
                    BlankLine
                    Get-UcsBiosPolicy | Where-Object {$_.Name -ne 'SRIOV'} | Get-UcsBiosVfOSBootWatchdogTimer | Sort-Object Dn | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Vp* | Table -Name 'BIOS Policy VfOSBootWatchdogTimer'
                    BlankLine
                }
            }
        }

        Section -Style Heading2 -Name 'Pools' {

            Section -Style Heading3 -Name 'UUID Pools' {
                $UcsUuidSuffixPool = Get-UcsUuidSuffixPool | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, AssignmentOrder, Prefix, Size, Assigned
                $UcsUuidSuffixPool | Table -Name 'UUID Pools' 
            }

            Section -Style Heading3 -Name 'UUID Pool Blocks' {
                $UcsUuidSuffixBlock = Get-UcsUuidSuffixBlock | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, From, To
                $UcsUuidSuffixBlock | Table -Name 'UUID Pool Blocks' 
            }

            Section -Style Heading3 -Name 'UUID Pool Assignments' {
                $UcsUuidpoolAddr = Get-UcsUuidpoolAddr | Where-Object {$_.Assigned -ne 'no'} | Select-Object AssignedToDn, Id | Sort-Object   AssignedToDn
                $UcsUuidpoolAddr | Table -Name 'UUID Pool Assignments' 
            }

            Section -Style Heading3 -Name 'Server Pools' {
                $UcsServerPool = Get-UcsServerPool | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, Assigned
                $UcsServerPool | Table -Name 'Server Pools' 
            }

            Section -Style Heading3 -Name 'Server Pool Assignments' {
                $UcsComputePooledSlot = Get-UcsComputePooledSlot | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Rn
                $UcsComputePooledSlot | Table -Name 'Server Pool Assignments' 
            }
        }
    }

    Section -Style Heading1 -Name 'LAN' {
        Section -Style Heading2 -Name 'LAN Cloud' {
            Section -Style Heading2 -Name 'Fabric Interconnect Ethernet Switching Mode' {
                $UcsLanCloud = Get-UcsLanCloud | Select-Object Rn, Mode
                $UcsLanCloud | Table -Name 'Fabric Interconnect Ethernet Switching Mode' 
            }

            Section -Style Heading2 -Name 'Fabric Interconnect Ethernet Port Configuration' {
                $UcsFabricPort = Get-UcsFabricPort | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, IfRole, LicState, Mode, OperState, OperSpeed, XcvrType | Where-Object {$_.OperState -eq 'up'}
                $UcsFabricPort | Table -Name 'Fabric Interconnect Ethernet Port Configuration' 
            }

            Section -Style Heading2 -Name 'Fabric Interconnect Ethernet Uplink Port Channels' {
                $UcsUplinkPortChannel = Get-UcsUplinkPortChannel | Sort-Object Name | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, OperSpeed, OperState, Transport
                $UcsUplinkPortChannel | Table -Name 'Fabric Interconnect Ethernet Uplink Port Channels' 
            }

            Section -Style Heading2 -Name 'Fabric Interconnect Ethernet Uplink Port Channel Member' {
                $UcsUplinkPortChannelMember = Get-UcsUplinkPortChannelMember | Sort-Object Dn |Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Membership 
                $UcsUplinkPortChannelMember | Table -Name 'Fabric Interconnect Ethernet Uplink Port Channel Member' 
            }

            Section -Style Heading2 -Name 'QoS System Class Configuration' {
                $UcsQosClass = Get-UcsQosClass | Select-Object Priority, AdminState, Cos, Weight, Drop, Mtu
                $UcsQosClass | Table -Name 'QoS System Class Configuration' 
            }

            Section -Style Heading2 -Name 'Ethernet VLANs' {
                $UcsVlan = Get-UcsVlan = Get-UcsVlan | Where-Object {$_.IfRole -eq 'network'} | Sort-Object Id | Select-Object Id, Name, SwitchId
                $UcsVlan | Table -Name 'Ethernet VLANs' 
            }
        }
        <#
        Section -Style Heading2 -Name 'Appliances' {
        }

        Section -Style Heading2 -Name 'Internal LAN' {
        }
        #>
        Section -Style Heading2 -Name 'Policies' {
            Section -Style Heading3 -Name 'QoS Policies' {
                $UcsQosPolicy = Get-UcsQosPolicy | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name
                $UcsQosPolicy | Table -Name 'QoS Policies' 
            }

            Section -Style Heading3 -Name 'QoS vNIC Policy Map' {
                $UcsVnicEgressPolicy = Get-UcsVnicEgressPolicy | Sort-Object Prio | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Prio
                $UcsVnicEgressPolicy | Table -Name 'QoS vNIC Policy Map' 
            }

            Section -Style Heading3 -Name 'Network Control Policies' {
                $UcsNetworkControlPolicy = Get-UcsNetworkControlPolicy | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, Cdp, UplinkFailAction
                $UcsNetworkControlPolicy | Table -Name 'Network Control Policies' 
            }

            Section -Style Heading3 -Name 'vNIC Templates' {
                $UcsVnicTemplate = Get-UcsVnicTemplate | Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, Descr, SwitchId, TemplType, IdentPoolName, Mtu, NwCtrlPolicyName, QosPolicyName
                $UcsVnicTemplate | Table -Name 'vNIC Templates' 
            }

            Section -Style Heading3 -Name 'Ethernet VLAN to vNIC Mappings' {
                $UcsAdaptorVlan = Get-UcsAdaptorVlan | Sort-Object Dn |Select-Object @{L = 'Distinguished Name'; E = {$_.Dn}}, Name, Id, SwitchId
                $UcsAdaptorVlan | Table -Name 'Ethernet VLAN to vNIC Mappings' 
            }
        }

        Section -Style Heading2 -Name 'Pools' {
            Section -Style Heading3 -Name 'IP Pools' {
                $UcsIpPool = Get-UcsIpPool | Select-Object Dn, Name, AssignmentOrder, Size
                $UcsIpPool | Table -Name 'Ethernet VLAN to vNIC Mappings' 
            }

            Section -Style Heading3 -Name 'IP Pool Blocks' {
                $UcsIpPoolBlock = Get-UcsIpPoolBlock | Select-Object Dn, From, To, Subnet, DefGw
                $UcsIpPoolBlock | Table -Name 'IP Pool Blocks' 
            }

            Section -Style Heading3 -Name 'CIMC IP Pool Assignments' {
                $UcsIpPoolAddr = Get-UcsIpPoolAddr | Sort-Object AssignedToDn | Where-Object {$_.Assigned -eq 'yes'} | Select-Object AssignedToDn, Id 
                $UcsIpPoolAddr | Table -Name 'CIMC IP Pool Assignments' 
            }

            Section -Style Heading3 -Name 'MAC Address Pools' {
                $UcsMacPool = Get-UcsMacPool | Select-Object Dn, Name, AssignmentOrder, Size, Assigned
                $UcsMacPool | Table -Name 'MAC Address Pools' 
            }

            Section -Style Heading3 -Name 'MAC Address Pool Blocks' {
                $UcsMacMemberBlock = Get-UcsMacMemberBlock | Select-Object Dn, From, To
                $UcsMacMemberBlock | Table -Name 'MAC Address Pool Blocks' 
            }

            Section -Style Heading3 -Name 'MAC Address Pool Assignments' {
                $UcsVnic = Get-UcsVnic | Sort-Object Dn | Select-Object Dn, IdentPoolName, Addr | Where-Object {$_.Addr -ne 'derived'}
                $UcsVnic | Table -Name 'MAC Address Pool Assignments' 
            }
        }
    }

    Section -Style Heading1 -Name 'SAN' {
        Section -Style Heading2 -Name 'SAN Cloud' {
            Section -Style Heading3 -Name 'Fabric Interconnect Fibre Channel Switching Mode' {
                $UcsSanCloud = Get-UcsSanCloud | Select-Object Rn, Mode
                $UcsSanCloud | Table -Name 'Fabric Interconnect Fibre Channel Switching Mode' 
            }

            Section -Style Heading3 -Name 'Fabric Interconnect FC Uplink Ports' {
                $UcsFiFcPort = Get-UcsFiFcPort | Select-Object EpDn, SwitchId, SlotId, PortId, LicState, Mode, OperSpeed, OperState, wwn | Sort-Object -descending  | where-object {$_.OperState -ne 'sfp-not-present'}
                $UcsFiFcPort | Table -Name 'Fabric Interconnect FC Uplink Ports' 
            }

            Section -Style Heading3 -Name 'Fabric Interconnect FC Uplink Port Channels' {
                $UcsFcUplinkPortChannel = Get-UcsFcUplinkPortChannel | Select-Object Dn, Name, OperSpeed, OperState, Transport
                $UcsFcUplinkPortChannel | Table -Name 'Fabric Interconnect FC Uplink Port Channels' 
            }

            Section -Style Heading3 -Name 'Fabric Interconnect FCoE Uplink Ports' {
                $UcsFabricPort = Get-UcsFabricPort | Where-Object {$_.IfRole -eq 'fcoe-uplink'} | Select-Object IfRole, EpDn, LicState, OperState, OperSpeed
                $UcsFabricPort | Table -Name 'Fabric Interconnect FCoE Uplink Ports' 
            }

            Section -Style Heading3 -Name 'Fabric Interconnect FCoE Uplink Port Channels' {
                $UcsFabricFcoeSanPc = Get-UcsFabricFcoeSanPc | Select-Object Dn, Name, FcoeState, OperState, Transport, Type
                $UcsFabricFcoeSanPc | Table -Name 'Fabric Interconnect FCoE Uplink Port Channels' 
            }
            <#
        Section -Style Heading2 -Name 'Storage Cloud' {
        }

        Section -Style Heading2 -Name 'Policies' {
        }

        Section -Style Heading2 -Name 'Pools' {
        }
        #>
        }
    }

    Section -Style Heading1 -Name 'VM' {
        <#
    Section -Style Heading2 -Name 'Clusters' {
    }

    Section -Style Heading2 -Name 'Fabric Network Sets' {
    }

    Section -Style Heading2 -Name 'Port Profiles' {
    }

    Section -Style Heading2 -Name 'VM Networks' {
    }

    Section -Style Heading2 -Name 'Microsoft' {
    }

    Section -Style Heading2 -Name 'VMware' {
    }
    
}

Section -Style Heading1 -Name 'Storage' {
    Section -Style Heading2 -Name 'Storage Profiles' {
    }

    Section -Style Heading2 -Name 'Storaage Policies' {
    }
}

Section -Style Heading1 -Name 'Chassis' {
    Section -Style Heading2 -Name 'Chassis Profiles' {
    }

    Section -Style Heading2 -Name 'Chassis Profile Templates' {
    }

    Section -Style Heading2 -Name 'Policies' {
    }
}

Section -Style Heading1 -Name 'Admin' {
    Section -Style Heading2 -Name 'User Management' {
    }

    Section -Style Heading2 -Name 'Communication Management' {
    }

    Section -Style Heading2 -Name 'Time Zone Management' {
    }
    
    Section -Style Heading2 -Name 'License Management' {
    }
    #>
    }
    #endregion Script Body
}
# Create and export document to specified format.
$Document | Export-Document -Path $Path -Format $Format

# Disconnect UCS Chassis
Disconnect-Ucs -Ucs $UCS