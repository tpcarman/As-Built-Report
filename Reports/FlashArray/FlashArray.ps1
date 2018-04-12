#requires -Module @{ModuleName="PScribo";ModuleVersion="0.7.22"},PureStoragePowerShellSDK

#region Configuration Settings
###############################################################################################
#                                    CONFIG SETTINGS                                          #
###############################################################################################
$ScriptPath = (Get-Location).Path
$ReportConfigFile = Join-Path $ScriptPath $("Reports\$Type\$Type.json")
If (Test-Path $ReportConfigFile -ErrorAction SilentlyContinue) {
    $ReportConfig = Get-Content $ReportConfigFile | ConvertFrom-json
}
# If custom style not set, use Pure Storage style
if (!$StyleName) {
    .\Styles\PureStorage.ps1
}

# Connect to Pure Storage FlashArrays using supplied credentials
$PfaArrays = $IP.split(",")
foreach ($Endpoint in $PfaArrays) {
    [array]$Arrays += New-PfaArray -EndPoint $Endpoint -Credentials $Credentials -IgnoreCertificateError
}
#endregion Configuration Settings

#region Script Body
###############################################################################################
#                                       SCRIPT BODY                                           #
###############################################################################################

$ArraySummary = @()
foreach ($array in $arrays) {
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
                $StorageSummary = Get-PfaArraySpaceMetrics $Array | Select-Object @{L = "Capacity TB"; E = {[math]::Round(($_.capacity) / 1TB, 2)}}, `
                @{N = "Used TB"; E = {[math]::Round(($_.total) / 1TB, 2)}}, @{N = "Free TB"; E = {[math]::Round(($_.capacity - $_.total) / 1TB, 2)}}, `
                @{L = "% Used"; E = {[math]::Truncate(($_.total / $_.capacity) * 100)}}, @{L = "Volumes GB"; E = {[math]::Round(($_.volumes) / 1GB, 2)}}, `
                @{L = "Snapshots GB"; E = {[math]::Round(($_.snapshots) / 1GB, 2)}}, @{L = "Shared Space GB"; E = {[math]::Round(($_.shared_space) / 1GB, 2)}}, `
                @{L = "System GB"; E = {[math]::Round(($_.system) / 1GB, 2)}}, @{L = "Data Reduction"; E = {[math]::Round(($_.data_reduction), 2)}}, `
                @{L = "Total Reduction"; E = {[math]::Round(($_.total_reduction), 2)}}
                $StorageSummary | Table -Name 'Storage Summary' -List -ColumnWidths 50, 50
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
                    $WWNTarget = Get-PfaArrayPorts $Array | Sort-Object name | Select-Object @{L = "Port"; E = {$_.name}}, @{L = "WWN"; E = {($_.wwn -split "(\w{2})" | Where-Object {$_ -ne ""}) -join ":" }}
                    $WWNTarget | Table -Name 'WWN Target Ports' -ColumnWidths 50, 50
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
                    $Hosts = Get-PfaHosts $Array | Sort-Object name | Select-Object @{L = "Host"; E = {$_.name}}, @{L = "Host Group"; E = {$_.hgroup}}, @{L = "WWN"; E = {($_.wwn | ForEach-Object { (($_ -split "(\w{2})") | Where-Object {$_ -ne ""}) -join ":" }) -join ", "}}    
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
    $Null = Disconnect-PfaArray -Array $Array
}
#endregion Document Body