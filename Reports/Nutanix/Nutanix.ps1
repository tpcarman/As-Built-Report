#requires -PSSnapin NutanixCmdletsPSSnapin
#requires -Module @{ModuleName="PScribo";ModuleVersion="0.7.23"}

<#
.SYNOPSIS  
    PowerShell script to document the configuration of Nutanix hyperconverged infrastucture in Word/HTML/XML/Text formats
.DESCRIPTION
    Documents the configuration of Nutanix hyperconverged infrastucture in Word/HTML/XML/Text formats using PScribo.
.NOTES
    Version:        0.1
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
    Credits:        Iain Brighton (@iainbrighton) - PScribo module
                    Carl Webster (@carlwebster) - Documentation Script Concept
                    Kees Baggerman (@kbaggerman) - Nutanix Documentation Script Concept
.LINK
    https://github.com/tpcarman/As-Built-Report
    https://github.com/iainbrighton/PScribo
#>

#region Configuration Settings
#---------------------------------------------------------------------------------------------#
#                                    CONFIG SETTINGS                                          #
#---------------------------------------------------------------------------------------------#

# If custom style not set, use Nutanix style
if (!$StyleName) {
    & "$PSScriptRoot\..\..\Styles\Nutanix.ps1"
}

# Connect to Nutanix Cluster using supplied credentials
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
foreach ($Cluster in $Target) {
    if ($Credentials) {
        $NTNXCluster = Connect-NutanixCluster $Cluster -UserName $Credentials.UserName -Password $Credentials.Password -AcceptInvalidSSLCerts -ForcedConnection
    } else {
        $NTNXCluster = Connect-NutanixCluster $Cluster -UserName $UserName -Password $SecurePassword -AcceptInvalidSSLCerts -ForcedConnection
    }
    #endregion Configuration Settings

    #region Script Body
    #---------------------------------------------------------------------------------------------#
    #                                       SCRIPT BODY                                           #
    #---------------------------------------------------------------------------------------------#

    $NTNXClusterInfo = Get-NTNXClusterInfo -NutanixClusters $NTNXCluster
    $HypervisorType = $NTNXClusterInfo.HypervisorTypes
    $NTNXCluster = Get-NTNXCluster | Sort-Object Name
    if ($NTNXCluster) {
        Section -Style Heading1 $NTNXCluster.name {
            Section -Style Heading2 'Cluster Summary' {
                Section -Style Heading3 'Hardware' {
                    $ClusterSummary = [PSCustomObject]@{
                        'Name' = $NTNXCluster.name 
                        'Storage Type' = $NTNXCluster.storageType 
                        'Number of Nodes' = $NTNXCluster.numNodes 
                        'Block Serial(s)' = $NTNXCluster.blockSerials -join ', ' 
                        'Version' = $NTNXCluster.version 
                        'NCC Version' = ($NTNXCluster.nccVersion).TrimStart("ncc-") 
                        'Timezone' = $NTNXCluster.timezone
                    }
                    if ($Healthcheck.Cluster.Version) {
                        $ClusterSummary | Where-Object {$_.'Version' -lt $Healthcheck.Cluster.Version} | Set-Style -Style Warning -Property 'Version'
                    }
                    if ($Healthcheck.Cluster.NccVersion) {
                        $ClusterSummary | Where-Object {$_.'NCC Version' -lt $Healthcheck.Cluster.NccVersion} | Set-Style -Style Warning -Property 'NCC Version'
                    }
                    if ($Healthcheck.Cluster.Timezone) {
                        $ClusterSummary | Where-Object {$_.'Timezone' -ne $Healthcheck.Cluster.Timezone} | Set-Style -Style Critical -Property 'Timezone'
                    }
                    $ClusterSummary | Table -Name 'Cluster Summary'
                }

                Section -Style Heading3 'Network' {
                    $Network = [PSCustomObject]@{
                        'Name' = $NTNXCluster.name 
                        'Cluster Virtual IP Address' = $NTNXCluster.clusterExternalIPAddress 
                        'iSCSI Data Services IP Address' = $NTNXCluster.clusterExternalDataServicesIPAddress 
                        'Subnet' = $NTNXCluster.externalSubnet 
                        'DNS Server(s)' = $NTNXCluster.nameServers -join ', ' 
                        'NTP Server(s)' = $NTNXCluster.ntpServers -join ', '
                    }
                    $Network | Table -Name 'Cluster Network Information'
                }

                Section -Style Heading3 'Controller VMs' {
                    $CVMs = Get-NTNXVM | Where-Object {$_.controllerVm -eq $true}
                    $ControllerVMs = foreach ($CVM in $CVMs) {
                        [PSCustomObject]@{
                            'CVM Name' = $CVM.vmName 
                            'Power State' = $CVM.powerState 
                            'Host' = $CVM.hostName 
                            'IP Address' = $CVM.ipAddresses[0] 
                            'CPUs' = $CVM.numVCPUs 
                            'Memory' = "$([math]::Round(($CVM.memoryCapacityinBytes) / 1GB, 2)) GB"  
                        }
                    }
                    if ($Healthcheck.Cluster.CVM) {
                        $ControllerVMs | Where-Object {$_.'Power State' -eq 'off'} | Set-Style -Style Critical
                    }
                    $ControllerVMs | Sort-Object 'CVM Name' | Table -Name 'Controller VM Summary'
                }
            }

            Section -Style Heading2 'System' {
                $AuthConfig = Get-NTNXAuthConfigDirectory
                if ($AuthConfig) {
                    Section -Style Heading3 'Authentication' {
                        $AuthConfigDirectory = [PSCustomObject]@{
                            'Name' = $AuthConfig.name 
                            'Domain' = $AuthConfig.domain 
                            'URL' = $AuthConfig.DirectoryUrl 
                            'Directory Type' = $AuthConfig.DirectoryType
                            'Connection Type' = $AuthConfig.ConnectionType 
                            'Group Search Type' = $AuthConfig.GroupSearchType
                        }
                        $AuthConfigDirectory | Table -Name 'Authentication'
                    }
                }

                $NTNXSmtpServer = Get-NTNXSmtpServer
                if ($NTNXSmtpServer.Address -ne '') {
                    Section -Style Heading3 'SMTP Server' {
                        $SmtpServer = [PSCustomObject]@{
                            'Address' = $NTNXSmtpServer.address 
                            'Port' = $NTNXSmtpServer.port 
                            'Username' = $NTNXSmtpServer.username
                            'Password' = $NTNXSmtpServer.password
                            'Secure Mode' = $NTNXSmtpServer.secureMode 
                            'From Email Address' = $NTNXSmtpServer.fromEmailAddress
                        }
                        $SmtpServer | Table -Name 'SMTP Server'
                    }
                }

                $NTNXAlertConfig = Get-NTNXAlertConfiguration
                if ($NTNXAlertConfig) {
                    Section -Style Heading3 'Alert Email Configuration' {
                        $AlertConfig = [PSCustomObject]@{
                            'Email Every Alert' = Switch ($NTNXAlertConfig.enable) {
                                $true {'Yes'}
                                $false {'No'}
                            } 
                            'Email Daily Alert' = Switch ($NTNXAlertConfig.enableEmailDigest) {
                                $true {'Yes'}
                                $false {'No'}
                            } 
                            'Nutanix Support Email' = $NTNXAlertConfig.defaultNutanixEmail 
                            'Additional Email Recipients' = $NTNXAlertConfig.emailContactlist -join ', '                         
                        }
                        $AlertConfig | Table -Name 'Alert Email Configuration'
                    }
                }

                # ToDo: SNMP Configuration
                <#
            Section -Style Heading3 'SNMP' {
            }
            #>

                # ToDo: Syslog Configuration
                <#
            Section -Style Heading3 'Syslog' {
            }
            #>

                Section -Style Heading3 'Licensing' {
                    $NTNXLicense = Get-NTNXLicense 
                    $Licensing = [PSCustomObject]@{
                        'Cluster' = $NTNXCluster.name 
                        'License Type' = $NTNXLicense.category
                    }
                    if ($Healthcheck.System.LicenseType) {
                        $Licensing | Where-Object {$_.'License Type' -ne $Healthcheck.System.LicenseType} | Set-Style -Style Warning -Property 'License Type'
                    }
                    $Licensing | Table -Name 'Licensing' -ColumnWidths 50, 50

                    BlankLine
            
                    $NTNXLicenseAllowance = Get-NTNXLicenseAllowance
                    $LicenseAllowance = foreach ($NTNXLicense in $NTNXLicenseAllowance) {
                        [PSCustomObject]@{
                            'Feature' = $NTNXLicense.key 
                            'Permitted' = 'Yes'
                        }
                    }
                    $LicenseAllowance | Table -Name 'License Allowance' -ColumnWidths 50, 50
                }
            }
    
            $NTNXHosts = Get-NTNXHost
            if ($NTNXHosts) {
                Section -Style Heading2 'Hardware' {
                    Section -Style Heading3 'Host Hardware Specifications' {
                        $Hosts = foreach ($NTNXHost in $NTNXHosts) {
                            [PSCustomObject]@{
                                'Name' = $NTNXHost.name 
                                'Serial Number' = $NTNXHost.serial 
                                'Block Model' = $NTNXHost.blockModelName 
                                'Block Serial' = $NTNXHost.blockSerial 
                                'BMC Version' = $NTNXHost.bmcVersion 
                                'BIOS Version' = $NTNXHost.biosVersion 
                                'CPU Model' = $NTNXHost.cpuModel 
                                'CPUs' = $NTNXHost.numCpuSockets 
                                'Cores' = $NTNXHost.numCpuCores
                                'Memory' = "$([math]::Round(($NTNXHost.memoryCapacityinBytes) / 1GB, 0)) GB"
                                'Hypervisor' = $NTNXHost.hypervisorFullname
                            } 
                        }
                        $Hosts | Sort-Object 'Name' | Table -List -Name 'Host Specifications' -ColumnWidths 50, 50
                    }

                    Section -Style Heading3 'Host Network Specifications' {
                        $HostNetworks = foreach ($NTNXHost in $NTNXHosts) {
                            [PSCustomObject]@{
                                'Name' = $NTNXHost.name 
                                'Hypervisor IP Address' = $NTNXHost.hypervisorAddress 
                                'CVM IP Address' = $NTNXHost.serviceVMExternalIP 
                                'IPMI IP Address' = $NTNXHost.ipmiAddress
                            }
                        }
                        $HostNetworks | Sort-Object 'Name' | Table -Name 'Host Network Specifications' -ColumnWidths 25, 25, 25, 25
                    }

                    Section -Style Heading3 'Disk Specifications' {
                        $NTNXDisks = Get-NTNXDisk
                        $Disks = foreach ($NTNXDisk in $NTNXDisks) {
                            [PSCustomObject]@{
                                'Disk ID' = $NTNXDisk.id
                                'Hypervisor IP' = $NTNXDisk.hostName
                                'Location' = $NTNXDisk.location
                                'Tier' = $NTNXDisk.storageTierName 
                                'Disk Size' = "$([math]::Round(($NTNXDisk.disksize) / 1TB, 0)) TB" 
                                'Online' = $NTNXDisk.online 
                                'Status' = ($NTNXDisk.diskStatus).ToLower()
                            } 
                        }
                        if ($Healthcheck.Hardware.DiskOnline) {
                            $Disks | Where-Object {$_.'Online' -ne $true} | Set-Style -Style Critical -Property 'Online'
                        }
                        if ($Healthcheck.Hardware.DiskStatus) {
                            $Disks | Where-Object {$_.'Status' -ne 'normal'} | Set-Style -Style Critical -Property 'Status'
                        }
                        $Disks | Sort-Object 'Hypervisor IP', 'Location', 'Disk ID' | Table -Name 'Disk Specifications' 
                    }
                }
            }
    
            Section -Style Heading2 'Storage' {
                $NTNXContainers = Get-NTNXContainer
                if ($NTNXContainers) {
                    Section -Style Heading3 'Storage Containers' {
                        $Containers = foreach ($NTNXContainer in $NTNXContainers) {
                            [PSCustomObject]@{
                                'Name' = $NTNXContainer.name 
                                'Replication Factor' = "RF $($NTNXContainer.replicationFactor)" 
                                'Compression' = $NTNXContainer.compressionEnabled 
                                'Cache Deduplication' = $NTNXContainer.fingerPrintonWrite
                                'Capacity Deduplication' = ($NTNXContainer.onDiskDedup).ToLower() 
                                'Erasure Coding' = $NTNXContainer.erasureCode 
                                'Maximum Capacity' = "$([math]::Round(($NTNXContainer.maxCapacity) / 1TB, 2)) TB"
                                'Advertised Capacity' = "$([math]::Round(($NTNXContainer.advertisedCapacity) / 1TB, 2)) TB" 
                            }
                        }
                        $Containers | Sort-Object 'Name' | Table -List -Name 'Storage Containers' -ColumnWidths 50, 50
                    }

                    $NTNXStoragePools = Get-NTNXStoragePool
                    if ($NTNXStoragePools) {
                        Section -Style Heading3 'Storage Pools' {
                            $StoragePools = foreach ($NTNXStoragePool in $NTNXStoragePools) {
                                [PSCustomObject]@{
                                    'Name' = $NTNXStoragePool.name
                                    'Disks' = ($NTNXStoragePool.disks).count 
                                    'Maximum Capacity' = "$([math]::Round(($NTNXStoragePool.capacity) / 1TB, 2)) TB" 
                                    'Reserved Capacity' = "$([math]::Round(($NTNXStoragePool.reservedCapacity) / 1TB, 2)) TB"
                                } 
                            }
                            $StoragePools | Sort-Object 'Name' | Table -Name 'Storage Pools' 
                        } 
                    }
        
                    if ($HypervisorType -eq 'kVMware') {
                        $NTNXNfsDatastores = Get-NTNXNfsDatastore
                        if ($NTNXNfsDatastores) {
                            Section -Style Heading3 'NFS Datastores' {
                                $NfsDatastores = foreach ($NTNXNfsDatastore in $NTNXNfsDatastores) {
                                    [PSCustomObject]@{
                                        'Datastore Name' = $NTNXNfsDatastore.datastoreName 
                                        'Host IP' = $NTNXNfsDatastore.hostIpAddress 
                                        'Container' = $NTNXNfsDatastore.containerName 
                                        'Total Capacity' = "$([math]::Round(($NTNXNfsDatastore.capacity) / 1TB, 2)) TB" 
                                        'Free Capacity' = "$([math]::Round(($NTNXNfsDatastore.freeSpace) / 1TB, 2)) TB"
                                    } 
                                }
                                $NfsDatastores | Sort-Object 'Host IP', 'Datastore Name' | Table -Name 'NFS Datastores' 
                            }
                        }
                    }
                }
            }

            if ($HypervisorType -eq 'kKvm') {
                $NTNXVMNetworks = Get-NTNXNetwork
                if ($NTNXVMNetworks) {
                    Section -Style Heading2 'VM Networks' {
                        $VMNetworks = foreach ($NTNXVMNetwork in $NTNXVMNetworks) {
                            [PSCustomObject]@{
                                'VM Network' = $NTNXVMNetwork.name 
                                'VLAN ID' = $NTNXVMNetwork.vlanid
                            }
                        }
                        $VMNetworks | Sort-Object 'VLAN ID' | Table -Name 'VM Networks' -ColumnWidths 50, 50
                    }
                }
            }
    
            $NTNXVMs = Get-NTNXVM | Where-Object {$_.controllerVm -eq $false}
            if ($NTNXVMs) {
                Section -Style Heading2 'VM' {
                    Section -Style Heading3 'Virtual Machines' {
                        $VMs = foreach ($NTNXVM in $NTNXVMs) {
                            [PSCustomObject]@{
                                'VM Name' = $NTNXVM.vmName 
                                'Power State' = $NTNXVM.powerState 
                                'Operating System' = $NTNXVM.guestOperatingSystem 
                                'IP Addresses' = $NTNXVM.ipAddresses -join ', '
                                'vCPUs' = $NTNXVM.numVCPUs
                                'Memory' = "$([math]::Round(($NTNXVM.memoryCapacityInBytes) / 1GB, 0)) GB" 
                                'NICs' = $NTNXVM.numNetworkAdapters 
                                'Disk Capacity' = "$([math]::Round(($NTNXVM.diskCapacityinBytes) / 1GB, 2)) GB"
                                'Host' = $NTNXVM.hostName
                            }
                        }
                        $VMs | Sort-Object 'VM Name' | Table -List -Name 'Virtual Machines' -ColumnWidths 50, 50
                    }
                }
            }

            $NTNXProtectionDomains = Get-NTNXProtectionDomain
            if ($NTNXProtectionDomains -ne $null) {
                Section -Style Heading2 'Data Protection' {
                    Section -Style Heading3 'Protection Domains' {
                        $ProtectionDomains = foreach ($NTNXProtectionDomain in $NTNXProtectionDomains) {
                            [PSCustomObject]@{
                                'Name' = $NTNXProtectionDomain.name 
                                'Active' = $NTNXProtectionDomain.active 
                                'Remote Site(s)' = $NTNXProtectionDomain.remoteSiteNames 
                                'Pending Replications' = $NTNXProtectionDomain.pendingReplicationCount 
                                'Ongoing Replications' = $NTNXProtectionDomain.ongoingReplicationCount 
                                'Schedule Suspended' = $NTNXProtectionDomain.schedulesSuspended 
                                'Written Bytes' = $NTNXProtectionDomain.totalUserWrittenBytes     
                            }
                        }
                        $ProtectionDomains | Sort-Object 'Name' | Table -Name 'Protection Domains' 
                    }

                    $NTNXPDReplications = Get-NTNXProtectionDomainReplication
                    if ($NTNXPDReplications -ne $null) {
                        Section -Style Heading3 'Protection Domain Replication' {
                            $ProtectionDomainReplications = foreach ($NTNXPDReplication in $NTNXPDReplications) {
                                [PSCustomObject]@{
                                    'Name' = $NTNXPDReplication.protectionDomainName 
                                    'Remote Sites' = $NTNXPDReplication.remoteSiteName 
                                    'Snapshot ID' = $NTNXPDReplication.snapshotId 
                                    'Data Completed' = "$([math]::Round(($NTNXPDReplication.completedBytes) / 1TB, 2)) TB" 
                                    '% Complete' = $NTNXPDReplication.completedPercentage
                                    'Minutes to Complete' = [math]::Round(($NTNXPDReplication.replicationTimetoCompleteSecs) / 60, 2)
                                }
                            }
                            $ProtectionDomainReplications | Sort-Object 'Name' | Table -Name 'Protection Domain Replication' 
                        }
                    }                    

                    $NTNXPDSnapshots = Get-NTNXProtectionDomainSnapshot
                    if ($NTNXPDSnapshots -ne $null) {
                        Section -Style Heading3 'Protection Domain Snapshots' {
                            $ProtectionDomainSnapshots = foreach ($NTNXPDSnapshot in $NTNXPDSnapshots) {
                                [PSCustomObject]@{
                                    'Protection Domain' = $NTNXPDSnapshot.protectionDomainName 
                                    'State' = $NTNXPDSnapshot.state 
                                    'Snapshot ID' = $NTNXPDSnapshot.snapshotId 
                                    'Consistency Groups' = $NTNXPDSnapshot.consistencyGroups 
                                    'Remote Site(s)' = $NTNXPDSnapshot.remoteSiteNames 
                                    'Size in Bytes' = $NTNXPDSnapshot.sizeInBytes
                                }
                            }
                            $ProtectionDomainSnapshots | Sort-Object 'Protection Domain' | Table -Name 'Protection Domain Snapshots' 
                        }
                    }                    

                    $NTNXUnprotectedVMs = Get-NTNXUnprotectedVM
                    if ($NTNXUnprotectedVMs -ne $null) {
                        Section -Style Heading3 'Unprotected VMs' {
                            $UnprotectedVMs = foreach ($NTNXUnprotectedVM in $NTNXUnprotectedVMs) {
                                [PSCustomObject]@{
                                    'VM Name' = $NTNXUnprotectedVM.vmName 
                                    'Power State' = $NTNXUnprotectedVM.powerState
                                    'Operating System' = $NTNXUnprotectedVM.guestOperatingSystem 
                                    'CPUs' = $NTNXUnprotectedVM.numVCPUs 
                                    'NICs' = $NTNXUnprotectedVM.numNetworkAdapters 
                                    'Disk Capacity' = "$([math]::Round(($NTNXUnprotectedVM.diskCapacityinBytes) / 1GB, 2)) GB" 
                                    'Host' = $NTNXUnprotectedVM.hostName
                                }
                            }
                            $UnprotectedVMs | Sort-Object 'VM Name' | Table -Name 'Unprotected VMs' 
                        }
                    }
                }
            }

            $NTNXRemoteSites = Get-NTNXRemoteSite
            if ($NTNXRemoteSites) {
                Section -Style Heading2 'Remote Sites' {
                    $RemoteSites = foreach ($NTNXRemoteSite in $NTNXRemoteSites) {
                        [PSCustomObject]@{
                            'Name' = $NTNXRemoteSite.name 
                            'Capabilities' = $NTNXRemoteSite.capabilities -join ', ' 
                            'Remote IP' = $NTNXRemoteSite.RemoteIpPorts.keys -join ', '
                            'Metro Ready' = Switch ($NTNXRemoteSite.metroReady) {
                                $true {'Yes'}
                                $false {'No'}
                            }
                            'Use SSH Tunnel' = Switch ($NTNXRemoteSite.sshEnabled) {
                                $true {'Yes'}
                                $false {'No'}
                            }
                            'Compress On Wire' = Switch ($NTNXRemoteSite.compressionEnabled) {
                                $true {'Yes'}
                                $false {'No'}
                            }
                            'Use Proxy' = Switch ($NTNXRemoteSite.proxyEnabled) {
                                $true {'Yes'}
                                $false {'No'}
                            }
                            'Bandwidth Throttling' = Switch ($NTNXRemoteSite.bandwidthPolicyEnabled) {
                                $true {'Enabled'}
                                $false {'Disabled'}
                            }                    
                        }
                    }
                    $RemoteSites | Sort-Object 'Name' | Table -Name 'Remote Sites' -List -ColumnWidths 50, 50
                }
            }
        }
    }
    
    # Disconnect Nutanix Cluster
    $Null = Disconnect-NutanixCluster $Cluster
}
#endregion Script Body