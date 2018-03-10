#requires -Modules @{ModuleName="PScribo";ModuleVersion="0.7.21.110"},PureStoragePowerShellSDK

#region Script Help
<#
.SYNOPSIS  
    PowerShell script to document the configuration of Pure Storage FlashArray SAN infrastucture in Word/HTML/XML/Text formats
.DESCRIPTION
    Documents the configuration of Pure Storage SAN infrastucture in Word/HTML/XML/Text formats
.NOTES
    Version:        0.1
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
    Credits:        @iainbrighton - PScribo module
.LINK
    https://github.com/tpcarman/Documentation-Scripts
    https://github.com/iainbrighton/PScribo	
.PARAMETER PfaArray
    Specifies the IP/FQDN of the Pure Storage FlasArray on which to connect.
    Multiple storage arrays may be specified, separated by a comma. 
    This parameter is mandatory.
.PARAMETER ReportName
    Specifies the report name.
    This parameter is optional.
    By default, the report name is 'Pure Storage As Built Documentation'.  
.PARAMETER Author
    Specifies the report's author.
    This parameter is optional and has a default value.
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
    This parameter is optional. If not specified the report will be saved in the current directory/folder.
.PARAMETER AddDateTime
    Specifies whether to append a date/time string to the report filename.
    This parameter is optional. 
    By default, the date/time string is not added to the report filename.
.PARAMETER Healthcheck
    (Currently Not in Use)
	Highlights certain issues within the Pure Storage environment.
    This parameter is optional and by default is set to $False.

.PARAMETER CompanyName
    Specifies the Company Name
    This parameter is optional and does not have a default value.
.PARAMETER CompanyContact
    Specifies the Company Contact's Name
    This parameter is optional and does not have a default value.
.PARAMETER CompanyEmail
    Specifies the Company Contact's Email Address
    This parameter is optional and does not have a default value.
.PARAMETER CompanyPhone
    Specifies the Company Contact's Phone Number
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

#>
#endregion Script Help

#region Script Parameters
[CmdletBinding()]
Param(

    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Specify the IP/FQDN of the Pure Storage array')]
    [ValidateNotNullOrEmpty()]
    [Alias("Array")] 
    [Array]$PfaArray = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the document output format')]
    [ValidateNotNullOrEmpty()]
    [Alias("Output")]
    [ValidateSet("Word", "Html", "Text", "Xml")]
    [Array]$Format = 'WORD',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the path to save the report')]
    [ValidateNotNullOrEmpty()]
    [Alias("Folder")]
    [String]$Path = $env:USERPROFILE + '\Documents',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the document report style')]
    [ValidateNotNullOrEmpty()] 
    [String]$Style = 'Default',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify whether to append a date/time string to the report filename')]
    [Switch]$AddDateTime = $False,

    [Parameter(Mandatory = $False, HelpMessage = 'Highlights any configuration issues within the report')]
    [Switch]$Healthcheck = $False,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report name')]
    [ValidateNotNullOrEmpty()] 
    [String]$ReportName = 'Pure Storage As Built Documentation',
    
    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report author name')]
    [ValidateNotNullOrEmpty()] 
    [String]$Author = $env:USERNAME,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report version number')]
    [ValidateNotNullOrEmpty()] 
    [String]$Version = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report document status')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Draft", "Updated", "Released")] 
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
        Style -Name 'Title' -Size 24 -Color 'F05423' -Font 'Calibri' -Align Center
        Style -Name 'Title 2' -Size 18 -Color '2F2F2F' -Font 'Calibri' -Align Center
        Style -Name 'Title 3' -Size 12 -Color '2F2F2F' -Font 'Calibri' -Align Left
        Style -Name 'Heading 1' -Size 16 -Color 'F05423' -Font 'Calibri'
        Style -Name 'Heading 2' -Size 14 -Color 'F05423' -Font 'Calibri'
        Style -Name 'Heading 3' -Size 12 -Color 'F05423' -Font 'Calibri'
        Style -Name 'Heading 4' -Size 11 -Color 'F05423' -Font 'Calibri'
        Style -Name 'Heading 5' -Size 10 -Color 'F05423' -Font 'Calibri' -Italic
        Style -Name 'H1 Exclude TOC' -Size 16 -Color 'F05423' -Font 'Calibri'
        Style -Name 'Normal' -Size 10 -Font 'Calibri' -Default
        Style -Name 'TOC' -Size 16 -Color 'F05423' -Font 'Calibri'
        Style -Name 'TableDefaultHeading' -Size 10 -Color 'FFFFFF' -BackgroundColor '2F2F2F' -Font 'Calibri'
        Style -Name 'TableDefaultRow' -Size 10 -Font 'Calibri'
        Style -Name 'TableDefaultAltRow' -Size 10 -BackgroundColor 'DDDDDD' -Font 'Calibri'
        Style -Name 'Error' -Size 10 -Font 'Calibri' -BackgroundColor 'EA5054'
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
    
    foreach ($Endpoint in $PfaArray) {
        $Credentials = Get-Credential -Message "Credentials for Pure Storage array $Endpoint" 
        [array]$Arrays += New-PfaArray -EndPoint $Endpoint -Credentials $Credentials -IgnoreCertificateError
    }
    
    #endregion Script Variables

    #region Script Body
    $ArraySummary = @()
    foreach ($array in $arrays) {
        PageBreak
        $ArrayName = (Get-PfaArrayAttributes $Array).array_name
        Section -Style Heading1 $Arrayname {
            Section -Style Heading2 'System Summary' {
                Section -Style Heading3 'Array Summary' {
                    $RemoteAssist = (Get-PfaRemoteAssistSession $array).status
                    $PhoneHome = (Get-PfaPhoneHomeStatus $array).phonehome
                    $ArraySummary = Get-PfaArrayAttributes $Array | Sort-Object array_name | Select-Object @{L = "Name"; E = {$_.array_name}}, @{L = "Revision"; E = {$_.revision}}, `
                    @{L = "Remote Assist"; E = {$RemoteAssist}}, @{L = "Phone Home"; E = {$PhoneHome}}
                    $ArraySummary | Table -Name 'Array Summary' 
                }

                Section -Style Heading3 'Storage Summary' {
                    $StorageSummary = Get-PfaArraySpaceMetrics $Array | Select-Object @{L = "Total TB"; E = {[math]::Round(($_.capacity) / 1TB, 2)}}, `
                    @{N = "Used TB"; E = {[math]::Round(($_.total) / 1TB, 2)}}, @{L = "% Used"; E = {[math]::Truncate(($_.total / $_.capacity) * 100)}}, `
                    @{L = "Volumes GB"; E = {[math]::Round(($_.volumes) / 1GB, 2)}}, @{L = "Snapshots GB"; E = {[math]::Round(($_.snapshots) / 1GB, 2)}}, `
                    @{L = "Shared Space GB"; E = {[math]::Round(($_.shared_space) / 1GB, 2)}}, @{L = "Data Reduction"; E = {[math]::Round(($_.data_reduction), 2)}}
                    $StorageSummary | Table -Name 'Storage Summary' 
                }

                Section -Style Heading3 'Controller Summary' {
                    $ControllerSummary = Get-PfaControllers $Array | Sort-Object mode | Select-Object @{L = "Name"; E = {$_.name}}, @{L = "Mode"; E = {$_.mode}}, `
                    @{L = "Model"; E = {$_.model}}, @{L = "Purity Version"; E = {$_.version}}, @{L = "Status"; E = {$_.status}}
                    $ControllerSummary | Table -Name 'Controller Summary' 
                }
   
            }

            Section -Style Heading2 'Hardware' {
            
                Section -Style Heading3 'Network Configuration' {
                    $NetworkConfig = Get-PfaNetworkInterfaces $array | Sort-Object name | Select-Object @{L = "Name"; E = {$_.name}}, @{L = "Enabled"; E = {$_.enabled}}, `
                    @{L = "Address"; E = {$_.address}}, @{L = "Netmask"; E = {$_.netmask}}, @{L = "Gateway"; E = {$_.gateway}}, @{L = "MTU"; E = {$_.mtu}}, `
                    @{L = "VLAN"; E = {$_.vlan}}, @{L = "Speed (GB)"; E = {($_.speed) / 1000000000}}, @{L = "HW Address"; E = {$_.address}}, `
                    @{L = "Services"; E = {$_.services}}
                    $NetworkConfig | Table -Name 'Network Configuration' -List -ColumnWidths 50, 50  
                }

                if ((Get-PfaArrayPorts $Array).wwn) {
                    Section -Style Heading3 'WWN Target Ports' {
                        $WWNTarget = Get-PfaArrayPorts $Array | Sort-Object name | Select-Object @{L = "Port"; E = {$_.name}}, @{L = "WWN"; E = {$_.wwn}} #,@{L="Address"; E={$_.portal}}
                        $WWNTarget | Table -Name 'WWN Target Ports' 
                    }
                    
                }
                else {
                    Section -Style Heading3 'IQN Target Ports' {
                        $IQNTarget = Get-PfaArrayPorts $Array | Sort-Object name | Select-Object @{L = "Port"; E = {$_.name}}, @{L = "IQN"; E = {$_.iqn}} #,@{L="Address"; E={$_.portal}}
                        $IQNTarget | Table -Name 'IQN Target Ports' 
                    }
                }

                Section -Style Heading3 'Disk Specifications' {
                    $DiskSpec = Get-PfaAllDriveAttributes $Array | Select-Object @{L = "Name"; E = {$_.name}}, @{L = "Capacity GB"; E = {($_.capacity) / 1GB}}, `
                    @{L = "Type"; E = {$_.type}}, @{L = "Status"; E = {$_.status}}
                    $DiskSpec | Table -Name 'Disk Specifications' -ColumnWidths 25, 25, 25, 25             
                }
            }

            Section -Style Heading2 'System' {

                Section -Style Heading3 'Alert Email Configuration' {
                    $RelayHost = (Get-PfaRelayHost $array).relayhost
                    $SenderDomain = (Get-PfaSenderDomain $array).senderdomain
                    $EmailConfig = Get-PfaArrayAttributes $Array | Select-Object @{L = "Array"; E = {$_.array_name}}, @{L = "Relay Host"; E = {$RelayHost}}, `
                    @{L = "Sender Domain"; E = {$SenderDomain}}
                    $EmailConfig | Table -Name 'Alert Email Configuration' 
                }

                Section -Style Heading3 'Alert Recipients' {
                    $Recipients = Get-PfaAlerts $array | Sort-Object name | Select-Object @{L = "Name"; E = {$_.name}}, @{L = "Enabled"; E = {$_.enabled}}
                    $Recipients | Table -Name 'Alert Recipients' -ColumnWidths 50, 50 
                }

                Section -Style Heading3 'DNS' {
                    $DNSConfig = Get-PfaDnsAttributes $array | Select-Object @{L = "Domain"; E = {$_.domain}}, @{L = "DNS Server(s)"; E = {$_.nameservers -join ", "}}
                    $DNSConfig | Table -Name 'DNS' -ColumnWidths 50, 50 
                }

                Section -Style Heading3 'SNMP' {
                    $SNMPConfig = Get-PfaSnmpManagers $Array | Select-Object @{L = "Name"; E = {$_.name}}, @{L = "Community"; E = {$_.community}}, `
                    @{L = "Privacy Protocol"; E = {$_.privacy_protocol}}, @{L = "Auth Protocol"; E = {$_.auth_protocol}}, `
                    @{L = "Host"; E = {$_.host}}, @{L = "Version"; E = {$_.version}}, @{L = "User"; E = {$_.user}}, @{L = "Privacy Passphrase"; E = {$_.privacy_passphrase}}, `
                    @{L = "Auth Passphrase"; E = {$_.auth_passphrase}}
                    $SNMPConfig | Table -Name 'SNMP'  -List -ColumnWidths 50, 50
                }

                Section -Style Heading3 'Directory Service Configuration' {
                    $DirectoryService = Get-PfaDirectoryServiceConfiguration $Array | Select-Object @{L = "Enabled"; E = {$_.enabled}}, @{L = "URI"; E = {$_.uri}}, `
                    @{L = "Base DN"; E = {$_.base_dn}}, @{L = "Bind User"; E = {$_.bind_user}}, @{L = "Check Peer"; E = {$_.check_peer}}
                    $DirectoryService | Table -Name 'Directory Service Configuration' 

                    Section -Style Heading4 'Directory Service Groups' {
                        $DirectoryServiceGroups = Get-PfaDirectoryServiceGroups $Array | Select-Object @{L = "Group Base"; E = {($_.group_base)}}, `
                        @{L = "Array Admin Group"; E = {$_.array_admin_group}}, @{L = "Storage Admin Group"; E = {$_.storage_admin_group}}, `
                        @{L = "Read Only Group"; E = {$_.readonly_group}}
                        $DirectoryServiceGroups | Table -Name 'Directory Service Groups' -ColumnWidths 25, 25, 25, 25  
                    }
                }

            
                Section -Style Heading3 'SSL Certificate' {
                    $SSL = Get-PfaCurrentCertificateAttributes $Array | Select-Object @{L = "Status"; E = {$_.status}}, @{L = "Key Size"; E = {$_.key_size}}, `
                    @{L = "Issued To"; E = {$_.issued_to}}, @{L = "Issued By"; E = {$_.issued_by}}, @{L = "Valid From"; E = {$_.valid_from}}, `
                    @{L = "Valid To"; E = {$_.valid_to}}, @{L = "Country"; E = {$_.country}}, @{L = "State/Province"; E = {$_.state}}, `
                    @{L = "Locality"; E = {$_.locality}}, @{L = "Organization"; E = {$_.organization}}, @{L = "Organization Unit"; E = {$_.organizational_unit}}, `
                    @{L = "Email"; E = {$_.email}}
                    $SSL | Table -Name 'SSL Certificate' -List -ColumnWidths 50, 50 
                }   

            }

            Section -Style Heading2 'Storage' {

                Section -Style Heading3 'Hosts' {
                    if ((Get-PfaHosts $Array).wwn) {
                        $Hosts = Get-PfaHosts $Array | Sort-Object name | Select-Object @{L = "Host"; E = {$_.name}}, @{L = "Host Group"; E = {$_.hgroup}}, @{L = "WWN"; E = {$_.wwn -join ", "}}
                    }
                    else {
                        $Hosts = Get-PfaHosts $Array | Sort-Object name | Select-Object @{L = "Host"; E = {$_.name}}, @{L = "Host Group"; E = {$_.hgroup}}, @{L = "IQN"; E = {$_.iqn -join ", "}}
                    }
                    $Hosts | Table -Name 'Storage' 
                }

                Section -Style Heading3 'Host Groups' {
                    $HostGroups = Get-PfaHostGroups $Array | Sort-Object name | Select-Object @{L = "Host Group"; E = {$_.name}}, @{L = "Hosts"; E = {$_.hosts -join ", "}}
                    $Hostgroups | Table -Name 'Host Groups' -ColumnWidths 50, 50 
                }

                Section -Style Heading3 'Volumes' {
                    $PfaVols = Get-PfaVolumes $Array
                    $Vols = @()
                    foreach ($PfaVol in $PfaVols) {
                        $Vols += Get-PfaVolumeHostGroupConnections -Array $Array -VolumeName $PfaVol.name
                    }
                    $Volumes = $Vols | Sort-Object host, lun, name, hgroup | Select-Object @{L = "Host Name"; E = {$_.host}}, @{L = "Volume"; E = {$_.name}}, @{L = "LUN"; E = {$_.lun}}, `
                    @{L = "Size GB"; E = {($_.size) / 1GB}}, @{L = "Host Group"; E = {$_.hgroup}}
                    $Volumes | Table -Name 'Volumes' 
                }
            }

            Section -Style Heading2 'Protection' {

                Section -Style Heading3 'Connected Arrays' {
                    $Connections = Get-PfaArrayConnections $array | Sort-Object name | Select-Object @{L = "Name"; E = {$_.array_name}}, @{L = "ID"; E = {$_.id}}, `
                    @{L = "Version"; E = {$_.version}}, @{L = "Management Address"; E = {$_.management_address}}, @{L = "Replication Address"; E = {$_.replication_address}}, `
                    @{L = "Connected"; E = {$_.connected}}, @{L = "Type"; E = {$_.type}}, @{L = "Throttled"; E = {$_.throttled}}
                    $Connections | Table -Name 'Connected Arrays' -List -ColumnWidths 50, 50 
                }

                Section -Style Heading3 'Protection Groups' {
                    $ProtectionGroups = Get-PfaProtectionGroups $Array | Sort-Object name | Select-Object @{L = "Name"; E = {$_.name}}, @{L = "Host Group(s)"; E = {$_.hgroups}}, `
                    @{L = "Source"; E = {$_.source}}, @{L = "Targets"; E = {($_.targets).name}}, @{L = "Replication Allowed"; E = {($_.targets).allowed}}
                    $ProtectionGroups | Table -Name 'Protection Groups' 
                }

                Section -Style Heading3 'Protection Group Schedules' {
                    $PGSchedules = Get-PfaProtectionGroupSchedules $Array | Sort-Object name | Select-Object @{L = "Name"; E = {$_.name}}, @{L = "Snapshot Enabled"; E = {$_.snap_enabled}}, `
                    @{L = "Snapshot Frequency Mins"; E = {($_.snap_frequency) / 60}}, @{L = "Snapshot At"; E = {$_.snap_at}}, @{L = "Snapshot Replication Enabled"; E = {$_.replicate_enabled}}, `
                    @{L = "Snapshot Replication Frequency Mins"; E = {($_.replicate_frequency) / 60}}, @{L = "Replicate At"; E = {$_.replicate_at}}, `
                    @{L = "Snapshot Replication Blackout Times"; E = {$_.replicate_blackout}}
                    $PGSchedules | Table -Name 'Protection Group Schedules' 
                }
            
                Section -Style Heading3 'Volume Snapshots (Last 30)' {
                    $VolumeSnaps = Get-PfaVolumeSnapshots $Array -VolumeName * | Sort-Object created -Descending | Select-Object -Last 30 @{L = "Name"; E = {$_.name}}, `
                    @{L = "Source"; E = {$_.source}}, @{L = "Created"; E = {$_.created}}, @{L = "Size GB"; E = {($_.size) / 1GB}}
                    $VolumeSnaps | Table -Name 'Volume Snapshots' 
                }
    
            }
        }
    }
    #endregion Document Body
}

# Create and export document to specified format.
$Document | Export-Document -Path $Path -Format $Format

# Disconnect Pure Storage Array
foreach ($Arrayt in $Arrays) {
    Disconnect-PfaArray -Array $Array
}