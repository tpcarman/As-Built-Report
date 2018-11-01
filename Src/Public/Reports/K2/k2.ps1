#requires -Module @{ModuleName="PScribo";ModuleVersion="0.7.23"},@{ModuleName="K2.Powershell";ModuleVersion="1.4.5.2"}

<#
.SYNOPSIS  
    PowerShell script to document the configuration of Kaminario Array in Word/HTML/XML/Text formats
.DESCRIPTION
    Documents the configuration of Kaminario Array in Word/HTML/XML/Text formats using PScribo.
.NOTES
    Version:        0.1
    Author:         Nick Lepore
    Twitter:        @midnigh7
    Github:         Midnigh7

    Credits:        Iain Brighton (@iainbrighton) - PScribo module
                    Tim Carman (@tpcarman)

.LINK
    https://github.com/tpcarman/As-Built-Report
    https://github.com/iainbrighton/PScribo
    https://www.powershellgallery.com/packages/K2.Powershell/
#>

#region Configuration Settings
###############################################################################################
#                                    CONFIG SETTINGS                                          #
###############################################################################################

# If custom style not set, use Kaminario style
if (!$StyleName) {
    .\Styles\K2Storage.ps1
}

# Connect to Kaminario Arrays using supplied credentials
$K2Arrays = $Target.split(",")
foreach ($Endpoint in $K2Arrays) {
    $K2User = ($Credentials).Username
    $K2Password = ($Credentials.GetNetworkCredential()).password
    Connect-K2Array -K2Array $Endpoint -Username $K2User -Password $K2Password

    #endregion Configuration Settings

    #region Script Body
    ###############################################################################################
    #                                       SCRIPT BODY                                           #
    ###############################################################################################

    $ArrayName = (Get-K2State).system_name
    Section -Style Heading1 $Arrayname {
        Section -Style Heading2 'System Summary' {
            Section -Style Heading3 'Array Summary' {
                $ArraySummary = Get-K2State | Sort-Object array_name | Select-Object @{L = 'System Name'; E = {$_.system_name}}, @{L = 'Version'; E = {$_.system_version}}, 
                @{L = 'Connectivity Type'; E = {$_.system_connectivity_type}}, @{L = 'System State'; E = {$_.state}}
                $ArraySummary | Table -Name 'Array Summary' 
            }
        

            Section -Style Heading3 'Storage Summary' {
                $StorageSummary = Get-K2SystemCapacity | Select-Object @{L = 'Total Capacity TB'; E = {[math]::Round(($_.total) /1GB, 2)}}, 
                @{L = 'Provisioned TB'; E = {[math]::Round(($_.provisioned) / 1GB, 2)}}, @{L = 'Free TB'; E = {[math]::Round($_.free / 1GB, 2)}}, @{L = 'Allocated TB'; E = {[math]::Round(($_.Allocated) / 1GB, 2)}},
                @{L = '% Used'; E = {[math]::round(($_.physical / $_.total ) * 100, 2)}}, @{L = 'Volumes TB'; E = {[math]::Round(($_.provisioned_volumes) / 1TB, 2)}}, 
                @{L = 'Snapshots GB'; E = {[math]::Round(($_.provisioned_snapshots) / 1MB, 2)}}, 
                @{L = 'Physical TB'; E = {[math]::Round(($_.physical) / 1GB, 2)}}
                $StorageSummary | Table -Name 'Storage Summary' -List -ColumnWidths 50, 50
            }  
        }
    

        Section -Style Heading2 'Storage' {

            Section -Style Heading3 'Hosts' {
                $Hosts = Get-K2Host | Sort-Object name | Select-Object @{L = 'Host'; E = {$_.name}}, @{L = 'Host Group'; E = {$_.host_group}}, @{L = 'Type'; E = {$_.type}}
                $Hosts | Table -Name 'Storage' 
            }

            Section -Style Heading3 'Host Groups' {
                $HostGroups = Get-K2HostGroup | Sort-Object name | Select-Object @{L = 'Host Group'; E = {$_.name}}, @{L = "Allow Different Host Types"; E = {$_.allow_different_host_types}}
                $Hostgroups | Table -Name 'Host Groups' -ColumnWidths 50, 50 
            }

            Section -Style Heading3 'Volumes' {
                $K2Vols = Get-K2Volume
                $Vols = @()
                foreach ($K2Vol in $K2Vols) {
                    $Vols += Get-K2Volume -Name $K2Vol.name
                }
                $Volumes = $Vols | Sort-Object name | Select-Object @{L = 'Volume Name'; E = {$_.name}}, @{L = 'VMWare Support'; E = {$_.vmware_support}}, @{L = 'Is Deupe'; E = {$_.is_dedup}},
                @{L = 'Size TB'; E = {($_.size) / 1GB}}, @{L = 'Host Group'; E = {$_.hgroup}}
                $Volumes | Table -Name 'Volumes' 
            }
    
    }

        Section -Style Heading2 'Protection' {

            Section -Style Heading3 'Connected Arrays' {
                $Connections = Get-K2ReplicationPeer | Sort-Object name | Select-Object @{L = 'Remote Name'; E = {$_.name}}, @{L = 'K2 Management IP'; E = {$_.mgmt_host}}, @{L = 'Connectivity State'; E = {$_.mgmt_connectivity_state}}
                $Connections | Table -Name 'Connected Arrays' -List -ColumnWidths 50, 50 
            }

            Section -Style Heading3 'Replicated Volumes' {
                $RepVols = Get-K2ReplicationPeerVolume | Sort-Object name | Select-Object @{L = 'Remote Volume Name'; E = {$_.name}}
                $RepVols | Table -Name 'Replicated Volumes' 
            }

            Section -Style Heading3 'Retention Polices' {
                $RenPolicy = Get-K2RetentionPolicy| Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Snapshots to Keep'; E = {$_.num_snapshots}}, 
                @{L = 'Hours'; E = {$_.hours}}, @{L = 'Days'; E = {$_.days}}, @{L = 'Weeks'; E = {$_.weeks}}
                $RenPolicy | Table -Name 'Protection Group Schedules' 
            }
            
            Section -Style Heading3 'Volume Snapshots (Last 30)' {
                $VolumeSnaps = Get-K2Snapshot | Sort-Object creation_time -Descending | Select-Object -Last 30 @{L = 'Name'; E = {$_.short_name}}, 
                @{L = 'Source'; E = {$_.source}}, @{L = 'Created'; E = {$_.creation_time}}
                $VolumeSnaps | Table -Name 'Volume Snapshots' 
            }
    
        }
    }
    $Null = Disconnect-K2Array -ErrorAction SilentlyContinue
}
#endregion Document Body