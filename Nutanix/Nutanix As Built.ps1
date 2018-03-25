#requires -Modules @{ModuleName="PScribo";ModuleVersion="0.7.22.112"}
#requires -PSSnapin NutanixCmdletsPSSnapin

<#
.SYNOPSIS  
    PowerShell script to document the configuration of Nutanix hyper-converged infrastucture in Word/HTML/XML/Text formats
.DESCRIPTION
    Documents the configuration of Nutanix hyper-converged infrastucture in Word/HTML/XML/Text formats using PScribo.
.NOTES
    Version:        0.1
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
    Credits:        @iainbrighton - PScribo module
.LINK
    https://github.com/tpcarman/Documentation-Scripts
    https://github.com/iainbrighton/PScribo	
.PARAMETER ReportName
    Specifies the report name.
    This parameter is optional.
    By default, the report name is 'Nutanix As Built Documentation'.   
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
    Highlights certain issues within the Nutanix environment.
    This parameter is optional and by default is set to $False.
.PARAMETER Cluster
    Specifies the IP/FQDN of the Nutanix Cluster to connect.
    Alias 'IP'
    This parameter is mandatory.
.PARAMETER Username
    Specifies the username of the Nutanix Cluster to connect.
    Alias 'User'
    This parameter is mandatory.
.PARAMETER Password
    Specifies the password of the Nutanix Cluster to connect.
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
    .\Nutanix As Built.ps1 -NTNXCluster 192.168.1.100 -Format HTML,Word
    Creates 'Nutanix As Built Documentation' report in HTML & Word formats.
.EXAMPLE
    .\Nutanix As Built.ps1 -NTNXCluster 192.168.1.100 -Format Text -AddDateTime
    Creates Nutanix As Built report in Text format and appends the current date and time to the filename Nutanix As Built Documentation - 09-03-2018_10.45.30.txt
.EXAMPLE
    .\Nutanix As Built.ps1 -NTNXCluster 192.168.1.100 -Author 'Tim Carman' -CompanyName 'ACME'
    Creates Nutanix As Built report report in default format (Word) and includes Author and Company names.
    Company Name is appended to the filename ACME - Nutanix As Built Documentation.docx
.EXAMPLE
    .\Nutanix As Built.ps1 -NTNXCluster 192.168.1.100 -Style 'ACME'
    Creates Nutanix As Built report report in default format (Word) with customised style
#>

#region Script Parameters
[CmdletBinding(SupportsShouldProcess = $False)]
Param(

    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Please provide the IP/FQDN of the Nutanix Cluster')]
    [ValidateNotNullOrEmpty()]
    [Alias('IP')]
    [String]$Cluster = '',

    [Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Specify the username for the Nutanix Cluster')]
    [ValidateNotNullOrEmpty()]
    [Alias('User')]
    [String]$Username = '',

    [Parameter(Position = 2, Mandatory = $True, HelpMessage = 'Specify the password for the Nutanix Cluster')]
    [ValidateNotNullOrEmpty()]
    [String]$Password = '',

    [Parameter(Position = 3, Mandatory = $False, HelpMessage = 'Specify the document output format')]
    [ValidateNotNullOrEmpty()]
    [Alias('Output')]
    [ValidateSet('Word', 'Html', 'Text', 'Xml')]
    [Array]$Format = 'WORD',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report name')]
    [ValidateNotNullOrEmpty()]
    [String]$ReportName = 'Nutanix As Built Documentation',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the document report style')]
    [ValidateNotNullOrEmpty()] 
    [String]$Style = 'Default',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify whether to append a date/time string to the report filename')]
    [Switch]$AddDateTime = $False,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the path to save the report')]
    [ValidateNotNullOrEmpty()]
    [Alias('Folder')]
    [String]$Path = (Get-Location).Path,

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
    $Filename = "$CompanyName - $ReportName - " + (Get-Date -Format 'yyyy-MM-dd_HH.mm.ss')
}
elseif ($AddDateTime -and !$CompanyName) {
    $Filename = "$ReportName - " + (Get-Date -Format 'yyyy-MM-dd_HH.mm.ss')
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
    DocumentOption -EnableSectionNumbering -PageSize A4 -DefaultFont 'Arial' -MarginLeftAndRight 71 -MarginTopAndBottom 71
    
    # Styles
    #region Default Document Style
    if ($Style -eq 'Default') {
        Style -Name 'Title' -Size 24 -Color '024DAF' -Font 'Arial' -Align Center
        Style -Name 'Title 2' -Size 18 -Color 'B0D235' -Font 'Arial' -Align Center
        Style -Name 'Title 3' -Size 12 -Color 'B0D235' -Font 'Arial' -Align Left
        Style -Name 'Heading 1' -Size 16 -Color '024DAF' -Font 'Arial'
        Style -Name 'Heading 2' -Size 14 -Color '024DAF' -Font 'Arial'
        Style -Name 'Heading 3' -Size 12 -Color '024DAF' -Font 'Arial'
        Style -Name 'Heading 4' -Size 11 -Color '024DAF' -Font 'Arial'
        Style -Name 'Heading 5' -Size 10 -Color '024DAF' -Font 'Arial' -Italic
        Style -Name 'H1 Exclude TOC' -Size 16 -Color '024DAF' -Font 'Arial'
        Style -Name 'Normal' -Size 10 -Font 'Arial' -Default
        Style -Name 'TOC' -Size 16 -Color '024DAF' -Font 'Arial'
        Style -Name 'TableDefaultHeading' -Size 10 -Color 'FFFFFF' -BackgroundColor '4D4D4F' -Font 'Arial'
        Style -Name 'TableDefaultRow' -Size 10 -Font 'Arial'
        Style -Name 'TableDefaultAltRow' -Size 10 -BackgroundColor 'DDDDDD' -Font 'Arial'
        Style -Name 'Critical' -Size 10 -Font 'Arial' -BackgroundColor 'EA5054'
        Style -Name 'Warning' -Size 10 -Font 'Arial' -BackgroundColor 'FFFF00'
        Style -Name 'Info' -Size 10 -Font 'Arial' -BackgroundColor '9CC2E5'
        Style -Name 'OK' -Size 10 -Font 'Arial' -BackgroundColor '92D050'

        TableStyle -Id 'TableDefault' -HeaderStyle 'TableDefaultHeading' -RowStyle 'TableDefaultRow' -AlternateRowStyle 'TableDefaultAltRow' -BorderColor '4D4D4F' -Align Left -BorderWidth 0.5 -Default
    
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

    #region Script Body
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Password = ConvertTo-SecureString $Password -AsPlainText -Force
    Connect-NutanixCluster $Cluster -UserName $UserName -Password $Password -AcceptInvalidSSLCerts -ForcedConnection
    
    $NTNXCluster = Get-NTNXCluster
    if ($NTNXCluster) {
        Section -Style Heading1 'Cluster Summary' {
            Section -Style Heading2 'Hardware' {
                $ClusterSummary = $NTNXCluster | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Storage Type'; E = {$_.storageType}}, @{L = 'Number of Nodes'; E = {$_.numNodes}}, @{L = 'Block Serial(s)'; E = {$_.blockSerials -join ", "}}, `
                @{L = 'Version'; E = {$_.version}}, @{L = 'NCC Version'; E = {$_.nccVersion}}, @{L = 'Timezone'; E = {$_.timezone}}
                $ClusterSummary | Table -Name 'Cluster Summary' 
            }

            Section -Style Heading2 'Network' {
                $Cluster = $NTNXCluster | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Cluster Virtual IP Address'; E = {$_.clusterExternalIPAddress}}, @{L = 'iSCSI Data Services IP Address'; E = {$_.clusterExternalDataServicesIPAddress}}, `
                @{L = 'Subnet'; E = {$_.externalSubnet}}, @{L = 'DNS Server(s)'; E = {$_.nameServers -join ", "}}, @{L = 'NTP Server(s)'; E = {$_.ntpServers -join ", "}}
                $Cluster | Table -Name 'Network Summary'
        
            }

            Section -Style Heading2 'Controller VMs' {
                $CVMs = Get-NTNXVM | Where-Object {$_.controllerVm -eq $true} | Sort-Object vmname | Select-Object @{L = 'CVM Name'; E = {$_.vmName}}, @{L = 'Power State'; E = {$_.powerState}}, @{L = 'Host'; E = {$_.hostName}}, `
                @{L = 'IP Address'; E = {$_.ipAddresses[0]}}, @{L = 'CPUs'; E = {$_.numVCPUs}}, @{L = 'Memory GB'; E = {[math]::Round(($_.memoryCapacityinBytes) / 1GB, 2)}} 
                $CVMs | Table -Name 'Controller VM Summary' 
            }
        }

        Section -Style Heading1 'System' {
            Section -Style Heading2 'Authentication' {Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Domain'; E = {$_.domain}}, @{L = 'URL'; E = {$_.DirectoryUrl}}, @{L = 'Directory Type'; E = {$_.DirectoryType}}, `
                @{L = 'Connection Type'; E = {$_.ConnectionType}}, @{L = 'Group Search Type'; E = {$_.GroupSearchType}}
                $AuthConfig = Get-NTNXAuthConfigDirectory 
                $AuthConfig | Table -Name 'Authentication'
            
            }

            Section -Style Heading2 'SMTP Server' {
                $SmtpServer = Get-NTNXSmtpServer | Select-Object @{L = 'Address'; E = {$_.address}}, @{L = 'Port'; E = {$_.port}}, @{L = 'Username'; E = {$_.username}}, @{L = 'Password'; E = {$_.password}}, `
                @{L = 'Secure Mode'; E = {$_.secureMode}}, @{L = 'From Email Address'; E = {$_.fromEmailAddress}}
                $SmtpServer | Table -Name 'SMTP Server'
            }

            Section -Style Heading2 'Alert Email Configuration' {
                $AlertConfig = Get-NTNXAlertConfiguration | Select-Object @{L = 'Email Every Alert'; E = {$_.enable}}, @{L = 'Email Daily Alert'; E = {$_.enableEmailDigest}}, `
                @{L = 'Nutanix Support Email'; E = {$_.defaultNutanixEmail}}, @{L = 'Additional Email Recipients'; E = {$_.emailContactlist -join ", "}} 
                $AlertConfig | Table -Name 'Alert Email Configuration'
            }

            # ToDo: SNMP Configuration
            <#
            Section -Style Heading2 'SNMP' {
            }
            #>

            # ToDo: Syslog Configuration
            <#
            Section -Style Heading2 'Syslog' {
            }
            #>

            Section -Style Heading2 'Licensing' {
                $License = Get-NTNXLicense | Select-Object @{L = 'Cluster'; E = {($NTNXCluster).name}}, @{L = 'License Type'; E = {$_.category}} 
                $License | Table -Name 'Licensing'
            
                BlankLine
            
                $LicenseAllowance = Get-NTNXLicenseAllowance | Sort-Object key | Select-Object @{L = 'Feature'; E = {$_.key}}, @{L = 'Permitted'; E = {'Yes'}}
                $LicenseAllowance | Table -Name 'License Allowance' 
            }
        }
    }
    
    $NTNXHost = Get-NTNXHost
    if ($NTNXHost) {
        Section -Style Heading1 'Hardware' {
            Section -Style Heading2 'Host Hardware Specifications' {
                $NTNXHostSpec = $NTNXHost | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Serial Number'; E = {$_.serial}}, @{L = 'Block Model'; E = {$_.blockModelName}}, @{L = 'Block Serial'; E = {$_.blockSerial}}, `
                @{L = 'BMC Version'; E = {$_.bmcVersion}}, @{L = 'BIOS Version'; E = {$_.biosVersion}}, @{L = 'CPU Model'; E = {$_.cpuModel}}, @{L = 'CPUs'; E = {$_.numCpuSockets}}, @{L = 'Cores'; E = {$_.numCpuCores}}, `
                @{L = 'Memory GB'; E = {[math]::Round(($_.memoryCapacityinBytes) / 1GB, 0)}}, @{L = 'Hypervisor'; E = {$_.hypervisorFullname}} 
                $NTNXHostSpec | Table -Name 'Host Specifications' 
            }

            Section -Style Heading2 'Host Network Specifications' {
                $NTNXHostNetSpec = $NTNXHost | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Hypervisor IP Address'; E = {$_.hypervisorAddress}}, @{L = 'CVM IP Address'; E = {$_.serviceVMExternalIP}}, `
                @{L = 'IPMI IP Address'; E = {$_.ipmiAddress}}
                $NTNXHostNetSpec | Table -Name 'Host Network Specifications' 
            }

            Section -Style Heading2 'Disk Specifications' {
                $NTNXDiskSpec = Get-NTNXDisk | Sort-Object hostname, location, id | Select-Object @{L = 'Disk ID'; E = {$_.id}}, @{L = 'Hypervisor IP'; E = {$_.hostName}}, @{L = 'Location'; E = {$_.location}}, @{L = 'Tier'; E = {$_.storageTierName}}, `
                @{L = 'Disk Size TB'; E = {[math]::Round(($_.disksize) / 1TB, 0)}}, @{L = 'Online'; E = {$_.online}}, @{L = 'Status'; E = {($_.diskStatus).ToLower()}}
                $NTNXDiskSpec | Table -Name 'Disk Specifications' 
            }
        }
    }
    
    
    Section -Style Heading1 'Storage' {
        $NTNXContainer = Get-NTNXContainer
        if ($NTNXContainer) {
            Section -Style Heading2 'Storage Containers' {
                $NTNXContainer = $NTNXContainer | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'RF'; E = {$_.replicationFactor}}, @{L = 'Compression'; E = {$_.compressionEnabled}}, @{L = 'Cache Deduplication'; E = {$_.fingerPrintonWrite}}, `
                @{L = 'Capacity Deduplication'; E = {($_.onDiskDedup).ToLower()}}, @{L = 'Erasure Coding'; E = {$_.erasureCode}}, @{L = 'Max Capacity TB'; E = {[math]::Round(($_.maxCapacity) / 1TB, 2)}}, `
                @{L = 'Advertised Capacity TB'; E = {[math]::Round(($_.advertisedCapacity) / 1TB, 2)}}
                $NTNXContainer | Table -Name 'Storage Containers'
            }

            $NTNXStoragePool = Get-NTNXStoragePool
            if ($NTNXStoragePool) {
                Section -Style Heading2 'Storage Pools' {
                    $NTNXStoragePool = Get-NTNXStoragePool | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Disks'; E = {($_.disks).count}}, @{L = 'Maximum Capacity TB'; E = {[math]::Round(($_.capacity) / 1TB, 2)}}, `
                    @{L = 'Reserved Capacity TB'; E = {[math]::Round(($_.reservedCapacity) / 1TB, 2)}}
                    $NTNXStoragePool | Table -Name 'Storage Pools' 
                } 
            }
        
            $NTNXNfsDatastore = Get-NTNXNfsDatastore
            if ($NTNXNfsDatastore) {
                Section -Style Heading2 'NFS Datastores' {
                    $NTNXNfsDatastore = Get-NTNXNfsDatastore | Sort-Object hostIpAddress, name | Select-Object @{L = 'Datastore Name'; E = {$_.datastoreName}}, @{L = 'Host IP'; E = {$_.hostIpAddress}}, @{L = 'Container'; E = {$_.containerName}}, `
                    @{L = 'Total Capacity TB'; E = {[math]::Round(($_.capacity) / 1TB, 2)}}, @{L = 'Free Capacity TB'; E = {[math]::Round(($_.freeSpace) / 1TB, 2)}}
                    $NTNXNfsDatastore | Table -Name 'NFS Datastores' 
                }
            }
        }
    }
    
    $NTNXVM = Get-NTNXVM | Where-Object {$_.controllerVm -eq $false}
    if ($NTNXVM) {
        Section -Style Heading1 'VM' {
            Section -Style Heading2 'Virtual Machines' {
                $NTNXVM = $NTNXVM | Sort-Object vmname | Select-Object @{L = 'VM Name'; E = {$_.vmName}}, @{L = 'Power State'; E = {$_.powerState}}, @{L = 'Operating System'; E = {$_.guestOperatingSystem}}, `
                @{L = 'IP Addresses'; E = {$_.ipAddresses -join ", "}}, @{L = 'CPUs'; E = {$_.numVCPUs}}, @{L = 'NICs'; E = {$_.numNetworkAdapters}}, @{L = 'Disk Capacity GB'; E = {[math]::Round(($_.diskCapacityinBytes) / 1GB, 2)}}, `
                @{L = 'Host'; E = {$_.hostName}}
                $NTNXVM | Table -Name 'Virtual Machines' }
        }
    }

    $NTNXProtectionDomain = Get-NTNXProtectionDomain
    if ($NTNXProtectionDomain) {
        Section -Style Heading1 'Data Protection' {
            Section -Style Heading2 'Protection Domains' {
                $NTNXProtectionDomain = $NTNXProtectionDomain | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Active'; E = {$_.active}}, @{L = 'Remote Site(s)'; E = {$_.remoteSiteNames}}, @{L = 'Pending Replications'; E = {$_.pendingReplicationCount}}, `
                @{L = 'Ongoing Replications'; E = {$_.ongoingReplicationCount}}, @{L = 'Schedule Suspended'; E = {$_.schedulesSuspended}}, @{L = 'Written Bytes'; E = {$_.totalUserWrittenBytes}} 
                $NTNXProtectionDomain | Table -Name 'Protection Domains' 
        
            }

            Section -Style Heading2 'Protection Domain Replication' {
                $NTNXProtectionDomainReplication = Get-NTNXProtectionDomainReplication | Sort-Object id | Select-Object @{L = 'Name'; E = {$_.protectionDomainName}}, @{L = 'Remote Sites'; E = {$_.remoteSiteName}}, @{L = 'Snapshot ID'; E = {$_.snapshotId}}, `
                @{L = 'Data Completed TB'; E = {[math]::Round(($_.completedBytes) / 1TB, 2)}}, @{L = '% Complete'; E = {$_.completedPercentage}}, @{L = 'Minutes to Complete'; E = {[math]::Round(($_.replicationTimetoCompleteSecs) / 60, 2)}}
                $NTNXProtectionDomainReplication | Table -Name 'Protection Domain Replication' 
            }

            Section -Style Heading2 'Protection Domain Snapshots' {
                $NTNXProtectionDomainSnapshot = Get-NTNXProtectionDomainSnapshot | Sort-Object protectionDomainName | Select-Object @{L = 'Protection Domain'; E = {$_.protectionDomainName}}, @{L = 'State'; E = {$_.state}}, @{L = 'Snapshot ID'; E = {$_.snapshotId}}, `
                @{L = 'Consistency Groups'; E = {$_.consistencyGroups}}, @{L = 'Remote Site(s)'; E = {$_.remoteSiteNames}}, @{L = 'Size in Bytes'; E = {$_.sizeInBytes}}
                $NTNXProtectionDomainSnapshot | Table -Name 'Protection Domain Snapshots' 
            }

            Section -Style Heading2 'Unprotected VMs' {
                $NTNXUnprotectedVM = Get-NTNXUnprotectedVM | Sort-Object vmName | Select-Object @{L = 'VM Name'; E = {$_.vmName}}, @{L = 'Power State'; E = {$_.powerState}}, @{L = 'Operating System'; E = {$_.guestOperatingSystem}}, @{L = 'CPUs'; E = {$_.numVCPUs}}, `
                @{L = 'NICs'; E = {$_.numNetworkAdapters}}, @{L = 'Disk Capacity GB'; E = {[math]::Round(($_.diskCapacityinBytes) / 1GB, 2)}}, @{L = 'Host'; E = {$_.hostName}}
                $NTNXUnprotectedVM | Table -Name 'Unprotected VMs' 
            }
        }
    }

    $NTNXRemoteSite = Get-NTNXRemoteSite
    if ($NTNXRemoteSite) {
        Section -Style Heading1 'Remote Sites' {
            $NTNXRemoteSite = $NTNXRemoteSite | Sort-Object name | Select-Object @{L = 'Name'; E = {$_.name}}, @{L = 'Capabilities'; E = {$_.capabilities}}, @{L = 'Remote IP'; E = {($_.RemoteIpPorts).keys}}, @{L = 'Metro Ready'; E = {$_.metroReady}}, @{L = 'Use SSH Tunnel'; E = {$_.sshEnabled}}, `
            @{L = 'Compress On Wire'; E = {$_.compressionEnabled}}, @{L = 'Use Proxy'; E = {$_.proxyEnabled}}, @{L = 'Bandwidth Throttling'; E = {$_.bandwidthPolicyEnabled}}
            $NTNXRemoteSite | Table -Name 'Remote Sites' -List -ColumnWidths 50, 50
        }
    }
        
    #endregion Script Body

}
# Create and export document to specified format. Open document.
$Document | Export-Document -Path $Path -Format $Format

# Disconnect Nutanix Cluster
Disconnect-NutanixCluster $Cluster
