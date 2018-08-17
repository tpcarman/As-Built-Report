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
###############################################################################################
#                                    CONFIG SETTINGS                                          #
###############################################################################################

# If custom style not set, use Nutanix style
if (!$StyleName) {
    .\Styles\Nutanix.ps1
}

# Connect to Nutanix Cluster using supplied credentials
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Clusters = $Target.split(",")
foreach ($Cluster in $Clusters) {
    $NTNXCluster = Connect-NutanixCluster $Cluster -UserName $UserName -Password $SecurePassword -AcceptInvalidSSLCerts -ForcedConnection

    #endregion Configuration Settings

    #region Script Body
    ###############################################################################################
    #                                       SCRIPT BODY                                           #
    ###############################################################################################

    $NTNXClusterInfo = Get-NTNXClusterInfo -NutanixClusters $NTNXCluster
    $HypervisorType = $NTNXClusterInfo.HypervisorTypes
    $NTNXCluster = Get-NTNXCluster
    if ($NTNXCluster) {
        Section -Style Heading1 $NTNXCluster.name {
            Section -Style Heading2 'Cluster Summary' {
                Section -Style Heading3 'Hardware' {
                    $ClusterSummary = $NTNXCluster | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Storage Type'; E = {$_.storageType}}, @{L = 'Number of Nodes'; E = {$_.numNodes}}, @{L = 'Block Serial(s)'; E = {$_.blockSerials -join ", "}}, 
                    @{L = 'Version'; E = {$_.version}}, @{L = 'NCC Version'; E = {$_.nccVersion}}, @{L = 'Timezone'; E = {$_.timezone}}
                    $ClusterSummary | Table -Name 'Cluster Summary' 
                }

                Section -Style Heading3 'Network' {
                    $Cluster = $NTNXCluster | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Cluster Virtual IP Address'; E = {$_.clusterExternalIPAddress}}, @{L = 'iSCSI Data Services IP Address'; E = {$_.clusterExternalDataServicesIPAddress}}, 
                    @{L = 'Subnet'; E = {$_.externalSubnet}}, @{L = 'DNS Server(s)'; E = {$_.nameServers -join ", "}}, @{L = 'NTP Server(s)'; E = {$_.ntpServers -join ", "}}
                    $Cluster | Table -Name 'Network Summary'
        
                }

                Section -Style Heading3 'Controller VMs' {
                    $CVMs = Get-NTNXVM | Where-Object {$_.controllerVm -eq $true} | Sort-Object vmname | Select-Object @{L = 'CVM Name'; E = {$_.vmName}}, @{L = 'Power State'; E = {$_.powerState}}, @{L = 'Host'; E = {$_.hostName}}, 
                    @{L = 'IP Address'; E = {$_.ipAddresses[0]}}, @{L = 'CPUs'; E = {$_.numVCPUs}}, @{L = 'Memory GB'; E = {[math]::Round(($_.memoryCapacityinBytes) / 1GB, 2)}} 
                    if ($Healthcheck.Cluster.CVM) {
                        $CVMs | Where-Object {$_.'Power State' -eq 'off'} | Set-Style -Style Critical
                    }
                    $CVMs | Table -Name 'Controller VM Summary' 
                }
            }

            Section -Style Heading2 'System' {
                $AuthConfig = Get-NTNXAuthConfigDirectory
                if ($AuthConfig) {
                    Section -Style Heading3 'Authentication' {
                        $AuthConfig = $AuthConfig | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Domain'; E = {$_.domain}}, @{L = 'URL'; E = {$_.DirectoryUrl}}, @{L = 'Directory Type'; E = {$_.DirectoryType}}, 
                        @{L = 'Connection Type'; E = {$_.ConnectionType}}, @{L = 'Group Search Type'; E = {$_.GroupSearchType}}
                        $AuthConfig | Table -Name 'Authentication'
                    }
                }

                $SmtpServer = Get-NTNXSmtpServer
                if ($SmtpServer.Address -ne '') {
                    Section -Style Heading3 'SMTP Server' {
                        $SmtpServer = $SmtpServer | Select-Object @{L = 'Address'; E = {$_.address}}, @{L = 'Port'; E = {$_.port}}, @{L = 'Username'; E = {$_.username}}, @{L = 'Password'; E = {$_.password}}, 
                        @{L = 'Secure Mode'; E = {$_.secureMode}}, @{L = 'From Email Address'; E = {$_.fromEmailAddress}}
                        $SmtpServer | Table -Name 'SMTP Server'
                    }
                }

                $AlertConfig = Get-NTNXAlertConfiguration
                if ($AlertConfig) {
                    Section -Style Heading3 'Alert Email Configuration' {
                        $AlertConfig = $AlertConfig | Select-Object @{L = 'Email Every Alert'; E = {$_.enable}}, @{L = 'Email Daily Alert'; E = {$_.enableEmailDigest}}, 
                        @{L = 'Nutanix Support Email'; E = {$_.defaultNutanixEmail}}, @{L = 'Additional Email Recipients'; E = {$_.emailContactlist -join ", "}} 
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
                    $License = Get-NTNXLicense | Select-Object @{L = 'Cluster'; E = {($NTNXCluster).name}}, @{L = 'License Type'; E = {$_.category}} 
                    $License | Table -Name 'Licensing' -ColumnWidths 50, 50
            
                    BlankLine
            
                    $LicenseAllowance = Get-NTNXLicenseAllowance | Sort-Object key | Select-Object @{L = 'Feature'; E = {$_.key}}, @{L = 'Permitted'; E = {'Yes'}}
                    $LicenseAllowance | Table -Name 'License Allowance' 
                }
            }
    
            $NTNXHost = Get-NTNXHost
            if ($NTNXHost) {
                Section -Style Heading2 'Hardware' {
                    Section -Style Heading3 'Host Hardware Specifications' {
                        $NTNXHostSpec = $NTNXHost | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Serial Number'; E = {$_.serial}}, @{L = 'Block Model'; E = {$_.blockModelName}}, @{L = 'Block Serial'; E = {$_.blockSerial}}, 
                        @{L = 'BMC Version'; E = {$_.bmcVersion}}, @{L = 'BIOS Version'; E = {$_.biosVersion}}, @{L = 'CPU Model'; E = {$_.cpuModel}}, @{L = 'CPUs'; E = {$_.numCpuSockets}}, @{L = 'Cores'; E = {$_.numCpuCores}}, 
                        @{L = 'Memory GB'; E = {[math]::Round(($_.memoryCapacityinBytes) / 1GB, 0)}}, @{L = 'Hypervisor'; E = {$_.hypervisorFullname}} 
                        $NTNXHostSpec | Table -Name 'Host Specifications' 
                    }

                    Section -Style Heading3 'Host Network Specifications' {
                        $NTNXHostNetSpec = $NTNXHost | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Hypervisor IP Address'; E = {$_.hypervisorAddress}}, @{L = 'CVM IP Address'; E = {$_.serviceVMExternalIP}}, 
                        @{L = 'IPMI IP Address'; E = {$_.ipmiAddress}}
                        $NTNXHostNetSpec | Table -Name 'Host Network Specifications' -ColumnWidths 25, 25, 25, 25
                    }

                    Section -Style Heading3 'Disk Specifications' {
                        $NTNXDiskSpec = Get-NTNXDisk | Sort-Object hostname, location, id | Select-Object @{L = 'Disk ID'; E = {$_.id}}, @{L = 'Hypervisor IP'; E = {$_.hostName}}, @{L = 'Location'; E = {$_.location}}, @{L = 'Tier'; E = {$_.storageTierName}}, 
                        @{L = 'Disk Size TB'; E = {[math]::Round(($_.disksize) / 1TB, 0)}}, @{L = 'Online'; E = {$_.online}}, @{L = 'Status'; E = {($_.diskStatus).ToLower()}}
                        if ($Healthcheck.Hardware.Disks) {
                            $NTNXDiskSpec | Where-Object {$_.'Online' -ne $true} | Set-Style -Style Critical
                            $NTNXDiskSpec | Where-Object {$_.'Status' -ne 'normal'} | Set-Style -Style Critical
                        }
                        $NTNXDiskSpec | Table -Name 'Disk Specifications' 
                    }
                }
            }
    
            Section -Style Heading2 'Storage' {
                $NTNXContainer = Get-NTNXContainer
                if ($NTNXContainer) {
                    Section -Style Heading3 'Storage Containers' {
                        $NTNXContainer = $NTNXContainer | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'RF'; E = {$_.replicationFactor}}, @{L = 'Compression'; E = {$_.compressionEnabled}}, @{L = 'Cache Deduplication'; E = {$_.fingerPrintonWrite}}, 
                        @{L = 'Capacity Deduplication'; E = {($_.onDiskDedup).ToLower()}}, @{L = 'Erasure Coding'; E = {$_.erasureCode}}, @{L = 'Max Capacity TB'; E = {[math]::Round(($_.maxCapacity) / 1TB, 2)}}, 
                        @{L = 'Advertised Capacity TB'; E = {[math]::Round(($_.advertisedCapacity) / 1TB, 2)}}
                        $NTNXContainer | Table -Name 'Storage Containers'
                    }

                    $NTNXStoragePool = Get-NTNXStoragePool
                    if ($NTNXStoragePool) {
                        Section -Style Heading3 'Storage Pools' {
                            $NTNXStoragePool = Get-NTNXStoragePool | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Disks'; E = {($_.disks).count}}, @{L = 'Maximum Capacity TB'; E = {[math]::Round(($_.capacity) / 1TB, 2)}}, 
                            @{L = 'Reserved Capacity TB'; E = {[math]::Round(($_.reservedCapacity) / 1TB, 2)}}
                            $NTNXStoragePool | Table -Name 'Storage Pools' 
                        } 
                    }
        
                    if ($HypervisorType -eq 'kVMware') {
                        $NTNXNfsDatastore = Get-NTNXNfsDatastore
                        if ($NTNXNfsDatastore) {
                            Section -Style Heading3 'NFS Datastores' {
                                $NTNXNfsDatastore = Get-NTNXNfsDatastore | Sort-Object hostIpAddress, name | Select-Object @{L = 'Datastore Name'; E = {$_.datastoreName}}, @{L = 'Host IP'; E = {$_.hostIpAddress}}, @{L = 'Container'; E = {$_.containerName}}, 
                                @{L = 'Total Capacity TB'; E = {[math]::Round(($_.capacity) / 1TB, 2)}}, @{L = 'Free Capacity TB'; E = {[math]::Round(($_.freeSpace) / 1TB, 2)}}
                                $NTNXNfsDatastore | Table -Name 'NFS Datastores' 
                            }
                        }
                    }
                }
            }

            if ($HypervisorType -eq 'kKvm') {
                $NTNXVMNetwork = Get-NTNXNetwork
                if ($NTNXVMNetwork) {
                    Section -Style Heading2 'VM Networks' {
                        $NTNXVMNetwork = $NTNXVMNetwork | Sort-Object vlanid | Select-Object @{L = 'VM Network'; E = {$_.name}}, @{L = 'VLAN ID'; E = {$_.vlanid}}
                        $NTNXVMNetwork | Table -Name 'VM Networks' -ColumnWidths 50, 50
                    }
                }
            }
    
            $NTNXVM = Get-NTNXVM | Where-Object {$_.controllerVm -eq $false}
            if ($NTNXVM) {
                Section -Style Heading2 'VM' {
                    Section -Style Heading3 'Virtual Machines' {
                        $NTNXVM = $NTNXVM | Sort-Object vmname | Select-Object @{L = 'VM Name'; E = {$_.vmName}}, @{L = 'Power State'; E = {$_.powerState}}, @{L = 'Operating System'; E = {$_.guestOperatingSystem}}, 
                        @{L = 'IP Addresses'; E = {$_.ipAddresses -join ", "}}, @{L = 'CPUs'; E = {$_.numVCPUs}}, @{L = 'NICs'; E = {$_.numNetworkAdapters}}, @{L = 'Disk Capacity GB'; E = {[math]::Round(($_.diskCapacityinBytes) / 1GB, 2)}}, 
                        @{L = 'Host'; E = {$_.hostName}}
                        $NTNXVM | Table -Name 'Virtual Machines'
                    }
                }
            }

            $NTNXProtectionDomain = Get-NTNXProtectionDomain
            if ($NTNXProtectionDomain -ne $null) {
                Section -Style Heading2 'Data Protection' {
                    Section -Style Heading3 'Protection Domains' {
                        $NTNXProtectionDomain = $NTNXProtectionDomain | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Active'; E = {$_.active}}, @{L = 'Remote Site(s)'; E = {$_.remoteSiteNames}}, @{L = 'Pending Replications'; E = {$_.pendingReplicationCount}}, 
                        @{L = 'Ongoing Replications'; E = {$_.ongoingReplicationCount}}, @{L = 'Schedule Suspended'; E = {$_.schedulesSuspended}}, @{L = 'Written Bytes'; E = {$_.totalUserWrittenBytes}} 
                        $NTNXProtectionDomain | Table -Name 'Protection Domains' 
        
                    }

                    $NTNXProtectionDomainReplication = Get-NTNXProtectionDomainReplication
                    if ($NTNXProtectionDomainReplication -ne $null) {
                        Section -Style Heading3 'Protection Domain Replication' {
                            $NTNXProtectionDomainReplication = $NTNXProtectionDomainReplication | Sort-Object id | Select-Object @{L = 'Name'; E = {$_.protectionDomainName}}, @{L = 'Remote Sites'; E = {$_.remoteSiteName}}, @{L = 'Snapshot ID'; E = {$_.snapshotId}}, 
                            @{L = 'Data Completed TB'; E = {[math]::Round(($_.completedBytes) / 1TB, 2)}}, @{L = '% Complete'; E = {$_.completedPercentage}}, @{L = 'Minutes to Complete'; E = {[math]::Round(($_.replicationTimetoCompleteSecs) / 60, 2)}}
                            $NTNXProtectionDomainReplication | Table -Name 'Protection Domain Replication' 
                        }
                    }                    

                    $NTNXProtectionDomainSnapshot = Get-NTNXProtectionDomainSnapshot
                    if ($NTNXProtectionDomainSnapshot -ne $null) {
                        Section -Style Heading3 'Protection Domain Snapshots' {
                            $NTNXProtectionDomainSnapshot = $NTNXProtectionDomainSnapshot | Sort-Object protectionDomainName | Select-Object @{L = 'Protection Domain'; E = {$_.protectionDomainName}}, @{L = 'State'; E = {$_.state}}, @{L = 'Snapshot ID'; E = {$_.snapshotId}}, 
                            @{L = 'Consistency Groups'; E = {$_.consistencyGroups}}, @{L = 'Remote Site(s)'; E = {$_.remoteSiteNames}}, @{L = 'Size in Bytes'; E = {$_.sizeInBytes}}
                            $NTNXProtectionDomainSnapshot | Table -Name 'Protection Domain Snapshots' 
                        }
                    }                    

                    $NTNXUnprotectedVM = Get-NTNXUnprotectedVM
                    if ($NTNXUnprotectedVM -ne $null) {
                        Section -Style Heading3 'Unprotected VMs' {
                            $NTNXUnprotectedVM = $NTNXUnprotectedVM | Sort-Object vmName | Select-Object @{L = 'VM Name'; E = {$_.vmName}}, @{L = 'Power State'; E = {$_.powerState}}, @{L = 'Operating System'; E = {$_.guestOperatingSystem}}, @{L = 'CPUs'; E = {$_.numVCPUs}}, 
                            @{L = 'NICs'; E = {$_.numNetworkAdapters}}, @{L = 'Disk Capacity GB'; E = {[math]::Round(($_.diskCapacityinBytes) / 1GB, 2)}}, @{L = 'Host'; E = {$_.hostName}}
                            $NTNXUnprotectedVM | Table -Name 'Unprotected VMs' 
                        }
                    }
                }
            }

            $NTNXRemoteSite = Get-NTNXRemoteSite
            if ($NTNXRemoteSite) {
                Section -Style Heading2 'Remote Sites' {
                    $NTNXRemoteSite = $NTNXRemoteSite | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Capabilities'; E = {$_.capabilities -join '|'}}, @{L = 'Remote IP'; E = {($_.RemoteIpPorts).keys}}, @{L = 'Metro Ready'; E = {$_.metroReady}}, @{L = 'Use SSH Tunnel'; E = {$_.sshEnabled}}, 
                    @{L = 'Compress On Wire'; E = {$_.compressionEnabled}}, @{L = 'Use Proxy'; E = {$_.proxyEnabled}}, @{L = 'Bandwidth Throttling'; E = {$_.bandwidthPolicyEnabled}}
                    $NTNXRemoteSite | Table -Name 'Remote Sites' -List -ColumnWidths 50, 50
                }
            }
        }
    }
    
    # Disconnect Nutanix Cluster
    $Null = Disconnect-NutanixCluster $Cluster
}
#endregion Script Body