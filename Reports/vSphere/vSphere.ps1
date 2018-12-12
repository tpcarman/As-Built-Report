#requires -Modules @{ModuleName="PScribo";ModuleVersion="0.7.24"},VMware.VimAutomation.Core

<#
.SYNOPSIS  
    PowerShell script to document the configuration of VMware vSphere infrastucture in Word/HTML/XML/Text formats
.DESCRIPTION
    Documents the configuration of VMware vSphere infrastucture in Word/HTML/XML/Text formats using PScribo.
.NOTES
    Version:        0.3.0
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
    Credits:        Iain Brighton (@iainbrighton) - PScribo module
                    Jake Rutski (@jrutski) - VMware vSphere Documentation Script Concept
.LINK
    https://github.com/tpcarman/As-Built-Report
    https://github.com/iainbrighton/PScribo
#>

#region Configuration Settings
#---------------------------------------------------------------------------------------------#
#                                    CONFIG SETTINGS                                          #
#---------------------------------------------------------------------------------------------#
# Clear variables
$vCenter = @()
$VIServer = @()

# If custom style not set, use VMware style
if (!$StyleName) {
    & "$PSScriptRoot\..\..\Styles\VMware.ps1"
}

#endregion Configuration Settings

#region Script Functions
#---------------------------------------------------------------------------------------------#
#                                    SCRIPT FUNCTIONS                                         #
#---------------------------------------------------------------------------------------------#

function Get-vCenterStats {
    $vCenterStats = @()
    $ServiceInstance = Get-View ServiceInstance -Server $vCenter
    $VCenterStatistics = Get-View ($ServiceInstance).Content.PerfManager
    [int] $CurrentServiceIndex = 2;
    Foreach ($xStatLevel in $VCenterStatistics.HistoricalInterval) {
        Switch ($xStatLevel.SamplingPeriod) {
            300 {$xInterval = '5 Minutes'}
            1800 {$xInterval = '30 Minutes'}
            7200 {$xInterval = '2 Hours'}
            86400 {$xInterval = '1 Day'}
        }
        ## Add the required key/values to the hashtable
        $vCenterStatsHash = @{
            IntervalDuration = $xInterval;
            IntervalEnabled = $xStatLevel.Enabled;
            SaveDuration = $xStatLevel.Name;
            StatsLevel = $xStatLevel.Level;
        }
        ## Add the hash to the array
        $vCenterStats += $vCenterStatsHash;
        $CurrentServiceIndex++
    }
    Write-Output $vCenterStats
}

function Get-License {
    <#
    .SYNOPSIS
    Function to retrieve vSphere product licensing information.
    .DESCRIPTION
    Function to retrieve vSphere product licensing information.
    .NOTES
    Version:        0.1.0
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
    .PARAMETER VMHost
    A vSphere ESXi Host object
    .PARAMETER vCenter
    A vSphere vCenter Server object
    .PARAMETER Licenses
    All vSphere product licenses
    .INPUTS
    System.Management.Automation.PSObject.
    .OUTPUTS
    System.Management.Automation.PSObject.
    .EXAMPLE
    PS> Get-License -VMHost ESXi01
    .EXAMPLE
    PS> Get-License -vCenter VCSA
    .EXAMPLE
    PS> Get-License -Licenses
    #>
    [CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$vCenter, [PSObject]$VMHost,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Switch]$Licenses
    ) 

    $LicenseObject = @()
    $ServiceInstance = Get-View ServiceInstance -Server $vCenter
    $LicenseManager = Get-View $ServiceInstance.Content.LicenseManager
    $LicenseManagerAssign = Get-View $LicenseManager.LicenseAssignmentManager 
    if ($VMHost) {
        $VMHostId = $VMHost.Extensiondata.Config.Host.Value
        $VMHostAssignedLicense = $LicenseManagerAssign.QueryAssignedLicenses($VMHostId)    
        $VMHostLicense = $VMHostAssignedLicense | Where-Object {$_.EntityId -eq $VMHostId}
        if ($Options.ShowLicenses) {
            $VMHostLicenseKey = $VMHostLicense.AssignedLicense.LicenseKey
        } else {
            $VMHostLicenseKey = "*****-*****-*****" + $VMHostLicense.AssignedLicense.LicenseKey.Substring(17)
        }
        $LicenseObject = [PSCustomObject]@{                               
            Product = $VMHostLicense.AssignedLicense.Name 
            LicenseKey = $VMHostLicenseKey                   
        }
    }
    if ($vCenter) {
        $vCenterAssignedLicense = $LicenseManagerAssign.QueryAssignedLicenses($vCenter.InstanceUuid.AssignedLicense)
        $vCenterLicense = $vCenterAssignedLicense | Where-Object {$_.EntityId -eq $vCenter.InstanceUuid}
        if ($vCenterLicense -and $Options.ShowLicenses) { 
            $vCenterLicenseKey = $vCenterLicense.AssignedLicense.LicenseKey
        } elseif ($vCenterLicense) { 
            $vCenterLicenseKey = "*****-*****-*****" + $vCenterLicense.AssignedLicense.LicenseKey.Substring(17)
        } else {
            $vCenterLicenseKey = 'No License Key'
        }
        $LicenseObject = [PSCustomObject] @{                               
            Product = Switch ($vCenterLicense.AssignedLicense.Name) {
                $null {'Evaluation Mode'}
                default {$vCenterLicense.AssignedLicense.Name}
            }
            LicenseKey = $vCenterLicenseKey                    
        }
    }
    if ($Licenses) {
        foreach ($License in $LicenseManager.Licenses) {
            if ($Options.ShowLicenses) {
                $LicenseKey = $License.LicenseKey
            } else {
                $LicenseKey = "*****-*****-*****" + $License.LicenseKey.Substring(17)
            }
            $Object = [PSCustomObject] @{                               
                'Product' = $License.Name
                'LicenseKey' = $LicenseKey
                'Total' = $License.Total
                'Used' = $License.Used                     
            }
            $LicenseObject += $Object
        }
    }
    Write-Output $LicenseObject
}

function Get-VMHostNetworkAdapterCDP {
    <#
    .SYNOPSIS
    Function to retrieve the Network Adapter CDP info of a vSphere host.
    .DESCRIPTION
    Function to retrieve the Network Adapter CDP info of a vSphere host.
    .PARAMETER VMHost
    A vSphere ESXi Host object
    .INPUTS
    System.Management.Automation.PSObject.
    .OUTPUTS
    System.Management.Automation.PSObject.
    .EXAMPLE
    PS> Get-VMHostNetworkAdapterCDP -VMHost ESXi01,ESXi02
    .EXAMPLE
    PS> Get-VMHost ESXi01,ESXi02 | Get-VMHostNetworkAdapterCDP
    #>
    [CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [PSObject[]]$VMHost   
    )    

    begin {
        $CDPObject = @()
    }

    process {
        try {
            foreach ($VMHost in $VMHosts) {
                $ConfigManagerView = Get-View $VMHost.ExtensionData.ConfigManager.NetworkSystem
                $PNICs = $ConfigManagerView.NetworkInfo.Pnic

                foreach ($PNIC in $PNICs) {
                    $PhysicalNicHintInfo = $ConfigManagerView.QueryNetworkHint($PNIC.Device)
                    if ($PhysicalNicHintInfo.ConnectedSwitchPort) {
                        $Connected = $true
                    } else {
                        $Connected = $false
                    }
                    $Object = [PSCustomObject] @{                            
                        'VMHost' = $VMHost.Name
                        'NIC' = $PNIC.Device
                        'Connected' = $Connected
                        'Switch' = $PhysicalNicHintInfo.ConnectedSwitchPort.DevId
                        'HardwarePlatform' = $PhysicalNicHintInfo.ConnectedSwitchPort.HardwarePlatform
                        'SoftwareVersion' = $PhysicalNicHintInfo.ConnectedSwitchPort.SoftwareVersion
                        'MangementAddress' = $PhysicalNicHintInfo.ConnectedSwitchPort.MgmtAddr
                        'PortId' = $PhysicalNicHintInfo.ConnectedSwitchPort.PortId
                    }
                    $CDPObject += $Object
                }
            }
        } catch [Exception] {
            throw 'Unable to retrieve CDP info'
        }
    }
    end {
        Write-Output $CDPObject
    }
}

function Get-InstallDate {
    $esxcli = Get-EsxCli -VMHost $VMHost -V2 -Server $vCenter
    $thisUUID = $esxcli.system.uuid.get.Invoke()
    $decDate = [Convert]::ToInt32($thisUUID.Split("-")[0], 16)
    $installDate = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($decDate))
    [PSCustomObject][Ordered]@{
        Name = $VMHost.Name
        InstallDate = $installDate
    }
}

function Get-Uptime {
    [CmdletBinding()][OutputType('System.Management.Automation.PSObject')]
    Param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$VMHost, [PSObject]$VM
    )
    $UptimeObject = @()
    $Date = Get-Date
    If ($VMHost) {
        $UptimeObject = Get-View -ViewType hostsystem -Property name, runtime.boottime -Filter @{'name' = "$VMHost"} | Select-Object Name, @{L = 'UptimeDays'; E = {[math]::round(((($Date) - ($_.Runtime.BootTime)).TotalDays), 1)}}, @{L = 'UptimeHours'; E = {[math]::round(((($Date) - ($_.Runtime.BootTime)).TotalHours), 1)}}, @{L = 'UptimeMinutes'; E = {[math]::round(((($Date) - ($_.Runtime.BootTime)).TotalMinutes), 1)}}
    }

    if ($VM) {
        $UptimeObject = Get-View -ViewType VirtualMachine -Property name, runtime.boottime -Filter @{'name' = "$VM"} | Select-Object Name, @{L = 'UptimeDays'; E = {[math]::round(((($Date) - ($_.Runtime.BootTime)).TotalDays), 1)}}, @{L = 'UptimeHours'; E = {[math]::round(((($Date) - ($_.Runtime.BootTime)).TotalHours), 1)}}, @{L = 'UptimeMinutes'; E = {[math]::round(((($Date) - ($_.Runtime.BootTime)).TotalMinutes), 1)}}
    }
    Write-Output $UptimeObject
}

function Get-ESXiBootDevice {
    <#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
        ===========================================================================
    .DESCRIPTION
        This function identifies how an ESXi host was booted up along with its boot
        device (if applicable). This supports both local installation to Auto Deploy as
        well as Boot from SAN.
    .PARAMETER VMHostname
        The name of an individual ESXi host managed by vCenter Server
    .EXAMPLE
        Get-ESXiBootDevice
    .EXAMPLE
        Get-ESXiBootDevice -VMHost esxi-01
    #>
    param(
        [Parameter(Mandatory = $false)][PSObject]$VMHost
    )

    $results = @()
    $esxcli = Get-EsxCli -V2 -VMHost $vmhost -Server $vCenter
    $bootDetails = $esxcli.system.boot.device.get.Invoke()

    # Check to see if ESXi booted over the network
    $networkBoot = $false
    if ($bootDetails.BootNIC) {
        $networkBoot = $true
        $bootDevice = $bootDetails.BootNIC
    } elseif ($bootDetails.StatelessBootNIC) {
        $networkBoot = $true
        $bootDevice = $bootDetails.StatelessBootNIC
    }

    # If ESXi booted over network, check to see if deployment
    # is Stateless, Stateless w/Caching or Stateful
    if ($networkBoot) {
        $option = $esxcli.system.settings.advanced.list.CreateArgs()
        $option.option = "/UserVars/ImageCachedSystem"
        try {
            $optionValue = $esxcli.system.settings.advanced.list.Invoke($option)
        } catch {
            $bootType = "stateless"
        }
        $bootType = $optionValue.StringValue
    }

    # Loop through all storage devices to identify boot device
    $devices = $esxcli.storage.core.device.list.Invoke()
    $foundBootDevice = $false
    foreach ($device in $devices) {
        if ($device.IsBootDevice -eq $true) {
            $foundBootDevice = $true

            if ($device.IsLocal -eq $true -and $networkBoot -and $bootType -ne "stateful") {
                $bootType = "stateless caching"
            } elseif ($device.IsLocal -eq $true -and $networkBoot -eq $false) {
                $bootType = "local"
            } elseif ($device.IsLocal -eq $false -and $networkBoot -eq $false) {
                $bootType = "remote"
            }

            $bootDevice = $device.Device
            $bootModel = $device.Model
            $bootVendor = $device.VEndor
            $bootSize = $device.Size
            $bootIsSAS = $device.IsSAS
            $bootIsSSD = $device.IsSSD
            $bootIsUSB = $device.IsUSB
        }
    }

    # Pure Stateless (e.g. No USB or Disk for boot)
    if ($networkBoot -and $foundBootDevice -eq $false) {
        $bootModel = "N/A"
        $bootVendor = "N/A"
        $bootSize = "N/A"
        $bootIsSAS = "N/A"
        $bootIsSSD = "N/A"
        $bootIsUSB = "N/A"
    }

    $tmp = [PSCustomObject] @{
        Host = $vmhost.Name;
        Device = $bootDevice;
        BootType = $bootType;
        Vendor = $bootVendor;
        Model = $bootModel;
        SizeMB = $bootSize;
        IsSAS = $bootIsSAS;
        IsSSD = $bootIsSSD;
        IsUSB = $bootIsUSB;
    }
    $results += $tmp
    $results
}

function Get-ScsiDeviceDetail {
    <#
        .SYNOPSIS
        Helper function to return Scsi device information for a specific host and a specific datastore.
        .PARAMETER VMHosts
        This parameter accepts a list of host objects returned from the Get-VMHost cmdlet
        .PARAMETER VMHostMoRef
        This parameter specifies, by MoRef Id, the specific host of interest from with the $VMHosts array.
        .PARAMETER DatastoreDiskName
        This parameter specifies, by disk name, the specific datastore of interest.
        .EXAMPLE
        $VMHosts = Get-VMHost
        Get-ScsiDeviceDetail -AllVMHosts $VMHosts -VMHostMoRef 'HostSystem-host-131' -DatastoreDiskName 'naa.6005076801810082480000000001d9fe'

        DisplayName      : IBM Fibre Channel Disk (naa.6005076801810082480000000001d9fe)
        Ssd              : False
        LocalDisk        : False
        CanonicalName    : naa.6005076801810082480000000001d9fe
        Vendor           : IBM
        Model            : 2145
        Multipath Policy : Round Robin
        CapacityGB       : 512
        .NOTES
        Author: Ryan Kowalewski
    #>

    [CmdLetBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $VMHosts,
        [Parameter(Mandatory = $true)]
        $VMHostMoRef,
        [Parameter(Mandatory = $true)]
        $DatastoreDiskName
    )

    $PolicyLookup = @{
        'VMW_PSP_RR' = 'Round Robin'
        'VMW_PSP_FIXED' = 'Fixed'
        'VMW_PSP_MRU' = 'Most Recently Used'
    }
    $VMHostObj = $VMHosts | Where-Object {$_.Id -eq $VMHostMoRef}
    $ScsiDisk = $VMHostObj.ExtensionData.Config.StorageDevice.ScsiLun | Where-Object {
        $_.CanonicalName -eq $DatastoreDiskName
    }
    $Multipath = $VMHostObj.ExtensionData.Config.StorageDevice.MultipathInfo.Lun | Where-Object {
        $_.Lun -eq $ScsiDisk.Key
    }
    $MultipathPolicy = $PolicyLookup."$($Multipath.Policy.Policy)"
    $CapacityGB = [math]::Round((($ScsiDisk.Capacity.BlockSize * $ScsiDisk.Capacity.Block) / 1024 / 1024 / 1024), 2)

    [PSCustomObject] @{
        'DisplayName' = $ScsiDisk.DisplayName
        'Ssd' = $ScsiDisk.Ssd
        'LocalDisk' = $ScsiDisk.LocalDisk
        'CanonicalName' = $ScsiDisk.CanonicalName
        'Vendor' = $ScsiDisk.Vendor
        'Model' = $ScsiDisk.Model
        'MultipathPolicy' = $MultipathPolicy
        'CapacityGB' = $CapacityGB
    }
}

Function Get-PciDeviceDetail {
    <#
    .SYNOPSIS
    Helper function to return PCI Devices Drivers & Firmware information for a specific host.
    .PARAMETER Server
    vCenter VISession object.
    .PARAMETER esxcli
    Esxcli session object associated to the host.
    .EXAMPLE
    $Credentials = Get-Crendentials
    $Server = Connect-VIServer -Server vcenter01.example.com -Credentials $Credentials
    $VMHost = Get-VMHost -Server $Server -Name esx01.example.com
    $esxcli = Get-EsxCli -Server $Server -VMHost $VMHost -V2
    Get-PciDeviceDetail -Server $vCenter -esxcli $esxcli
    VMkernel Name    : vmhba0
    Device Name      : Sunrise Point-LP AHCI Controller
    Driver           : vmw_ahci
    Driver Version   : 1.0.0-34vmw.650.0.14.5146846
    Firmware Version : NA
    VIB Name         : vmw-ahci
    VIB Version      : 1.0.0-34vmw.650.0.14.5146846
    .NOTES
    Author: Erwan Quelin heavily based on the work of the vDocumentation team - https://github.com/arielsanchezmora/vDocumentation/blob/master/powershell/vDocumentation/Public/Get-ESXIODevice.ps1
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        $Server,
        [Parameter(Mandatory = $true)]
        $esxcli
    )
    Begin {}
    
    Process {
        # Set default results
        $firmwareVersion = "N/A"
        $vibName = "N/A"
        $driverVib = @{
            Name = "N/A"
            Version = "N/A"
        }
        $pciDevices = $esxcli.hardware.pci.list.Invoke() | Where-Object {$_.VMKernelName -like "vmhba*" -or $_.VMKernelName -like "vmnic*" -or $_.VMKernelName -like "vmgfx*"} | Sort-Object -Property VMKernelName 
        foreach ($pciDevice in $pciDevices) {
            $driverVersion = $esxcli.system.module.get.Invoke(@{module = $pciDevice.ModuleName}) | Select-Object -ExpandProperty Version
            # Get NIC Firmware version
            if ($pciDevice.VMKernelName -like 'vmnic*') {
                $vmnicDetail = $esxcli.network.nic.get.Invoke(@{nicname = $pciDevice.VMKernelName})
                $firmwareVersion = $vmnicDetail.DriverInfo.FirmwareVersion
                # Get NIC driver VIB package version
                $driverVib = $esxcli.software.vib.list.Invoke() | Select-Object -Property Name, Version | Where-Object {$_.Name -eq $vmnicDetail.DriverInfo.Driver -or $_.Name -eq "net-" + $vmnicDetail.DriverInfo.Driver -or $_.Name -eq "net55-" + $vmnicDetail.DriverInfo.Driver}
                <#
                    If HP Smart Array vmhba* (scsi-hpsa driver) then get Firmware version
                    else skip if VMkernnel is vmhba*. Can't get HBA Firmware from 
                    Powercli at the moment only through SSH or using Putty Plink+PowerCli.
                #>
            } elseif ($pciDevice.VMKernelName -like 'vmhba*') {
                if ($pciDevice.DeviceName -match "smart array") {
                    $hpsa = $vmhost.ExtensionData.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo | Where-Object {$_.Name -match "HP Smart Array"}
                    if ($hpsa) {
                        $firmwareVersion = (($hpsa.Name -split "firmware")[1]).Trim()
                    }
                }
                # Get HBA driver VIB package version
                $vibName = $pciDevice.ModuleName -replace "_", "-"
                $driverVib = $esxcli.software.vib.list.Invoke() | Select-Object -Property Name, Version | Where-Object {$_.Name -eq "scsi-" + $VibName -or $_.Name -eq "sata-" + $VibName -or $_.Name -eq $VibName}
            }
            # Output collected data
            [PSCustomObject]@{
                'VMkernel Name' = $pciDevice.VMKernelName
                'Device Name' = $pciDevice.DeviceName
                'Driver' = $pciDevice.ModuleName
                'Driver Version' = $driverVersion
                'Firmware Version' = $firmwareVersion
                'VIB Name' = $driverVib.Name
                'VIB Version' = $driverVib.Version
            } 
        } 
    }
    End {}
    
}

Function Get-VAMITime {
    <#
.SYNOPSIS
    This function retrieves the time and NTP info from VAMI interface (5480)
    for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
.DESCRIPTION
    Function to return current Time and NTP information.
.EXAMPLE
    PS C:\> Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
    PS C:\> Get-VAMITime
.NOTES
	Created by  :: William Lam @lamw
	Edited by   :: Roman Gelman @rgelman75
	Requirement :: PowerCLI 6.5+, VCSA 6.5+
	Version 1.0 :: 29-Mar-2017 :: [Release] :: Publicly available
.LINK
	http://www.virtuallyghetto.com/2017/01/exploring-new-vcsa-vami-api-wpowercli-part-4.html
#>
	
    $ErrorActionPreference = 'Stop'
    foreach ($Server in ($global:DefaultCisServers | ? { $_.IsConnected })) {
        Try {
            $systemTimeAPI = Get-CisService -Name 'com.vmware.appliance.system.time' -Server $Server
            $timeResults = $systemTimeAPI.get()
			
            $timeSync = (Get-CisService -Name 'com.vmware.appliance.techpreview.timesync' -Server $Server).get()
            $timeSyncMode = $timeSync.mode
			
            $timeResult = [pscustomobject] @{
                Server = $Server.Name
                Timezone = $timeResults.timezone
                Date = $timeResults.date
                CurrentTime = $timeResults.time
                Mode = $timeSyncMode
                NTPServers = "N/A"
                NTPStatus = "N/A"
            }
			
            if ($timeSyncMode -eq "NTP") {
                $ntpServers = (Get-CisService -Name 'com.vmware.appliance.techpreview.ntp' -Server $Server).get()
                $timeResult.NTPServers = $ntpServers.servers -join ', '
                $timeResult.NTPStatus = $ntpServers.status
            }
            $timeResult
        } Catch { }
    }
	
}
#endregion Script Functions

#region Script Body
#---------------------------------------------------------------------------------------------#
#                                         SCRIPT BODY                                         #
#---------------------------------------------------------------------------------------------#

# Counter used for page breaks between vCenter instances
#$Count = @()
#$Count = 1

# Connect to vCenter Server using supplied credentials
foreach ($VIServer in $Target) { 
    #region vCenter Server Section
    $vCenter = Connect-VIServer $VIServer -Credential $Credentials -ErrorAction SilentlyContinue
    $CisServer = Connect-CisServer -Server $VIServer -Credential $Credentials -ErrorAction SilentlyContinue 
    # Create a lookup hashtable to quickly link VM MoRefs to Names
    # Exclude VMware Site Recovery Manager placeholder VMs
    $VMs = Get-VM -Server $vCenter | Where-Object {
        $_.ExtensionData.Config.ManagedBy.ExtensionKey -notlike 'com.vmware.vcDr*'
    } | Sort-Object Name
    $VMLookup = @{}
    foreach ($VM in $VMs) {
        $VMLookup.($VM.Id) = $VM.Name
    }

    # Create a lookup hashtable to quickly link Host MoRefs to Names
    $VMHosts = Get-VMHost -Server $vCenter | Sort-Object Name
    $VMHostLookup = @{}
    foreach ($VMHost in $VMHosts) {
        $VMHostLookup.($VMHost.Id) = $VMHost.Name
    }

    $vCenterAdvSettings = Get-AdvancedSetting -Entity $vCenter
    $vCenterLicense = Get-License -vCenter $vCenter
    $vCenterServerName = ($vCenterAdvSettings | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value
    $vCenterServerName = $vCenterServerName.ToString().ToLower()
    Section -Style Heading1 $vCenterServerName {
        #region vCenter Server Section
        if ($InfoLevel.vCenter -ge 1) {
            Section -Style Heading2 'vCenter Server' { 
                Paragraph ("The following section provides information on the configuration of vCenter " +
                    "Server $vCenterServerName.")
                BlankLine  

                #region vCenter Server Informative Information
                if ($InfoLevel.vCenter -eq 2) {                   
                    $vCenterSummary = [PSCustomObject] @{
                        'Name' = $vCenterServerName
                        'IP Address' = ($vCenterAdvSettings | Where-Object {$_.name -like 'VirtualCenter.ManagedIP'}).Value
                        'Version' = $vCenter.Version
                        'Build' = $vCenter.Build
                        'OS Type' = $vCenter.ExtensionData.Content.About.OsType
                    }
                    $vCenterSummary | Table -Name $vCenterServerName -ColumnWidths 20, 20, 20, 20, 20  
                }
                #endregion vCenter Server Informative Information

                #region vCenter Server Detailed Information
                if ($InfoLevel.vCenter -ge 3) { 
                    $vCenterSpecs = [PSCustomObject] @{
                        'Name' = $vCenterServerName
                        'IP Address' = ($vCenterAdvSettings | Where-Object {$_.name -like 'VirtualCenter.AutoManagedIPV4'}).Value
                        'Version' = $vCenter.Version
                        'Build' = $vCenter.Build
                        'OS Type' = $vCenter.ExtensionData.Content.About.OsType
                        'Product' = $vCenterLicense.Product
                        'License Key' = $vCenterLicense.LicenseKey
                        'HTTP Port' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'config.vpxd.rhttpproxy.httpport'}).Value
                        'HTTPS Port' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'config.vpxd.rhttpproxy.httpsport'}).Value
                        'Instance ID' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'instance.id'}).Value
                        'Password Expiry' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'VirtualCenter.VimPasswordExpirationInDays'}).Value
                        #'Platform Services Controller' = (($vCenterAdvSettings | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value -replace "^https://|/sso-adminserver/sdk/vsphere.local")
                    }
                    if ($vCenter.Version -gt 6) {
                        Add-Member -InputObject $vCenterSpecs -MemberType NoteProperty -Name 'Platform Services Controller' -Value (($vCenterAdvSettings | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value -replace "^https://|/sso-adminserver/sdk/vsphere.local")
                    }   

                    if ($Healthcheck.vCenter.Licensing) {
                        $vCenterSpecs | Where-Object {$_.'Product' -like '*Evaluation*'} | Set-Style -Style Warning -Property 'Product'
                        $vCenterSpecs | Where-Object {$_.'Product' -eq $null} | Set-Style -Style Warning -Property 'Product'
                        $vCenterSpecs | Where-Object {$_.'License Key' -like '*-00000-00000'} | Set-Style -Style Warning -Property 'License Key'
                        $vCenterSpecs | Where-Object {$_.'License Key' -eq 'No License Key'} | Set-Style -Style Warning -Property 'License Key'
                    }
                    $vCenterSpecs | Table -Name $vCenterServerName -List -ColumnWidths 50, 50

                    #region Virtual Appliance Management Interface Settings
                    #if ($vCenter.ExtensionData.Content.About.OsType -eq 'linux-x64') {
                    #    $vCenterVamiSpecs = [PSCustomObject] @{

                    #    }
                    #}
                    #endregion Virtual Appliance Management Interface Settings

                    #region vCenter Server Database Settings
                    Section -Style Heading3 'Database Settings' {
                        $vCenterDbSpecs = [PSCustomObject] @{
                            'Database Type' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'config.vpxd.odbc.dbtype'}).Value
                            'Data Source Name' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'config.vpxd.odbc.dsn'}).Value
                            'Maximum Database Connection' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'VirtualCenter.MaxDBConnection'}).Value
                        }
                        $vCenterDbSpecs | Table -Name 'vCenter Database Settings' -List -ColumnWidths 50, 50 
                    }
                    #endregion vCenter Server Database Settings
                    
                    #region vCenter Server Mail Settings
                    Section -Style Heading3 'Mail Settings' {
                        $vCenterMailSpecs = [PSCustomObject] @{
                            'SMTP Server' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'mail.smtp.server'}).Value
                            'SMTP Port' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'mail.smtp.port'}).Value
                            'Mail Sender' = ($vCenterAdvSettings | Where-Object {$_.name -eq 'mail.sender'}).Value
                        }
                        if ($Healthcheck.vCenter.Mail) {
                            $vCenterMailSpecs | Where-Object {!($_.'SMTP Server')} | Set-Style -Style Critical -Property 'SMTP Server'
                            $vCenterMailSpecs | Where-Object {!($_.'SMTP Port')} | Set-Style -Style Critical -Property 'SMTP Port'
                            $vCenterMailSpecs | Where-Object {!($_.'Mail Sender')} | Set-Style -Style Critical -Property 'Mail Sender' 
                        }
                        $vCenterMailSpecs | Table -Name 'vCenter Mail Settings' -List -ColumnWidths 50, 50 
                    }
                    #endregion vCenter Server Mail Settings
                    
                    #region vCenter Server Historical Statistics
                    Section -Style Heading3 'Historical Statistics' {
                        $vCenterHistoricalStats = Get-vCenterStats | Select-Object @{L = 'Interval Duration'; E = {$_.IntervalDuration}}, @{L = 'Interval Enabled'; E = {$_.IntervalEnabled}}, 
                        @{L = 'Save Duration'; E = {$_.SaveDuration}}, @{L = 'Statistics Level'; E = {$_.StatsLevel}} -Unique
                        $vCenterHistoricalStats | Table -Name 'Historical Statistics' -ColumnWidths 25, 25, 25, 25
                    }
                    #endregion vCenter Server Historical Statistics

                    #region vCenter Server Licensing
                    Section -Style Heading3 'Licensing' {
                        $Licenses = Get-License -Licenses | Select-Object Product, @{L = 'License Key'; E = {($_.LicenseKey)}}, Total, Used, @{L = 'Available'; E = {($_.total) - ($_.Used)}} -Unique
                        if ($Healthcheck.vCenter.Licensing) {
                            $Licenses | Where-Object {$_.Product -eq 'Product Evaluation'} | Set-Style -Style Warning 
                        }
                        $Licenses | Table -Name 'Licensing' -ColumnWidths 32, 32, 12, 12, 12
                    }
                    #endregion vCenter Server Licensing

                    <#
                    #region vCenter Server SSL Certificate
                    Section -Style Heading3 'SSL Certificate' {
                        $VcSslCertHash = @{
                            Country          = ($vCenterAdvSettings | Where-Object {$_.name -eq 'vpxd.certmgmt.certs.cn.country'}).Value
                            Email            = ($vCenterAdvSettings | Where-Object {$_.name -eq 'vpxd.certmgmt.certs.cn.email'}).Value
                            Locality         = ($vCenterAdvSettings | Where-Object {$_.name -eq 'vpxd.certmgmt.certs.cn.localityName'}).Value
                            State            = ($vCenterAdvSettings | Where-Object {$_.name -eq 'vpxd.certmgmt.certs.cn.state'}).Value
                            Organization     = ($vCenterAdvSettings | Where-Object {$_.name -eq 'vpxd.certmgmt.certs.cn.organizationName'}).Value
                            OrganizationUnit = ($vCenterAdvSettings | Where-Object {$_.name -eq 'vpxd.certmgmt.certs.cn.organizationalUnitName'}).Value
                            DaysValid        = ($vCenterAdvSettings | Where-Object {$_.name -eq 'vpxd.certmgmt.certs.daysValid'}).Value
                            Mode             = ($vCenterAdvSettings | Where-Object {$_.name -eq 'vpxd.certmgmt.mode'}).Value
                        }
                        $VcSslCertificate = $VcSslCertHash | Select-Object @{L = 'Country'; E = {$_.Country}}, @{L = 'State'; E = {$_.State}}, @{L = 'Locality'; E = {$_.Locality}}, 
                        @{L = 'Organization'; E = {$_.Organization}}, @{L = 'Organizational Unit'; E = {$_.OrganizationUnit}}, @{L = 'Email'; E = {$_.Email}}, @{L = 'Validity'; E = {"$($_.DaysValid / 365) Years"}}  
                        $VcSslCertificate | Table -Name "$vCenter SSL Certificate" -List -ColumnWidths 50, 50
                    }
                    #endregion vCenter Server SSL Certificate
                    #>
                    
                    #region vCenter Server Roles
                    Section -Style Heading3 'Roles' {
                        $VCRoles = Get-VIRole -Server $vCenter | Sort-Object Name | Select-Object Name, @{L = 'System Role'; E = {$_.IsSystem}}
                        $VCRoles | Table -Name 'Roles' -ColumnWidths 50, 50 
                    }
                    #endregion vCenter Server Roles

                    #region vCenter Server Tags
                    $Tags = Get-Tag -Server $vCenter
                    if ($Tags) {
                        Section -Style Heading3 'Tags' {
                            $Tags = $Tags | Sort-Object Name, Category | Select-Object Name, Description, Category
                            $Tags | Table -Name 'Tags'
                        }
                    }
                    #endregion vCenter Server Tags

                    #region vCenter Server Tag Categories
                    $TagCategories = Get-TagCategory 
                    if ($TagCategories) {
                        Section -Style Heading3 'Tag Categories' {
                            $TagCategories = $TagCategories | Sort-Object Name | Select-Object Name, Description, Cardinality -Unique
                            $TagCategories | Table -Name 'Tag Categories' -ColumnWidths 40, 40, 20
                        }
                    }
                    #endregion vCenter Server Tag Categories
                        
                    #region vCenter Server Tag Assignments
                    $TagAssignments = Get-TagAssignment | Sort-Object Tag, Entity
                    if ($TagAssignments) {
                        Section -Style Heading3 'Tag Assignments' {
                            $TagAssignments = $TagAssignments | Select-Object Tag, Entity
                            $TagAssignments | Table -Name 'Tag Assignments' -ColumnWidths 50, 50
                        }
                    }
                    #endregion vCenter Server Tag Assignments
                }
                #endregion vCenter Server Detailed Information
                    
                #region vCenter Alarms
                if ($InfoLevel.vCenter -ge 5) {
                    Section -Style Heading3 'Alarms' {
                        Paragraph ("The following table details the configuration of the vCenter Server " +
                            "alarms for $vCenterServerName.")
                        BlankLine
                        $Alarms = Get-AlarmAction -Server $vCenter | Sort-Object AlarmDefinition | Select-Object @{L = 'Alarm Definition'; E = {$_.AlarmDefinition}}, @{L = 'Action Type'; E = {$_.ActionType}}, @{L = 'Trigger'; E = {$_.Trigger -join [Environment]::NewLine}}
                        $Alarms | Table -Name 'Alarms' -ColumnWidths 50, 20, 30
                    }
                }
                #endregion vCenter Alarms
            }
        }
        #endregion vCenter Server Section

        #region Cluster Section
        if ($InfoLevel.Cluster -ge 1) {
            $Script:Clusters = Get-Cluster -Server $vCenter | Sort-Object Name
            if ($Clusters) {
                Section -Style Heading2 'Clusters' {
                    Paragraph ("The following section provides information on the configuration of each " +
                        "vSphere HA/DRS cluster managed by vCenter Server $vCenterServerName.")
                    BlankLine

                    #region Cluster Informative Information   
                    if ($InfoLevel.Cluster -eq 2) {
                        $ClusterSummary = foreach ($Cluster in $Clusters) {
                            [PSCustomObject] @{
                                'Name' = $Cluster.Name
                                'Datacenter' = $Cluster | Get-Datacenter
                                '# of Hosts' = $Cluster.ExtensionData.Host.Count 
                                '# of VMs' = $Cluster.ExtensionData.VM.Count
                                'vSphere HA' = Switch ($Cluster.HAEnabled) {
                                    'True' {'Enabled'}
                                    'False' {'Disabled'}
                                }
                                'vSphere DRS' = Switch ($Cluster.DrsEnabled) {
                                    'True' {'Enabled'}
                                    'False' {'Disabled'}
                                }
                                'Virtual SAN' = Switch ($Cluster.VsanEnabled) {
                                    'True' {'Enabled'}
                                    'False' {'Disabled'}
                                }
                                'EVC Mode' = Switch ($Cluster.EVCMode) {
                                    $null {'Disabled'}
                                    default {$Cluster.EVCMode}
                                }  
                                'VM Swap File Policy' = $Cluster.VMSwapfilePolicy                   
                            }
                        }
                        if ($Healthcheck.Cluster.HAEnabled) {
                            $ClusterSummary | Where-Object {$_.'vSphere HA' -eq 'Disabled'} | Set-Style -Style Warning -Property 'vSphere HA'
                        }
                        if ($Healthcheck.Cluster.DrsEnabled) {
                            $ClusterSummary | Where-Object {$_.'vSphere DRS' -eq 'Disabled'} | Set-Style -Style Warning -Property 'vSphere DRS'
                        }
                        if ($Healthcheck.Cluster.VsanEnabled) {
                            $ClusterSummary | Where-Object {$_.'Virtual SAN' -eq 'Disabled'} | Set-Style -Style Warning -Property 'Virtual SAN'
                        }
                        if ($Healthcheck.Cluster.EvcEnabled) {
                            $ClusterSummary | Where-Object {$_.'EVC Mode' -eq 'Disabled'} | Set-Style -Style Warning -Property 'EVC Mode'
                        }
                        $ClusterSummary | Table -Name 'Cluster Summary' #-ColumnWidths 15, 15, 8, 11, 11, 11, 11, 10, 8    
                    }
                    #endregion Cluster Informative Information

                    #region Cluster Detailed Information
                    if ($InfoLevel.Cluster -ge 3) {  
                        foreach ($Cluster in ($Clusters)) {
                            Section -Style Heading3 $Cluster {
                                Paragraph "The following table details the configuration for cluster $Cluster."
                                BlankLine
                                #region Cluster Configuration                                
                                $ClusterSpecs = [PSCustomObject] @{
                                    'Name' = $Cluster.Name
                                    'ID' = $Cluster.Id
                                    'Datacenter' = $Cluster | Get-Datacenter
                                    'Number of Hosts' = $Cluster.ExtensionData.Host.Count 
                                    'Number of VMs' = $Cluster.ExtensionData.VM.Count 
                                    'vSphere HA' = Switch ($Cluster.HAEnabled) {
                                        'True' {'Enabled'}
                                        'False' {'Disabled'}
                                    }
                                    'vSphere DRS' = Switch ($Cluster.DrsEnabled) {
                                        'True' {'Enabled'}
                                        'False' {'Disabled'}
                                    }
                                    'Virtual SAN' = Switch ($Cluster.VsanEnabled) {
                                        'True' {'Enabled'}
                                        'False' {'Disabled'}
                                    }
                                    'EVC Mode' = Switch ($Cluster.EVCMode) {
                                        $null {'Disabled'}
                                        default {$Cluster.EVCMode}
                                    } 
                                    'VM Swap File Policy' = Switch ($Cluster.VMSwapfilePolicy) {
                                        'WithVM' {'Virtual machine directory'}
                                        'InHostDatastore' {'Datastore specified by host'}
                                    }   
                                }                                
                                if ($Healthcheck.Cluster.HAEnabled) {
                                    $ClusterSpecs | Where-Object {$_.'vSphere HA' -eq 'Disabled'} | Set-Style -Style Warning -Property 'vSphere HA'
                                }
                                if ($Healthcheck.Cluster.DrsEnabled) {
                                    $ClusterSpecs | Where-Object {$_.'vSphere DRS' -eq 'Disabled'} | Set-Style -Style Warning -Property 'vSphere DRS'
                                }
                                if ($Healthcheck.Cluster.VsanEnabled) {
                                    $ClusterSpecs | Where-Object {$_.'Virtual SAN' -eq 'Disabled'} | Set-Style -Style Warning -Property 'Virtual SAN'
                                }
                                if ($Healthcheck.Cluster.EvcEnabled) {
                                    $ClusterSpecs | Where-Object {$_.'EVC Mode' -eq 'Disabled'} | Set-Style -Style Warning -Property 'EVC Mode'
                                }
                                if ($InfoLevel.Cluster -ge 4) {
                                    $ClusterSpecs | ForEach-Object {
                                        $ClusterHosts = $Cluster | Get-VMHost | Sort-Object Name
                                        Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Hosts' -Value ($ClusterHosts.Name -join ", ")
                                        $ClusterVMs = $Cluster | Get-VM | Sort-Object Name 
                                        Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Virtual Machines' -Value ($ClusterVMs.Name -join ", ")
                                    }
                                }
                                $ClusterSpecs | Table -List -Name "$Cluster Information" -ColumnWidths 50, 50
                                #endregion Cluster Configuration
                                
                                #region HA Cluster Configuration
                                Section -Style Heading4 'HA Configuration' {
                                    Paragraph ("The following table details the vSphere HA configuration " +
                                        "for cluster $Cluster.")
                                    BlankLine

                                    ### TODO: HA Advanced Settings, Proactive HA
                                    #region HA Cluster Specifications
                                    $ClusterDasConfig = $Cluster.ExtensionData.Configuration.DasConfig
                                    $HACluster = [PSCustomObject] @{
                                        'vSphere HA' = Switch ($Cluster.HAEnabled) {
                                            'True' {'Enabled'}
                                            'False' {'Disabled'}
                                        }
                                        'Admission Control' = Switch ($Cluster.HAAdmissionControlEnabled) {
                                            'True' {'Enabled'}
                                            'False' {'Disabled'}
                                        }
                                        'Host Failures Cluster Tolerates' = $Cluster.HAFailoverLevel
                                        'Host Failover Capacity Policy' = Switch ($ClusterDasConfig.AdmissionControlPolicy.GetTYpe().Name) {
                                            'ClusterFailoverHostAdmissionControlPolicy' {'Dedicated failover hosts'}
                                            'ClusterFailoverResourcesAdmissionControlPolicy' {'Cluster resource percentage'}
                                            'ClusterFailoverLevelAdmissionControlPolicy' {'Slot policy'}
                                        }
                                        'Performance Degradation VMs Tolerate' = Switch ($ClusterDasConfig.AdmissionControlPolicy.ResourceReductionToToleratePercent) {
                                            $null {'Not applicable'}
                                            default {"$($ClusterDasConfig.AdmissionControlPolicy.ResourceReductionToToleratePercent)%"}
                                        }
                                        'Host Monitoring' = Switch ($ClusterDasConfig.HostMonitoring) {
                                            'disabled' {'Disabled'}
                                            'enabled' {'Enabled'}
                                        }  
                                        'Response for Host Isolation' = Switch ($Cluster.HAIsolationResponse) {
                                            'DoNothing' {'Disabled'}
                                            'Shutdown' {'Shutdown and restart VMs'}
                                            'PowerOff' {'Power off and restart VMs'}
                                        }
                                        'VM Restart Priority' = $Cluster.HARestartPriority 
                                        'VM Monitoring' = Switch ($ClusterDasConfig.VmMonitoring) {
                                            'vmMonitoringDisabled' {'Disabled'}
                                            'vmMonitoringOnly' {'VM monitoring only'}
                                            'vmAndAppMonitoring' {'VM and application monitoring'}
                                        }
                                        'Datastore with Permanent Device Loss' = Switch ($ClusterDasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL) {
                                            $null {'Not applicable'}
                                            'disabled' {'Disabled'}
                                            'warning' {'Issue events'}
                                            'restartAggressive' {'Power off and restart VMs'}
                                            default {$ClusterDasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL}
                                        }
                                        'Datastore with All Paths Down' = Switch ($ClusterDasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD) {
                                            $null {'Not applicable'}
                                            'disabled' {'Disabled'}
                                            'warning' {'Issue events'}
                                            'restartConservative' {'Power off and restart VMs (conservative)'}
                                            'restartAggressive' {'Power off and restart VMs (aggressive)'}
                                            default {$ClusterDasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD}
                                        }
                                        'APD recovery after APD timeout' = Switch ($ClusterDasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmReactionOnAPDCleared) {
                                            $null {'Not applicable'}
                                            'none' {'Disabled'}
                                            'reset' {'Reset VMs'}
                                            default {$ClusterDasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmReactionOnAPDCleared}
                                        }
                                        'Heartbeat Selection Policy' = Switch ($ClusterDasConfig.HBDatastoreCandidatePolicy) {
                                            'allFeasibleDsWithUserPreference' {'Use datastores from the specified list and complement automatically if needed'}
                                            'allFeasibleDs' {'Automatically select datastores accessible from the host'}
                                            'userSelectedDs' {'Use datastores only from the specified list'}
                                            default {$ClusterDasConfig.HBDatastoreCandidatePolicy}
                                        }
                                        'Heartbeat Datastores' = Switch ($ClusterDasConfig.HeartbeatDatastore) {
                                            $null {'None specified'}
                                            default {((Get-View -Id $ClusterDasConfig.HeartbeatDatastore -Property Name).Name | Sort-Object) -join ", "}
                                        }    
                                    }
                                    if ($Healthcheck.Cluster.HAEnabled) {
                                        $HACluster | Where-Object {$_.'vSphere HA' -eq 'Disabled'} | Set-Style -Style Warning -Property 'vSphere HA'
                                    }
                                    if ($Healthcheck.Cluster.HAAdmissionControl) {
                                        $HACluster | Where-Object {$_.'Admission Control' -eq 'Disabled'} | Set-Style -Style Warning -Property 'Admission Control'
                                    }
                                    if ($Healthcheck.Cluster.HostMonitoring) {
                                        $HACluster | Where-Object {$_.'Host Monitoring' -eq 'Disabled'} | Set-Style -Style Warning -Property 'Host Monitoring'
                                    }
                                    if ($Healthcheck.Cluster.DatastoreOnPDL) {
                                        $HACluster | Where-Object {$_.'Datastore with Permanent Device Loss' -eq 'Disabled'} | Set-Style -Style Warning -Property 'Datastore with Permanent Device Loss'
                                    }
                                    if ($Healthcheck.Cluster.DatastoreOnAPD) {
                                        $HACluster | Where-Object {$_.'Datastore with All Paths Down' -eq 'Disabled'} | Set-Style -Style Warning -Property 'Datastore with All Paths Down'
                                    }
                                    if ($Healthcheck.Cluster.APDTimeout) {
                                        $HACluster | Where-Object {$_.'APD recovery after APD timeout' -eq 'Disabled'} | Set-Style -Style Warning -Property 'APD recovery after APD timeout'
                                    }
                                    if ($Healthcheck.Cluster.vmMonitoring) {
                                        $HACluster | Where-Object {$_.'VM Monitoring' -eq 'Disabled'} | Set-Style -Style Warning -Property 'VM Monitoring'
                                    }
                                    $HACluster | Table -Name "$Cluster HA Configuration" -List -ColumnWidths 50, 50
                                    #endregion HA Cluster Specifications

                                    #region HA Cluster Advanced Options
                                    $HAAdvancedSettings = $Cluster | Get-AdvancedSetting | Where-Object {$_.Type -eq 'ClusterHA'}
                                    if ($HAAdvancedSettings) {
                                        Section -Style Heading5 'HA Advanced Options' {
                                            $HAAdvancedOptions = @()
                                            foreach ($HAAdvancedSetting in $HAAdvancedSettings) { 
                                                $HAAdvancedOption = [PSCustomObject] @{
                                                    'Option' = $HAAdvancedSetting.Name
                                                    'Value' = $HAAdvancedSetting.Value
                                                }
                                                $HAAdvancedOptions += $HAAdvancedOption
                                            }
                                            $HAAdvancedOptions | Sort-Object Option | Table -Name "$Cluster HA Advanced Options" -ColumnWidths 50, 50
                                        }
                                    }
                                    #endregion HA Cluster Advanced Options
                                }
                                #endregion HA Cluster Configuration

                                #region DRS Cluster Configuration
                                Section -Style Heading4 'DRS Configuration' {
                                    Paragraph ("The following table details the vSphere DRS configuration " +
                                        "for cluster $Cluster.")
                                    BlankLine

                                    ## TODO: DRS Advanced Settings
                                    #region DRS Cluster Specifications
                                    $ClusterDrsConfig = $Cluster.ExtensionData.Configuration.DrsConfig
                                    $DrsCluster = [PSCustomObject] @{
                                        'vSphere DRS' = Switch ($Cluster.DrsEnabled) {
                                            'True' {'Enabled'}
                                            'False' {'Disabled'}
                                        } 
                                        'Automation Level' = Switch ($Cluster.DrsAutomationLevel) {
                                            'Manual' {'Manual'}
                                            'PartiallyAutomated' {'Partially Automated'}
                                            'FullyAutomated' {'Fully Automated'}
                                        } 
                                        'Migration Threshold' = $ClusterDrsConfig.VmotionRate
                                        'Virtual Machine Automation' = Switch ($ClusterDrsConfig.EnableVmBehaviorOverrides) {
                                            'True' {'Enabled'}
                                            'False' {'Disabled'}
                                        }
                                    }
                                    if ($Healthcheck.Cluster.DrsEnabled) {
                                        $DrsCluster | Where-Object {$_.'vSphere DRS' -eq 'Disabled'} | Set-Style -Style Warning -Property 'vSphere DRS'
                                    }
                                    if ($Healthcheck.Cluster.DrsAutomationLevel) {
                                        $DrsCluster | Where-Object {$_.'Automation Level' -ne $Healthcheck.Cluster.DrsAutomationLevelSetting} | Set-Style -Style Warning -Property 'Automation Level'
                                    }
                                    $DrsCluster | Table -Name "$Cluster DRS Configuration" -List -ColumnWidths 50, 50 
                                    #endregion DRS Cluster Specfications
                                    BlankLine

                                    #region DRS Cluster Advanced Options
                                    $DrsAdvancedSettings = $Cluster | Get-AdvancedSetting | Where-Object {$_.Type -eq 'ClusterDRS'}
                                    if ($DrsAdvancedSettings) {
                                        Section -Style Heading5 'DRS Advanced Options' {
                                            $DrsAdvancedOptions = [PSCustomObject] @{
                                                #'VM Distribution' = ($DrsAdvancedSettings | Where-Object {$_.name -eq 'TryBalanceVmsPerHost'}).Value
                                                #'Memory Metric for Load Balancing' = ($DrsAdvancedSettings | Where-Object {$_.name -eq 'PercentIdleMBInMemDemand'}).Value
                                                #'CPU Over-Commitment' = ($DrsAdvancedSettings | Where-Object {$_.name -eq 'MaxVcpusPerClusterPct'}).Value
                                                $DrsAdvancedOptions = [PSCustomObject] @{
                                                    'Option' = $DrsAdvancedSettings.Name
                                                    'Value' = $DrsAdvancedSettings.Value
                                                }
                                            }
                                            $DrsAdvancedOptions | Table -Name "$Cluster DRS Advanced Options" -ColumnWidths 50, 50
                                        }
                                    }
                                    #endregion DRS Cluster Advanced Options

                                    #region DRS Cluster Group
                                    $DrsGroups = $Cluster | Get-DrsClusterGroup
                                    if ($DrsGroups) {
                                        Section -Style Heading5 'DRS Cluster Groups' {
                                            $DrsGroups = $DrsGroups | Sort-Object GroupType, Name | Select-Object Name, @{L = 'Group Type'; E = {$_.GroupType}}, @{L = 'Members'; E = {($_.Member | Sort-Object) -join ", "}}
                                            $DrsGroups | Table -Name "$Cluster DRS Cluster Groups"
                                        }
                                    }
                                    #endregion DRS Cluster Group  

                                    #region DRS Cluster VM/Host Rules
                                    $DrsVMHostRules = $Cluster | Get-DrsVMHostRule
                                    if ($DrsVMHostRules) {
                                        Section -Style Heading5 'DRS VM/Host Rules' {
                                            $DrsVMHostRules = $DrsVMHostRules | Sort-Object Name | Select-Object Name, Type, Enabled, @{L = 'VM Group'; E = {$_.VMGroup}}, @{L = 'VMHost Group'; E = {$_.VMHostGroup}}
                                            if ($Healthcheck.Cluster.DrsVMHostRules) {
                                                $DrsVMHostRules | Where-Object {$_.Enabled -eq $False} | Set-Style -Style Warning -Property Enabled
                                            }
                                            $DrsVMHostRules | Table -Name "$Cluster DRS VM/Host Rules"
                                        }
                                    }
                                    #endregion DRS Cluster VM/Host Rules

                                    #region DRS Cluster Rules
                                    $DrsRules = $Cluster | Get-DrsRule
                                    if ($DrsRules) {
                                        Section -Style Heading5 'DRS Rules' {
                                            $DrsRules = $DrsRules | Sort-Object Type | Select-Object Name, Type, Enabled, Mandatory, @{L = 'Virtual Machines'; E = {($_.VMIds | ForEach-Object {(get-view -id $_).name}) -join ", "}}
                                            if ($Healthcheck.Cluster.DrsRules) {
                                                $DrsRules | Where-Object {$_.Enabled -eq $False} | Set-Style -Style Warning -Property Enabled
                                            }
                                            $DrsRules | Table -Name "$Cluster DRS Rules"
                                        }
                                    }
                                    #endregion DRS Cluster Rules                                
                                }
                                
                                #region Cluster VUM Baselines
                                $ClusterBaselines = $Cluster | Get-PatchBaseline
                                if ($ClusterBaselines) {
                                    Section -Style Heading4 'Update Manager Baselines' {
                                        $ClusterBaselines = $ClusterBaselines | Sort-Object Name | Select-Object Name, Description, @{L = 'Type'; E = {$_.BaselineType}}, @{L = 'Target Type'; E = {$_.TargetType}}, @{L = 'Last Update Time'; E = {$_.LastUpdateTime}}, @{L = '# of Patches'; E = {($_.CurrentPatches).count}}
                                        $ClusterBaselines | Table -Name "$Cluster Update Manager Baselines"
                                    }
                                }
                                #endregion Cluster VUM Baselines

                                #region Cluster VUM Compliance
                                # Set InfoLevel to 4 or above to provide information for VMware Update Manager compliance
                                if ($InfoLevel.Cluster -ge 4) {
                                    $ClusterCompliance = $Cluster | Get-Compliance
                                    if ($ClusterCompliance) {
                                        Section -Style Heading4 'Update Manager Compliance' {
                                            $ClusterCompliance = $ClusterCompliance | Sort-Object Entity, Baseline | Select-Object @{L = 'Name'; E = {$_.Entity}}, @{L = 'Baseline'; E = {($_.Baseline).Name -join ", "}}, Status
                                            if ($Healthcheck.Cluster.VUMCompliance) {
                                                $ClusterCompliance | Where-Object {$_.Status -eq 'Unknown'} | Set-Style -Style Warning
                                                $ClusterCompliance | Where-Object {$_.Status -eq 'NotCompliant' -or $_.Status -eq 'Incompatible'} | Set-Style -Style Critical
                                            }
                                            $ClusterCompliance | Table -Name "$Cluster Update Manager Compliance" -ColumnWidths 25, 50, 25
                                        }
                                    }
                                }
                                #endregion Cluster VUM Compliance
                
                                #region Cluster Permissions
                                Section -Style Heading4 'Permissions' {
                                    Paragraph ("The following table details the permissions assigned " +
                                        "to cluster $Cluster.")
                                    BlankLine
                                    $VIPermission = $Cluster | Get-VIPermission | Select-Object @{L = 'User/Group'; E = {$_.Principal}}, @{L = 'Is Group?'; E = {$_.IsGroup}}, Role, @{L = 'Defined In'; E = {$_.Entity}}, Propagate | Sort-Object 'User/Group'
                                    $VIPermission | Table -Name "$Cluster Permissions"
                                }
                                #endregion Cluster Permissions
                            }
                            #endregion DRS Cluster Configuration
                        }
                        #endregion Cluster Detailed Information
                    }
                }
            }
        }
        #endregion Cluster Section   

        #region Resource Pool Section
        if ($InfoLevel.ResourcePool -ge 1) {
            $Script:ResourcePools = Get-ResourcePool -Server $vCenter | Sort-Object Parent, Name
            if ($ResourcePools) {
                Section -Style Heading2 'Resource Pools' {
                    Paragraph ("The following section provides information on the configuration of " +
                        "resource pools managed by vCenter Server $vCenterServerName.")
                    BlankLine
                    if ($InfoLevel.ResourcePool -eq 2) {
                        #region Resource Pool Informative Information
                        $ResourcePoolSummary = $ResourcePools | Select-Object Name, Parent, @{L = 'CPU Shares Level'; E = {$_.CpuSharesLevel}}, @{L = 'CPU Reservation MHz'; E = {$_.CpuReservationMHz}}, 
                        @{L = 'CPU Limit MHz'; E = {if ($_.CpuLimitMHz -eq -1) {"Unlimited"} else {$_.CpuLimitMHz}}}, @{L = 'Memory Shares Level'; E = {$_.MemSharesLevel}}, 
                        @{L = 'Memory Reservation'; E = {[math]::Round($_.MemReservationGB, 2)}}, @{L = 'Memory Limit GB'; E = {if ($_.MemLimitGB -eq -1) {"Unlimited"} else {[math]::Round($_.MemLimitGB, 2)}}}
                        $ResourcePoolSummary | Table -Name 'Resource Pool Summary' #-ColumnWidths 11,11,13,13,13,13,13,13
                    }                    
                    #endregion Resource Pool Informative Information

                    if ($InfoLevel.ResourcePool -ge 3) {
                        #region Resource Pool Detailed Information
                        foreach ($ResourcePool in $ResourcePools) {
                            Section -Style Heading3 $ResourcePool.Name {
                                $ResourcePoolSpecs = $ResourcePool | Select-Object Name, id, Parent, @{L = 'CPU Shares Level'; E = {$_.CpuSharesLevel}}, @{L = 'Number of CPU Shares'; E = {$_.NumCpuShares}}, 
                                @{L = 'CPU Reservation'; E = {"$($_.CpuReservationMHz) MHz"}}, @{L = 'CPU Expandable Reservation'; E = {$_.CpuExpandableReservation}}, @{L = 'CPU Limit'; E = {if ($_.CpuLimitMHz -eq -1) {"Unlimited"} else {"$($_.CpuLimitMHz) MHz"}}}, 
                                @{L = 'Memory Shares Level'; E = {$_.MemSharesLevel}}, @{L = 'Number of Memory Shares'; E = {$_.NumMemShares}}, @{L = 'Memory Reservation'; E = {"$([math]::Round($_.MemReservationGB, 2)) GB"}}, 
                                @{L = 'Memory Expandable Reservation'; E = {$_.MemExpandableReservation}}, @{L = 'Memory Limit'; E = {if ($_.MemLimitGB -eq -1) {"Unlimited"} else {"$([math]::Round($_.MemLimitGB, 2)) GB"}}}, @{L = 'Number of VMs'; E = {($_ | Get-VM).count}}
            
                                # Set InfoLevel to 4 or above to provide information for associated VMs
                                if ($InfoLevel.ResourcePool -ge 4) {
                                    $ResourcePoolSpecs | ForEach-Object {
                                        # Query for VMs by resource pool Id
                                        $ResourcePoolId = $_.Id
                                        $ResourcePoolVMs = $VMs | Where-Object { $_.ResourcePoolId -eq $ResourcePoolId } | Sort-Object Name
                                        Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Virtual Machines' -Value ($ResourcePoolVMs.Name -join ", ")
                                    }
                                }
                                $ResourcePoolSpecs | Table -Name 'Resource Pools' -List -ColumnWidths 50, 50  
                            }
                        }
                        #endregion Resource Pool Detailed Information
                    }
                }
            }
        }
        #endregion Resource Pool Section

        #region ESXi VMHost Section
        if ($InfoLevel.VMHost -ge 1) {
            if ($VMHosts) {
                Section -Style Heading2 'Hosts' {
                    Paragraph ("The following section provides information on the configuration of VMware " +
                        "ESXi hosts managed by vCenter Server $vCenterServerName.")
                    BlankLine
    
                    #region ESXi Host Informative Information
                    if ($InfoLevel.VMHost -eq 2) {
                        $VMHostSummary = $VMHosts | Select-Object name, version, build, parent, @{L = 'Connection State'; E = {$_.ConnectionState}}, @{L = 'CPU Usage MHz'; E = {$_.CpuUsageMhz}}, @{L = 'Memory Usage GB'; E = {[math]::Round($_.MemoryUsageGB, 2)}}
                        if ($Healthcheck.VMHost.ConnectionState) {
                            $VMHostSummary | Where-Object {$_.'Connection State' -eq 'Maintenance'} | Set-Style -Style Warning
                            $VMHostSummary | Where-Object {$_.'Connection State' -eq 'Disconnected'} | Set-Style -Style Critical
                        }
                        $VMHostSummary | Table -Name 'Host Summary' #-ColumnWidths 23, 10, 12, 12, 14, 10, 10, 9
                    }
                    #endregion ESXi Host Informative Information

                    #region ESXi Host Detailed Information
                    if ($InfoLevel.VMHost -ge 3) {       
                        foreach ($VMHost in ($VMHosts | Where-Object {$_.ConnectionState -eq 'Connected' -or $_.ConnectionState -eq 'Maintenance'})) {        
                            Section -Style Heading3 $VMHost {

                                ### TODO: Host Certificate, Swap File Location
                                #region ESXi Host Hardware Section
                                Section -Style Heading4 'Hardware' {
                                    Paragraph ("The following section provides information on the host " +
                                        "hardware configuration of $VMHost.")
                                    BlankLine

                                    #region ESXi Host Specifications
                                    $VMHostUptime = Get-Uptime -VMHost $VMHost
                                    $esxcli = Get-EsxCli -VMHost $VMHost -V2 -Server $vCenter
                                    $VMHostHardware = Get-VMHostHardware -VMHost $VMHost
                                    $VMHostLicense = Get-License -VMHost $VMHost
                                    $ScratchLocation = Get-AdvancedSetting -Entity $VMHost | Where-Object {$_.Name -eq 'ScratchConfig.CurrentScratchLocation'}
                                    $VMHostSpecs = $VMHost | Sort-Object Name | Select-Object name, id, parent, manufacturer, model, @{L = 'Serial Number'; E = {$VMHostHardware.SerialNumber}}, @{L = 'Asset Tag'; E = {$VMHostHardware.AssetTag}}, 
                                    @{L = 'Processor Type'; E = {($_.processortype)}}, @{L = 'HyperThreading'; E = {($_.HyperthreadingActive)}}, @{L = 'Number of CPU Sockets'; E = {$_.ExtensionData.Hardware.CpuInfo.NumCpuPackages}}, 
                                    @{L = 'Number of CPU Cores'; E = {$_.ExtensionData.Hardware.CpuInfo.NumCpuCores}}, @{L = 'Number of CPU Threads'; E = {$_.ExtensionData.Hardware.CpuInfo.NumCpuThreads}}, 
                                    @{L = 'CPU Speed'; E = {"$([math]::Round(($_.ExtensionData.Hardware.CpuInfo.Hz) / 1000000000, 2)) GHz"}}, @{L = 'Memory'; E = {"$([math]::Round($_.memorytotalgb, 0)) GB"}}, 
                                    @{L = 'NUMA Nodes'; E = {$_.ExtensionData.Hardware.NumaInfo.NumNodes}}, @{L = 'Number of NICs'; E = {$VMHostHardware.NicCount}}, @{L = 'Number of Datastores'; E = {($_.DatastoreIdList).Count}}, @{L = 'Number of VMs'; E = {($_ | Get-VM).count}},  
                                    @{L = 'Maximum EVC Mode'; E = {$_.MaxEVCMode}}, @{L = 'Power Management Policy'; E = {$_.ExtensionData.Hardware.CpuPowerManagementInfo.CurrentPolicy}}, @{L = 'Scratch Location'; E = {$ScratchLocation.Value}}, 
                                    @{L = 'Bios Version'; E = {$_.ExtensionData.Hardware.BiosInfo.BiosVersion}}, @{L = 'Bios Release Date'; E = {$_.ExtensionData.Hardware.BiosInfo.ReleaseDate}}, @{L = 'ESXi Version'; E = {$_.version}}, 
                                    @{L = 'ESXi Build'; E = {$_.build}}, @{L = 'Product'; E = {$VMHostLicense.Product}}, @{L = 'License Key'; E = {$VMHostLicense.LicenseKey}}, @{L = 'Boot Time'; E = {$_.ExtensionData.Runtime.Boottime}}, @{L = 'Uptime Days'; E = {$VMHostUptime.UptimeDays}}                                   
                                    if ($Healthcheck.VMHost.Licensing) {
                                        $VMHostSpecs | Where-Object {$_.'Product' -like '*Evaluation*'} | Set-Style -Style Warning -Property 'Product'
                                        $VMHostSpecs | Where-Object {$_.'License Key' -like '*-00000-00000'} | Set-Style -Style Warning -Property 'License Key'
                                    }
                                    if ($Healthcheck.VMHost.ScratchLocation) {
                                        $VMHostSpecs | Where-Object {$_.'Scratch Location' -eq '/tmp/scratch'} | Set-Style -Style Warning -Property 'Scratch Location'
                                    }
                                    if ($Healthcheck.VMHost.UpTimeDays) {
                                        $VMHostSpecs | Where-Object {$_.'Uptime Days' -ge 275 -and $_.'Uptime Days' -lt 365} | Set-Style -Style Warning -Property 'Uptime Days'
                                        $VMHostSpecs | Where-Object {$_.'Uptime Days' -ge 365} | Set-Style -Style Warning -Property 'Uptime Days'
                                    }
                                    $VMHostSpecs | Table -Name "$VMHost Specifications" -List -ColumnWidths 50, 50 
                                    #endregion ESXi Host Specifications

                                    #region ESXi Host Boot Devices
                                    Section -Style Heading5 'Boot Devices' {
                                        $BootDevice = Get-ESXiBootDevice -VMHost $VMHost | Select-Object Host, Device, @{L = 'Boot Type'; E = {$_.BootType}}, Vendor, Model, @{L = 'Size MB'; E = {$_.SizeMB}}, @{L = 'Is SAS'; E = {$_.IsSAS}}, @{L = 'Is SSD'; E = {$_.IsSSD}}, 
                                        @{L = 'Is USB'; E = {$_.IsUSB}}
                                        $BootDevice | Table -Name "$VMHost Boot Devices" -List -ColumnWidths 50, 50 
                                    }
                                    #endregion ESXi Host Boot Devices

                                    #region ESXi Host PCI Devices
                                    Section -Style Heading5 'PCI Devices' {
                                        $PciHardwareDevice = $esxcli.hardware.pci.list.Invoke() | Where-Object {$_.VMKernelName -like "vmhba*" -OR $_.VMKernelName -like "vmnic*" -OR $_.VMKernelName -like "vmgfx*"} 
                                        $VMHostPciDevices = $PciHardwareDevice | Sort-Object VMkernelName | Select-Object @{L = 'VMkernel Name'; E = {$_.VMkernelName}}, @{L = 'PCI Address'; E = {$_.Address}}, @{L = 'Device Class'; E = {$_.DeviceClassName}}, 
                                        @{L = 'Device Name'; E = {$_.DeviceName}}, @{L = 'Vendor Name'; E = {$_.VendorName}}, @{L = 'Slot Description'; E = {$_.SlotDescription}}
                                        $VMHostPciDevices | Table -Name "$VMHost PCI Devices" 
                                    }
                                    #endregion ESXi Host PCI Devices
                                    
                                    #region ESXi Host PCI Devices Drivers & Firmware
                                    if ($Options.ShowDriversFirmware) {
                                        Section -Style Heading5 'PCI Devices Drivers & Firmware' {
                                            $VMHostPciDevicesDetails = Get-PciDeviceDetail -Server $vCenter -esxcli $esxcli | Sort-Object 'VMkernel Name' 
                                            $VMHostPciDevicesDetails | Table -Name "$VMHost PCI Devices Drivers & Firmware" 
                                        }
                                    }
                                    #endregion ESXi Host PCI Devices Drivers & Firmware
                                }
                                #endregion ESXi Host Hardware Section

                                #region ESXi Host System Section
                                Section -Style Heading4 'System' {
                                    Paragraph ("The following section provides information on the host " +
                                        "system configuration of $VMHost.")

                                    #region ESXi Host Profile Information
                                    if ($VMHost | Get-VMHostProfile) {
                                        Section -Style Heading5 'Host Profile' {
                                            $VMHostProfile = $VMHost | Get-VMHostProfile | Select-Object Name, Description
                                            $VMHostProfile | Table -Name "$VMHost Host Profile" -ColumnWidths 50, 50 
                                        }
                                    }
                                    #endregion ESXi Host Profile Information

                                    #region ESXi Host Image Profile Information
                                    Section -Style Heading5 'Image Profile' {
                                        $installdate = Get-InstallDate
                                        $esxcli = Get-ESXCli -VMHost $VMHost -V2 -Server $vCenter
                                        $ImageProfile = $esxcli.software.profile.get.Invoke()
                                        $SecurityProfile = $ImageProfile | Select-Object @{L = 'Image Profile'; E = {$_.Name}}, Vendor, @{L = 'Installation Date'; E = {$installdate.InstallDate}}
                                        $SecurityProfile | Table -Name "$VMHost Image Profile" -ColumnWidths 50, 25, 25 
                                    }
                                    #endregion ESXi Host Image Profile Information

                                    #region ESXi Host Time Configuration
                                    Section -Style Heading5 'Time Configuration' {
                                        $VMHostTimeSettingsHash = @{
                                            NtpServer = @($VMHost | Get-VMHostNtpServer) -join ", "
                                            Timezone = $VMHost.timezone
                                            NtpService = ($VMHost | Get-VMHostService | Where-Object {$_.key -eq 'ntpd'}).Running
                                        }
                                        $VMHostTimeSettings = $VMHostTimeSettingsHash | Select-Object @{L = 'Time Zone'; E = {$_.Timezone}}, @{L = 'NTP Service Running'; E = {$_.NtpService}}, @{L = 'NTP Server(s)'; E = {$_.NtpServer}}
                                        if ($Healthcheck.VMHost.TimeConfig) {
                                            $VMHostTimeSettings | Where-Object {$_.'NTP Service Running' -eq $False} | Set-Style -Style Critical -Property 'NTP Service Running'
                                        }
                                        $VMHostTimeSettings | Table -Name "$VMHost Time Configuration" -ColumnWidths 30, 30, 40
                                    }
                                    #endregion ESXi Host Time Configuration

                                    #region ESXi Host Syslog Configuration
                                    $SyslogConfig = $VMHost | Get-VMHostSysLogServer
                                    if ($SyslogConfig) {
                                        Section -Style Heading5 'Syslog Configuration' {
                                            ### TODO: Syslog Rotate & Size, Log Directory (Adv Settings)
                                            $SyslogConfig = $SyslogConfig | Select-Object @{L = 'SysLog Server'; E = {$_.Host}}, Port
                                            $SyslogConfig | Table -Name "$VMHost Syslog Configuration" -ColumnWidths 50, 50 
                                        }
                                    }
                                    #endregion ESXi Host Syslog Configuration

                                    #region ESXi Update Manager Baseline Information
                                    $VMHostBaselines = $VMHost | Get-PatchBaseline
                                    if ($VMHostBaselines) {
                                        Section -Style Heading5 'Update Manager Baselines' {
                                            $VMHostBaselines = $VMHostBaselines | Sort-Object Name | Select-Object Name, Description, @{L = 'Type'; E = {$_.BaselineType}}, @{L = 'Target Type'; E = {$_.TargetType}}, @{L = 'Last Update Time'; E = {$_.LastUpdateTime}}, @{L = '# of Patches'; E = {($_.CurrentPatches).count}}
                                            $VMHostBaselines | Table -Name "$VMHost Update Manager Baselines"
                                        }
                                    }
                                    #endregion ESXi Update Manager Baseline Information

                                    #region ESXi Update Manager Compliance Information
                                    $VMHostCompliance = $VMHost | Get-Compliance
                                    if ($VMHostCompliance) {
                                        Section -Style Heading5 'Update Manager Compliance' {
                                            $VMHostCompliance = $VMHostCompliance | Select-Object @{L = 'Baseline'; E = {($_.Baseline).Name}}, Status | Sort-Object 'Baseline'
                                            if ($Healthcheck.VMHost.VUMCompliance) {
                                                $VMHostCompliance | Where-Object {$_.Status -eq 'Unknown'} | Set-Style -Style Warning
                                                $VMHostCompliance | Where-Object {$_.Status -eq 'NotCompliant' -or $_.Status -eq 'Incompatible'} | Set-Style -Style Critical
                                            }
                                            $VMHostCompliance | Table -Name "$VMHost Update Manager Compliance" -ColumnWidths 75, 25
                                        }
                                    }
                                    #endregion ESXi Update Manager Compliance Information

                                    # Set InfoLevel to 5 to provide advanced system information for VMHosts
                                    if ($InfoLevel.VMHost -ge 5) {
                                        #region ESXi Host Advanced System Settings
                                        Section -Style Heading5 'Advanced System Settings' {
                                            $AdvSettings = $VMHost | Get-AdvancedSetting | Sort-Object Name | Select-Object Name, Value
                                            $AdvSettings | Table -Name "$VMHost Advanced System Settings" -ColumnWidths 50, 50 
                                        }
                                        #endregion ESXi Host Advanced System Settings

                                        #region ESXi Host Software VIBs
                                        Section -Style Heading5 'Software VIBs' {
                                            $esxcli = Get-ESXCli -VMHost $VMHost -V2 -Server $vCenter
                                            $VMHostVibs = $esxcli.software.vib.list.Invoke()
                                            $VMHostVibs = $VMHostVibs | Sort-Object InstallDate -Descending | Select-Object Name, ID, Version, Vendor, @{L = 'Acceptance Level'; E = {$_.AcceptanceLevel}}, 
                                            @{L = 'Creation Date'; E = {$_.CreationDate}}, @{L = 'Install Date'; E = {$_.InstallDate}}
                                            $VMHostVibs | Table -Name "$VMHost Software VIBs" -ColumnWidths 10, 25, 20, 10, 15, 10, 10
                                        }
                                        #endregion ESXi Host Software VIBs
                                    }
                                }
                                #endregion ESXi Host System Section

                                #region ESXi Host Storage Section
                                Section -Style Heading4 'Storage' {
                                    Paragraph ("The following section provides information on the host " +
                                        "storage configuration of $VMHost.")
                
                                    #region ESXi Host Datastore Specifications
                                    Section -Style Heading5 'Datastores' {
                                        $VMHostDS = $VMHost | Get-Datastore | Sort-Object Name | Select-Object Name, Type, @{L = 'Version'; E = {$_.FileSystemVersion}}, 
                                        @{L = '# of VMs'; E = {(($_ | Get-VM).count)}}, @{L = 'Total Capacity GB'; E = {[math]::Round($_.CapacityGB, 2)}}, 
                                        @{L = 'Used Capacity GB'; E = {[math]::Round((($_.CapacityGB) - ($_.FreeSpaceGB)), 2)}}, @{L = 'Free Space GB'; E = {[math]::Round($_.FreeSpaceGB, 2)}}, 
                                        @{L = '% Used'; E = {[math]::Round((100 - (($_.FreeSpaceGB) / ($_.CapacityGB) * 100)), 2)}}          
                                        if ($Healthcheck.Datastore.CapacityUtilization) {
                                            $VMHostDS | Where-Object {$_.'% Used' -ge 90} | Set-Style -Style Critical
                                            $VMHostDS | Where-Object {$_.'% Used' -ge 75 -and $_.'% Used' -lt 90} | Set-Style -Style Warning
                                        }
                                        $VMHostDS | Table -Name "$VMHost Datastores" #-ColumnWidths 20,10,10,10,10,10,10,10,10
                                    }
                                    #endregion ESXi Host Datastore Specifications
                
                                    #region ESXi Host Storage Adapater Information
                                    $VMHostHba = $VMHost | Get-VMHostHba | Where-Object {$_.type -eq 'FibreChannel' -or $_.type -eq 'iSCSI' }
                                    if ($VMHostHba) {
                                        Section -Style Heading5 'Storage Adapters' {
                                            $VMHostHbaFC = $VMHost | Get-VMHostHba -Type FibreChannel
                                            if ($VMHostHbaFC) {
                                                Paragraph ("The following table details the fibre channel " +
                                                    "storage adapters for $VMHost.")
                                                Blankline
                                                $VMHostHbaFC = $VMHost | Get-VMHostHba -Type FibreChannel | Sort-Object Device | Select-Object Device, Type, Model, Driver, 
                                                @{L = 'Node WWN'; E = {([String]::Format("{0:X}", $_.NodeWorldWideName) -split "(\w{2})" | Where-Object {$_ -ne ""}) -join ":" }}, 
                                                @{L = 'Port WWN'; E = {([String]::Format("{0:X}", $_.PortWorldWideName) -split "(\w{2})" | Where-Object {$_ -ne ""}) -join ":" }}, speed, status
                                                $VMHostHbaFC | Table -Name "$VMHost FC Storage Adapters"
                                            }

                                            $VMHostHbaISCSI = $VMHost | Get-VMHostHba -Type iSCSI
                                            if ($VMHostHbaISCSI) {
                                                Paragraph ("The following table details the iSCSI storage " +
                                                    "adapters for $VMHost.")
                                                Blankline
                                                $VMHostHbaISCSI = $VMHost | Get-VMHostHba -Type iSCSI | Sort-Object Device | Select-Object Device, @{L = 'iSCSI Name'; E = {$_.IScsiName}}, Model, Driver, @{L = 'Speed'; E = {$_.CurrentSpeedMb}}, status
                                                $VMHostHbaISCSI | Table -Name "$VMHost iSCSI Storage Adapters" -List -ColumnWidths 30, 70
                                            }
                                        }
                                    }
                                    #endregion ESXi Host Storage Adapater Information
                                }
                                #endregion ESXi Host Storage Section

                                #region ESXi Host Network Section
                                Section -Style Heading4 'Network' {
                                    Paragraph ("The following section provides information on the host " +
                                        "network configuration of $VMHost.")
                                    BlankLine
                                    #region ESXi Host Network Configuration
                                    $VMHostNetwork = $VMHost | Get-VMHostNetwork | Select-Object  VMHost, @{L = 'Virtual Switches'; E = {($_.VirtualSwitch | Sort-Object) -join ", "}}, @{L = 'VMKernel Adapters'; E = {($_.VirtualNic | Sort-Object) -join ", "}}, 
                                    @{L = 'Physical Adapters'; E = {($_.PhysicalNic | Sort-Object) -join ", "}}, @{L = 'VMKernel Gateway'; E = {$_.VMKernelGateway}}, @{L = 'IPv6 Enabled'; E = {$_.IPv6Enabled}}, 
                                    @{L = 'VMKernel IPv6 Gateway'; E = {$_.VMKernelV6Gateway}}, @{L = 'DNS Servers'; E = {($_.DnsAddress | Sort-Object) -join ", "}}, @{L = 'Host Name'; E = {$_.HostName}}, 
                                    @{L = 'Domain Name'; E = {$_.DomainName}}, @{L = 'Search Domain'; E = {($_.SearchDomain) -join ", "}}
                                    if ($Healthcheck.VMHost.IPv6Enabled) {
                                        $VMHostNetwork | Where-Object {$_.'IPv6 Enabled' -eq $false} | Set-Style -Style Warning -Property 'IPv6 Enabled'
                                    }
                                    $VMHostNetwork | Table -Name "$VMHost Host Network Configuration" -List -ColumnWidths 50, 50
                                    #endregion ESXi Host Network Configuration

                                    #region ESXi Host Physical Adapters
                                    Section -Style Heading5 'Physical Adapters' {
                                        Paragraph ("The following table details the physical network " +
                                            "adapters for $VMHost.")
                                        BlankLine

                                        $PhysicalAdapter = $VMHost | Get-VMHostNetworkAdapter -Physical | Select-Object @{L = 'Device Name'; E = {$_.DeviceName}}, @{L = 'MAC Address'; E = {$_.Mac}}, @{L = 'Bitrate/Second'; E = {$_.BitRatePerSec}}, 
                                        @{L = 'Full Duplex'; E = {$_.FullDuplex}}, @{L = 'Wake on LAN Support'; E = {$_.WakeOnLanSupported}}
                                        $PhysicalAdapter | Table -Name "$VMHost Physical Adapters" -ColumnWidths 20, 20, 20, 20, 20
                                    }
                                    #endregion ESXi Host Physical Adapters
                                    
                                    #region ESXi Host Cisco Discovery Protocol
                                    $CDPInfo = $VMHost | Get-VMHostNetworkAdapterCDP | Where-Object {$_.Connected -eq $true}
                                    if ($CDPInfo) {
                                        Section -Style Heading5 'Cisco Discovery Protocol' {
                                            $CDPInfo = $CDPInfo | Select-Object NIC, Connected, Switch, @{L = 'Hardware Platform'; E = {$_.HardwarePlatform}}, @{L = 'Port ID'; E = {$_.PortId}}
                                            $CDPInfo | Table -Name "$VMHost CDP Information" -ColumnWidths 20, 20, 20, 20, 20
                                        }
                                    }
                                    #endregion ESXi Host Cisco Discovery Protocol

                                    #region ESXi Host VMkernel Adapaters
                                    Section -Style Heading5 'VMkernel Adapters' {
                                        Paragraph "The following table details the VMkernel adapters for $VMHost"
                                        BlankLine

                                        $VMHostNetworkAdapter = $VMHost | Get-VMHostNetworkAdapter -VMKernel | Sort-Object DeviceName | Select-Object @{L = 'Device Name'; E = {$_.DeviceName}}, @{L = 'Network Label'; E = {$_.PortGroupName}}, @{L = 'MTU'; E = {$_.Mtu}}, 
                                        @{L = 'MAC Address'; E = {$_.Mac}}, @{L = 'IP Address'; E = {$_.IP}}, @{L = 'Subnet Mask'; E = {$_.SubnetMask}}, 
                                        @{L = 'vMotion Traffic'; E = {$_.vMotionEnabled}}, @{L = 'FT Logging'; E = {$_.FaultToleranceLoggingEnabled}}, 
                                        @{L = 'Management Traffic'; E = {$_.ManagementTrafficEnabled}}, @{L = 'vSAN Traffic'; E = {$_.VsanTrafficEnabled}}
                                        $VMHostNetworkAdapter | Table -Name "$VMHost VMkernel Adapters" -List -ColumnWidths 50, 50 
                                    }
                                    #endregion ESXi Host VMkernel Adapaters

                                    #region ESXi Host Virtual Switches
                                    $VSSwitches = $VMHost | Get-VirtualSwitch -Standard | Sort-Object Name
                                    if ($VSSwitches) {
                                        Section -Style Heading5 'Standard Virtual Switches' {
                                            Paragraph ("The following sections detail the standard virtual " +
                                                "switch configuration for $VMHost.")
                                            BlankLine
                                            $VSSGeneral = $VSSwitches | Get-NicTeamingPolicy | Select-Object @{L = 'Name'; E = {$_.VirtualSwitch}}, @{L = 'MTU'; E = {$_.VirtualSwitch.Mtu}}, @{L = 'Number of Ports'; E = {$_.VirtualSwitch.NumPorts}}, 
                                            @{L = 'Number of Ports Available'; E = {$_.VirtualSwitch.NumPortsAvailable}}, @{L = 'Load Balancing'; E = {$_.LoadBalancingPolicy}}, @{L = 'Failover Detection'; E = {$_.NetworkFailoverDetectionPolicy}}, 
                                            @{L = 'Notify Switches'; E = {$_.NotifySwitches}}, @{L = 'Failback Enabled'; E = {$_.FailbackEnabled}}, @{L = 'Active NICs'; E = {($_.ActiveNic) -join ", "}}, 
                                            @{L = 'Standby NICs'; E = {($_.StandbyNic) -join ", "}}, @{L = 'Unused NICs'; E = {($_.UnusedNic) -join ", "}}
                                            $VSSGeneral | Table -Name "$VMHost Standard Virtual Switches" -List -ColumnWidths 50, 50
                                        }
                                        #region ESXi Host Virtual Switch Security Policy
                                        $VSSSecurity = $VSSwitches | Get-SecurityPolicy
                                        if ($VSSSecurity) {
                                            Section -Style Heading5 'Virtual Switch Security Policy' {
                                                $VSSSecurity = $VSSSecurity | Select-Object @{L = 'vSwitch'; E = {$_.VirtualSwitch}}, @{L = 'MAC Address Changes'; E = {$_.MacChanges}}, @{L = 'Forged Transmits'; E = {$_.ForgedTransmits}}, 
                                                @{L = 'Promiscuous Mode'; E = {$_.AllowPromiscuous}} | Sort-Object vSwitch
                                                $VSSSecurity | Table -Name "$VMHost vSwitch Security Policy" 
                                            }
                                        }
                                        #endregion ESXi Host Virtual Switch Security Policy                  

                                        #region ESXi Host Virtual Switch NIC Teaming
                                        $VSSPortgroupNicTeaming = $VSSwitches | Get-NicTeamingPolicy
                                        if ($VSSPortgroupNicTeaming) {
                                            Section -Style Heading5 'Virtual Switch NIC Teaming' {
                                                $VSSPortgroupNicTeaming = $VSSPortgroupNicTeaming | Select-Object @{L = 'vSwitch'; E = {$_.VirtualSwitch}}, @{L = 'Load Balancing'; E = {$_.LoadBalancingPolicy}}, 
                                                @{L = 'Failover Detection'; E = {$_.NetworkFailoverDetectionPolicy}}, @{L = 'Notify Switches'; E = {$_.NotifySwitches}}, @{L = 'Failback Enabled'; E = {$_.FailbackEnabled}}, @{L = 'Active NICs'; E = {($_.ActiveNic) -join [Environment]::NewLine}}, 
                                                @{L = 'Standby NICs'; E = {($_.StandbyNic) -join [Environment]::NewLine}}, @{L = 'Unused NICs'; E = {($_.UnusedNic) -join [Environment]::NewLine}} | Sort-Object vSwitch
                                                $VSSPortgroupNicTeaming | Table -Name "$VMHost vSwitch NIC Teaming" #-ColumnWidths 12,16,12,12,12,12,12,12
                                            }
                                        }
                                        #endregion ESXi Host Virtual Switch NIC Teaming                       
                        
                                        #region ESXi Host Virtual Switch Port Groups
                                        $VSSPortgroups = $VSSwitches | Get-VirtualPortGroup -Standard 
                                        if ($VSSPortgroups) {
                                            Section -Style Heading5 'Virtual Port Groups' {
                                                $VSSPortgroups = $VSSPortgroups | Select-Object @{L = 'vSwitch'; E = {$_.VirtualSwitchName}}, @{L = 'Port Group'; E = {$_.Name}}, @{L = 'VLAN ID'; E = {$_.VLanId}}, @{L = '# of VMs'; E = {(($_ | Get-VM).count)}} | Sort-Object vSwitch, 'Port Group'
                                                $VSSPortgroups | Table -Name "$VMHost vSwitch Port Group Information" 
                                            }
                                        }
                                        #endregion ESXi Host Virtual Switch Port Groups                
                        
                                        #region ESXi Host Virtual Switch Port Group Security Poilicy
                                        $VSSPortgroupSecurity = $VSSwitches | Get-VirtualPortGroup | Get-SecurityPolicy 
                                        if ($VSSPortgroupSecurity) {
                                            Section -Style Heading5 'Virtual Port Group Security Policy' {
                                                $VSSPortgroupSecurity = $VSSPortgroupSecurity | Select-Object @{L = 'vSwitch'; E = {$_.virtualportgroup.virtualswitchname}}, @{L = 'Port Group'; E = {$_.VirtualPortGroup}}, @{L = 'MAC Changes'; E = {$_.MacChanges}}, 
                                                @{L = 'Forged Transmits'; E = {$_.ForgedTransmits}}, @{L = 'Promiscuous Mode'; E = {$_.AllowPromiscuous}} | Sort-Object vSwitch, 'Port Group'
                                                $VSSPortgroupSecurity | Table -Name "$VMHost vSwitch Port Group Security Policy" 
                                            }
                                        } 
                                        #endregion ESXi Host Virtual Switch Port Group Security Poilicy                 

                                        #region ESXi Host Virtual Switch Port Group NIC Teaming
                                        $VSSPortgroupNicTeaming = $VSSwitches | Get-VirtualPortGroup  | Get-NicTeamingPolicy 
                                        if ($VSSPortgroupNicTeaming) {
                                            Section -Style Heading5 'Virtual Port Group NIC Teaming' {
                                                $VSSPortgroupNicTeaming = $VSSPortgroupNicTeaming | Select-Object @{L = 'vSwitch'; E = {$_.virtualportgroup.virtualswitchname}}, @{L = 'Port Group'; E = {$_.VirtualPortGroup}}, @{L = 'Load Balancing'; E = {$_.LoadBalancingPolicy}}, 
                                                @{L = 'Failover Detection'; E = {$_.NetworkFailoverDetectionPolicy}}, @{L = 'Notify Switches'; E = {$_.NotifySwitches}}, @{L = 'Failback Enabled'; E = {$_.FailbackEnabled}}, @{L = 'Active NICs'; E = {($_.ActiveNic) -join [Environment]::NewLine}}, 
                                                @{L = 'Standby NICs'; E = {($_.StandbyNic) -join [Environment]::NewLine}}, @{L = 'Unused NICs'; E = {($_.UnusedNic) -join [Environment]::NewLine}} | Sort-Object vSwitch, 'Port Group'
                                                $VSSPortgroupNicTeaming | Table -Name "$VMHost vSwitch Port Group NIC Teaming" #-ColumnWidths 11,12,11,11,11,11,11,11,11
                                            }
                                        }  
                                        #endregion ESXi Host Virtual Switch Port Group NIC Teaming                      
                                    }
                                    #endregion ESXi Host Standard Virtual Switches
                                }                
                                #endregion ESXi Host Network Configuration

                                #region ESXi Host Security Section
                                Section -Style Heading4 'Security' {
                                    Paragraph ("The following section provides information on the host " +
                                        "security configuration of $VMHost.")
                                    
                                    #region ESXi Host Lockdown Mode
                                    Section -Style Heading5 'Lockdown Mode' {
                                        $LockDownMode = $VMHost | Get-View | Select-Object @{L = 'Lockdown Mode'; E = {$_.Config.AdminDisabled}}
                                        $LockDownMode | Table -Name "$VMHost Lockdown Mode" -List -ColumnWidths 50, 50
                                    }
                                    #endregion ESXi Host Lockdown Mode

                                    #region ESXi Host Services
                                    Section -Style Heading5 'Services' {
                                        $Services = $VMHost | Get-VMHostService | Sort-Object Key | Select-Object @{L = 'Name'; E = {$_.Key}}, Label, Policy, Running, Required
                                        if ($Healthcheck.VMHost.Services) {
                                            $Services | Where-Object {$_.'Name' -eq 'TSM-SSH' -and $_.Running} | Set-Style -Style Warning
                                            $Services | Where-Object {$_.'Name' -eq 'TSM' -and $_.Running} | Set-Style -Style Warning
                                            $Services | Where-Object {$_.'Name' -eq 'ntpd' -and $_.Running -eq $False} | Set-Style -Style Critical
                                        }
                                        $Services | Table -Name "$VMHost Services" 
                                    }
                                    #endregion ESXi Host Services

                                    if ($InfoLevel.VMHost -ge 4) {
                                        #region ESXi Host Firewall
                                        Section -Style Heading5 'Firewall' {
                                            $Firewall = $VMHost | Get-VMHostFirewallException | Sort-Object Name | Select-Object Name, Enabled, @{L = 'Incoming Ports'; E = {$_.IncomingPorts}}, @{L = 'Outgoing Ports'; E = {$_.OutgoingPorts}}, Protocols, @{L = 'Service Running'; E = {$_.ServiceRunning}}
                                            $Firewall | Table -Name "$VMHost Firewall Configuration" 
                                        }
                                        #endregion ESXi Host Firewall
                                    }
                    
                                    #region ESXi Host Authentication
                                    $AuthServices = $VMHost | Get-VMHostAuthentication
                                    if ($AuthServices.DomainMembershipStatus) {
                                        Section -Style Heading5 'Authentication Services' {
                                            $AuthServices = $AuthServices | Select-Object Domain, @{L = 'Domain Membership'; E = {$_.DomainMembershipStatus}}, @{L = 'Trusted Domains'; E = {$_.TrustedDomains}}
                                            $AuthServices | Table -Name "$VMHost Authentication Services" -ColumnWidths 25, 25, 50 
                                        }    
                                    }
                                    #endregion ESXi Host Authentication
                                }
                                #endregion ESXi Host Security Section

                                #region ESXi Host Virtual Machines Section
                                if ($InfoLevel.VMHost -ge 4) {
                                    $VMHostVM = $VMHost | Get-VM
                                    if ($VMHostVM) {
                                        Section -Style Heading4 'Virtual Machines' {
                                            Paragraph ("The following section provides information on the " +
                                                "virtual machine settings for $VMHost.")
                                            Blankline
                                            #region ESXi Host Virtual Machine Summary Information
                                            $VMHostVM = $VMHostVM | Sort-Object Name | Select-Object Name, @{L = 'Power State'; E = {$_.powerstate}}, @{L = 'CPUs'; E = {$_.NumCpu}}, @{L = 'Cores per Socket'; E = {$_.CoresPerSocket}}, @{L = 'Memory GB'; E = {[math]::Round(($_.memoryGB), 2)}}, @{L = 'Provisioned GB'; E = {[math]::Round(($_.ProvisionedSpaceGB), 2)}}, 
                                            @{L = 'Used GB'; E = {[math]::Round(($_.UsedSpaceGB), 2)}}, @{L = 'HW Version'; E = {$_.version}}, @{L = 'VM Tools Status'; E = {$_.ExtensionData.Guest.ToolsStatus}}
                                            if ($Healthcheck.VM.VMTools) {
                                                $VMHostVM | Where-Object {$_.'VM Tools Status' -eq 'toolsNotInstalled' -or $_.'VM Tools Status' -eq 'toolsOld'} | Set-Style -Style Warning -Property 'VM Tools Status'
                                            }
                                            $VMHostVM | Table -Name "$VMHost VM Summary" #-ColumnWidths 15,10,10,10,10,10,10,10,15
                                            #endregion ESXi Host Virtual Machine Summary Information

                                            #region ESXi Host VM Startup/Shutdown Information
                                            $VMStartPolicy = $VMHost | Get-VMStartPolicy | Where-Object {$_.StartAction -ne 'None'}
                                            if ($VMStartPolicy) {
                                                Section -Style Heading5 'VM Startup/Shutdown' {
                                                    $VMStartPolicies = $VMStartPolicy | Select-Object @{L = 'VM Name'; E = {$_.VirtualMachineName}}, @{L = 'Start Action'; E = {$_.StartAction}}, 
                                                    @{L = 'Start Delay'; E = {$_.StartDelay}}, @{L = 'Start Order'; E = {$_.StartOrder}}, @{L = 'Stop Action'; E = {$_.StopAction}}, @{L = 'Stop Delay'; E = {$_.StopDelay}}, 
                                                    @{L = 'Wait for Heartbeat'; E = {$_.WaitForHeartbeat}}
                                                    $VMStartPolicies | Table -Name "$VMHost VM Startup/Shutdown Policy" 
                                                }
                                            }
                                            #endregion ESXi Host VM Startup/Shutdown Information
                                        }
                                    }
                                }
                                #endregion ESXi Host Virtual Machines Section
                            }
                        }
                    }
                    #endregion ESXi Host Detailed Information
                }
            }
        }
        #endregion ESXi VMHost Section 

        #region Distributed Switch Section
        if ($InfoLevel.Network -ge 1) {
            # Create Distributed Virtual Switch Section if they exist
            $Script:VDSwitches = Get-VDSwitch -Server $vCenter
            if ($VDSwitches) {
                Section -Style Heading2 'Distributed Virtual Switches' {
                    Paragraph ("The following section provides information on the Distributed Virtual " +
                        "Switches managed by vCenter Server $vCenterServerName.")
                    BlankLine
                    #region Distributed Virtual Switch Informative Information
                    if ($InfoLevel.Network -eq 2) {
                        $VDSSummary = foreach ($VDSwitch in $VDSwitches) {
                            [PSCustomObject] @{
                                'VDSwitch' = $VDSwitch.Name
                                'Datacenter' = $VDSwitch.Datacenter
                                'Manufacturer' = $VDSwitch.Vendor
                                'Version' = $VDSwitch.Version
                                '# of Uplinks' = $VDSwitch.NumUplinkPorts
                                '# of Ports' = $VDSwitch.NumPorts 
                                '# of Hosts' = ($VDSwitch | Get-VMHost).Count
                                '# of VMs' = ($VDSwitch | Get-VM).Count
                            }
                        }    
                        $VDSSummary | Table -Name 'Distributed Virtual Switch Summary'
                    }    
                    #endregion Distributed Virtual Switch Informative Information

                    if ($InfoLevel.Network -ge 3) {
                        #region Distributed Virtual Switch Detailed Information
                        ## TODO: LACP, NetFlow, NIOC
                        foreach ($VDS in ($VDSwitches)) {
                            Section -Style Heading3 $VDS {
                                #region Distributed Virtual Switch General Properties  
                                Section -Style Heading4 'General Properties' {
                                    $VDSwitchSpecs = [PSCustomObject] @{
                                        'Name' = $VDS.Name
                                        'ID' = $VDS.Id
                                        'Datacenter' = $VDS.Datacenter
                                        'Manufacturer' = $VDS.Vendor
                                        'Version' = $VDS.Version
                                        'Number of Uplinks' = $VDS.NumUplinkPorts 
                                        'Number of Ports' = $VDS.NumPorts
                                        'Number of Port Groups' = ($VDS.ExtensionData.Summary.PortGroupName).Count 
                                        'Number of Hosts' = ($VDS | Get-VMHost).Count
                                        'Number of VMs' = ($VDS.ExtensionData.Summary.VM).Count 
                                        'MTU' = $VDS.Mtu
                                        'Network I/O Control Enabled' = $VDS.ExtensionData.Config.NetworkResourceManagementEnabled 
                                        'Discovery Protocol' = $VDS.LinkDiscoveryProtocol
                                        'Discovery Protocol Operation' = $VDS.LinkDiscoveryProtocolOperation
                                    }

                                    if ($InfoLevel.Network -ge 3) {
                                        $VDSwitchSpecs | ForEach-Object {
                                            $VDSwitchHosts = $VDS | Get-VMHost | Sort-Object Name
                                            Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Hosts' -Value ($VDSwitchHosts.Name -join ", ")
                                            $VDSwitchVMs = $VDS | Get-VM | Sort-Object 
                                            Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Virtual Machines' -Value ($VDSwitchVMs.Name -join ", ")
                                        }
                                    }
                                    $VDSwitchSpecs | Table -Name "$VDS General Properties" -List -ColumnWidths 50, 50 
                                }
                                #endregion Distributed Virtual Switch General Properties

                                #region Distributed Virtual Switch Uplinks
                                $VdsUplinks = $VDS | Get-VDPortgroup | Where-Object {$_.IsUplink -eq $true} | Get-VDPort | Sort-Object Switch, ProxyHost, Name
                                if ($VdsUplinks) {
                                    Section -Style Heading4 'Uplinks' {
                                        $VdsUplinkSpecs = foreach ($VdsUplink in $VdsUplinks) {
                                            [PSCustomObject] @{
                                                'VDSwitch' = $VdsUplink.Switch
                                                'VM Host' = $VdsUplink.ProxyHost
                                                'Uplink Name' = $VdsUplink.Name
                                                'Physical Network Adapter' = $VdsUplink.ConnectedEntity
                                                'Uplink Port Group' = $VdsUplink.Portgroup
                                            }
                                        }
                                        $VdsUplinkSpecs | Table -Name "$VDS Uplinks"
                                    }
                                }
                                #endregion Distributed Virtual Switch Uplinks               
                                
                                #region Distributed Virtual Switch Security
                                Section -Style Heading4 'Security' {
                                    $VDSecurityPolicy = $VDS | Get-VDSecurityPolicy
                                    $VDSecurityPolicySpecs = [PSCustomObject] @{
                                        'VDSwitch' = $VDSecurityPolicy.VDSwitch
                                        'Allow Promiscuous' = $VDSecurityPolicy.AllowPromiscuous
                                        'Forged Transmits' = $VDSecurityPolicy.ForgedTransmits
                                        'MAC Address Changes' = $VDSecurityPolicy.MacChanges
                                    }
                                    $VDSecurityPolicySpecs | Table -Name "$VDS Security" 
                                }
                                #endregion Distributed Virtual Switch Security

                                #region Distributed Virtual Switch Traffic Shaping
                                Section -Style Heading4 'Traffic Shaping' {
                                    $VDSTrafficShaping = $VDS | Get-VDTrafficShapingPolicy -Direction Out
                                    [Array]$VDSTrafficShaping += $VDS | Get-VDTrafficShapingPolicy -Direction In
                                    $VDSTrafficShapingSpecs = foreach ($VDSTrafficShape in $VDSTrafficShaping) {
                                        [PSCustomObject] @{
                                            'VDSwitch' = $VDSTrafficShape.VDSwitch
                                            'Direction' = $VDSTrafficShape.Direction
                                            'Enabled' = $VDSTrafficShape.Enabled
                                            'Average Bandwidth (kbit/s)' = $VDSTrafficShape.AverageBandwidth
                                            'Peak Bandwidth (kbit/s)' = $VDSTrafficShape.PeakBandwidth
                                            'Burst Size (KB)' = $VDSTrafficShape.BurstSize
                                        }
                                    }
                                    $VDSTrafficShapingSpecs | Sort-Object Direction | Table -Name "$VDS Traffic Shaping"
                                }
                                #endregion Distributed Virtual Switch Traffic Shaping

                                #region Distributed Virtual Switch Port Groups
                                Section -Style Heading4 'Port Groups' {
                                    $VDSPortgroups = $VDS | Get-VDPortgroup | Select-Object VDSwitch, @{L = 'Port Group'; E = {$_.Name}}, Datacenter, @{L = 'VLAN Configuration'; E = {$_.VlanConfiguration}}, @{L = 'Port Binding'; E = {$_.PortBinding}}, @{L = '# of Ports'; E = {$_.NumPorts}} | Sort-Object VDSwitch, 'Port Group'
                                    $VDSPortgroups | Table -Name "$VDS Port Group Information" 
                                }
                                #endregion Distributed Virtual Switch Port Groups

                                #region Distributed Virtual Switch Port Group Security
                                Section -Style Heading5 "Port Group Security" {
                                    $VDSPortgroupSecurity = $VDS | Get-VDPortgroup | Get-VDSecurityPolicy | Select-Object @{L = 'VDSwitch'; E = {($VDS.Name)}} , @{L = 'Port Group'; E = {$_.VDPortgroup}}, @{L = 'Allow Promiscuous'; E = {$_.AllowPromiscuous}}, @{L = 'Forged Transmits'; E = {$_.ForgedTransmits}}, @{L = 'MAC Address Changes'; E = {$_.MacChanges}} | Sort-Object VDSwitch, 'Port Group'
                                    $VDSPortgroupSecurity | Table -Name "$VDS Port Group Security"
                                }
                                #endregion Distributed Virtual Switch Port Group Security
                
                                #region Distributed Virtual Switch Port Group NIC Teaming
                                Section -Style Heading5 "Port Group NIC Teaming" {
                                    $VDSPortgroupNICTeaming = $VDS | Get-VDPortgroup | Get-VDUplinkTeamingPolicy | Select-Object @{L = 'VDSwitch'; E = {($VDS.Name)}} , @{L = 'Port Group'; E = {$_.VDPortgroup}}, @{L = 'Load Balancing'; E = {$_.LoadBalancingPolicy}}, @{L = 'Failover Detection'; E = {$_.FailoverDetectionPolicy}}, 
                                    @{L = 'Notify Switches'; E = {$_.NotifySwitches}}, @{L = 'Failback Enabled'; E = {$_.EnableFailback}}, @{L = 'Active Uplinks'; E = {($_.ActiveUplinkPort) -join [Environment]::NewLine}}, @{L = 'Standby Uplinks'; E = {($_.StandbyUplinkPort) -join [Environment]::NewLine}}, @{L = 'Unused Uplinks'; E = {@($_.UnusedUplinkPort) -join [Environment]::NewLine}} | Sort-Object VDSwitch, 'Port Group'
                                    $VDSPortgroupNICTeaming | Table -Name "$VDS Port Group NIC Teaming" #-ColumnWidths 12,11,11,11,11,11,11,11,11
                                }
                                #endregion Distributed Virtual Switch Port Group NIC Teaming

                                #region Distributed Virtual Switch Private VLANs
                                $VDSPvlan = $VDS | Get-VDSwitchPrivateVLAN | Select-Object @{L = 'Primary VLAN ID'; E = {$_.PrimaryVlanId}}, @{L = 'Private VLAN Type'; E = {$_.PrivateVlanType}}, @{L = 'Secondary VLAN ID'; E = {$_.SecondaryVlanId}}
                                if ($VDSPvlan) {
                                    Section -Style Heading4 'Private VLANs' {
                                        $VDSPvlan | Table -Name "$VDS Private VLANs"
                                    }
                                }
                                #endregion Distributed Virtual Switch Private VLANs            
                            }
                        }
                        #endregion Distributed Virtual Switch Detailed Information
                    }
                }
            }
        }
        #endregion Distributed Switch Section

        #region vSAN Section
        if ($InfoLevel.Vsan -ge 1) {
            $Script:VsanClusters = Get-VsanClusterConfiguration -Server $vCenter | Where-Object {$_.vsanenabled -eq $true} | Sort-Object Name
            if ($VsanClusters) {
                Section -Style Heading2 'vSAN' {
                    Paragraph ("The following section provides information on the vSAN managed " +
                        "by vCenter Server $vCenterServerName.")
                    BlankLine
                    #region vSAN Cluster Informative Information
                    if ($InfoLevel.Vsan -eq 2) {
                        $VsanClusterSummary = foreach ($VsanCluster in $VsanClusters) {
                            [PSCustomObject] @{
                                'Name' = $VsanCluster.Name
                                'vSAN Enabled' = $VsanCluster.VsanEnabled
                                'Stretched Cluster Enabled' = $VsanCluster.StretchedClusterEnabled
                                'Space Efficiency Enabled' = $VsanCluster.SpaceEfficiencyEnabled
                                'Encryption Enabled' = $VsanCluster.EncryptionEnabled
                                'Health Check Enabled' = $VsanCluster.HealthCheckEnabled
                            }
                        }   
                        $VsanClusterSummary | Table -Name 'vSAN Cluster Summary'
                        #endregion vSAN Cluster Informative Information

                        #region vSAN Cluster Detailed Information
                        if ($InfoLevel.Vsan -ge 3) {
                            foreach ($VsanCluster in $VsanClusters) {
                                Section -Style Heading3 $VsanCluster.Name {
                                    $VsanDiskGroup = Get-VsanDiskGroup -Cluster $VsanCluster.Name
                                    $NumVsanDiskGroup = $VsanDiskGroup.Count
                                    $VsanDisk = Get-vSanDisk -VsanDiskGroup $VsanDiskGroup
                                    $VsanDiskFormat = $VsanDisk.DiskFormatVersion | Select-Object -First 1 -Unique
                                    $NumVsanDisk = ($VsanDisk | Where-Object {$_.IsSsd -eq $true}).Count
                                    if ($VsanDisk.IsSsd -eq $true -and $VsanDisk.IsCacheDisk -eq $false) {
                                        $VsanClusterType = "All-Flash"
                                    } else {
                                        $VsanClusterType = "Hybrid"
                                    }
                                    $VsanClusterSpecs = [PSCustomObject] @{
                                        'Name' = $VsanCluster.Name
                                        'ID' = $VsanCluster.Id
                                        'Type' = $VsanClusterType
                                        'Stretched Cluster' = $VsanCluster.StretchedClusterEnabled
                                        'Number of Hosts' = $VsanCluster.Cluster.ExtensionData.Host.Count
                                        'Disk Format Version' = $VsanDiskFormat
                                        'Total Number of Disks' = $NumVsanDisk
                                        'Total Number of Disk Groups' = $NumVsanDiskGroup
                                        'Disk Claim Mode' = $VsanCluster.VsanDiskClaimMode
                                        'Deduplication & Compression' = $VsanCluster.SpaceEfficiencyEnabled
                                        'Encryption Enabled' = $VsanCluster.EncryptionEnabled
                                        'Health Check Enabled' = $VsanCluster.HealthCheckEnabled
                                        'HCL Last Updated' = $VsanCluster.TimeOfHclUpdate
                                    }
                                    #endregion vSAN Cluster Detailed Information

                                    #region vSAN Cluster Adv Detailed Information
                                    if ($InfoLevel.Vsan -ge 4) {
                                        Add-Member -InputObject $VsanClusterSpecs -MemberType NoteProperty -Name 'Hosts' -Value (($VsanDiskGroup.VMHost | Sort-Object Name) -join ", ")
                                    }
                                    #endregion vSAN Cluster Adv Detailed Information

                                    $VsanClusterSpecs | Table -Name "$VsanCluster.Name vSAN Configuration" -List -ColumnWidths 50, 50
                                }  
                            }      
                        }
                    }
                }
            }
            #endregion vSAN Section

            #region Datastore Section
            if ($InfoLevel.Datastore -ge 1) {
                $Script:Datastores = Get-Datastore -Server $vCenter | Where-Object {$_.Accessible -eq $true} | Sort-Object Name
                if ($Datastores) {
                    Section -Style Heading2 'Datastores' {
                        Paragraph ("The following section provides information on datastores managed " +
                            "by vCenter Server $vCenterServerName.")
                        BlankLine

                        #region Datastore Infomative Information
                        if ($InfoLevel.Datastore -eq 2) {
                            $DatastoreSummary = foreach ($Datastore in $Datastores) {
                                [PSCustomObject] @{
                                    'Name' = $Datastore.Name
                                    'Type' = $Datastore.Type
                                    '# of Hosts' = $Datastore.ExtensionData.Host.Count
                                    '# of VMs' = $Datastore.ExtensionData.VM.Count
                                    'Total Capacity GB' = [math]::Round($Datastore.CapacityGB, 2)
                                    'Used Capacity GB' = [math]::Round(
                                        (($Datastore.CapacityGB) - ($Datastore.FreeSpaceGB)), 2
                                    )
                                    'Free Space GB' = [math]::Round($Datastore.FreeSpaceGB, 2)
                                    '% Used' = [math]::Round(
                                        (100 - (($Datastore.FreeSpaceGB) / ($Datastore.CapacityGB) * 100)), 2
                                    )
                                }
                            }
                            if ($Healthcheck.Datastore.CapacityUtilization) {
                                $DatastoreSummary | Where-Object {$_.'% Used' -ge 90} | Set-Style -Style Critical -Property '% Used'
                                $DatastoreSummary | Where-Object {$_.'% Used' -ge 75 -and 
                                    $_.'% Used' -lt 90} | Set-Style -Style Warning -Property '% Used'
                            }
                            $DatastoreSummary | Sort-Object Name | Table -Name 'Datastore Summary'
                        }
                        #endregion Datastore Informative Information
                    
                        #region Datastore Detailed Information
                        if ($InfoLevel.Datastore -ge 3) {
                            foreach ($Datastore in $Datastores) {
                                Section -Style Heading3 $Datastore.Name {                                
                                    $DatastoreSpecs = [PSCustomObject] @{
                                        'Name' = $Datastore.Name
                                        'ID' = $Datastore.Id
                                        'Datacenter' = $Datastore.Datacenter
                                        'Type' = $Datastore.Type
                                        'Version' = $Datastore.FileSystemVersion
                                        'State' = $Datastore.State
                                        'Number of Hosts' = $Datastore.ExtensionData.Host.Count
                                        'Number of VMs' = $Datastore.ExtensionData.VM.Count
                                        'SIOC Enabled' = $Datastore.StorageIOControlEnabled
                                        'Congestion Threshold (ms)' = $Datastore.CongestionThresholdMillisecond
                                        'Total Capacity' = "$([math]::Round($Datastore.CapacityGB, 2)) GB"
                                        'Used Capacity' = "$([math]::Round((($Datastore.CapacityGB) - 
                                                                        ($Datastore.FreeSpaceGB)), 2)) GB"
                                        'Free Space' = "$([math]::Round($Datastore.FreeSpaceGB, 2)) GB"
                                        '% Used' = [math]::Round(
                                            (100 - (($Datastore.FreeSpaceGB) / ($Datastore.CapacityGB) * 100)), 2
                                        )
                                    }
                                    if ($Healthcheck.Datastore.CapacityUtilization) {
                                        $DatastoreSpecs | Where-Object {$_.'% Used' -ge 90} | Set-Style -Style Critical -Property '% Used'
                                        $DatastoreSpecs | Where-Object {$_.'% Used' -ge 75 -and 
                                            $_.'% Used' -lt 90} | Set-Style -Style Warning -Property '% Used'
                                    }
                                    # Set InfoLevel to 4 or above to provide information for associated VMHosts & VMs
                                    if ($InfoLevel.Datastore -ge 4) {
                                        $MemberProps = @{
                                            'InputObject' = $DatastoreSpecs
                                            'MemberType' = 'NoteProperty'
                                        }
                                        $DatastoreHosts = foreach ($DatastoreHost in $Datastore.ExtensionData.Host.Key) {
                                            $VMHostLookup."$($DatastoreHost.Type)-$($DatastoreHost.Value)"
                                        }
                                        Add-Member @MemberProps -Name 'Hosts' -Value (($DatastoreHosts | Sort-Object) -join ', ')
                                        $DatastoreVMs = foreach ($DatastoreVM in $Datastore.ExtensionData.VM) {
                                            $VMLookup."$($DatastoreVM.Type)-$($DatastoreVM.Value)"
                                        }
                                        Add-Member @MemberProps -Name 'Virtual Machines' -Value (($DatastoreVMs | Sort-Object) -join ', ')
                                    }
                                    $TableProps = @{
                                        'Name' = 'Datastore Specifications'
                                        'List' = $true
                                        'ColumnWidths' = 50, 50
                                    }
                                    $DatastoreSpecs | Sort-Object Datacenter, Name | Table @TableProps

                                    # Get VMFS volumes. Ignore local SCSILuns.
                                    if (($Datastore.Type -eq 'VMFS') -and
                                        ($Datastore.ExtensionData.Info.Vmfs.Local -eq $false)) {
                                        Section -Style Heading4 'SCSI LUN Information' {
                                            $ScsiLuns = foreach ($DatastoreHost in $Datastore.ExtensionData.Host.Key) {
                                                $DiskName = $Datastore.ExtensionData.Info.Vmfs.Extent.DiskName
                                                $ScsiDeviceDetailProps = @{
                                                    'VMHosts' = $VMHosts
                                                    'VMHostMoRef' = "$($DatastoreHost.Type)-$($DatastoreHost.Value)"
                                                    'DatastoreDiskName' = $DiskName
                                                }
                                                $ScsiDeviceDetail = Get-ScsiDeviceDetail @ScsiDeviceDetailProps

                                                [PSCustomObject] @{
                                                    'Host' = $VMHostLookup."$($DatastoreHost.Type)-$($DatastoreHost.Value)"
                                                    'Canonical Name' = $DiskName
                                                    'Capacity GB' = $ScsiDeviceDetail.CapacityGB
                                                    'Vendor' = $ScsiDeviceDetail.Vendor
                                                    'Model' = $ScsiDeviceDetail.Model
                                                    'Is SSD' = $ScsiDeviceDetail.Ssd
                                                    'Multipath Policy' = $ScsiDeviceDetail.MultipathPolicy
                                                }
                                            }
                                            $ScsiLuns | Sort-Object Host | Table -Name 'SCSI LUN Information'
                                        }
                                    }
                                }
                            }
                        }
                        #endregion Datastore Detailed Information
                    }
                }
            }
            #endregion Datastore Section
                    
            #region Datastore Clusters
            if ($InfoLevel.DSCluster -ge 1) {
                $DSClusters = Get-DatastoreCluster -Server $vCenter
                if ($DSClusters) {
                    Section -Style Heading2 'Datastore Clusters' {
                        Paragraph ("The following section provides information on datastore clusters " +
                            "managed by vCenter Server $vCenterServerName.")
                        BlankLine

                        #region Datastore Cluster Informative Information
                        if ($InfoLevel.DSCluster -eq 2) {
                            $DSClusterSummary = foreach ($DSCluster in $DSClusters) {
                                [PSCustomObject] @{
                                    'Name' = $DSCluster.Name
                                    'SDRS Automation Level' = $DSCluster.SdrsAutomationLevel
                                    'Space Utilization Threshold %' = $DSCluster.SpaceUtilizationThresholdPercent
                                    'I/O Load Balance Enabled' = $DSCluster.IOLoadBalanceEnabled
                                    'I/O Latency Threshold (ms)' = $DSCluster.IOLatencyThresholdMillisecond
                                    'Capacity GB' = [math]::Round($DSCluster.CapacityGB, 2)
                                    'FreeSpace GB' = [math]::Round($DSCluster.FreeSpaceGB, 2)
                                    '% Used' = [math]::Round(
                                        (100 - (($DSCluster.FreeSpaceGB) / ($DSCluster.CapacityGB) * 100)), 2
                                    )
                                }
                            }
                            if ($Healthcheck.DSCluster.CapacityUtilization) {
                                $DSClusterSummary | Where-Object {$_.'% Used' -ge 90} | Set-Style -Style Critical -Property '% Used'
                                $DSClusterSummary | Where-Object {$_.'% Used' -ge 75 -and $_.'% Used' -lt 90} | Set-Style -Style Critical -Property '% Used'
                            }
                            if ($Healthcheck.DSCluster.SDRSAutomationLevel) {
                                $DSClusterSummary | Where-Object {$_.'SDRS Automation Level' -ne 
                                    $Healthcheck.DSCluster.SDRSAutomationLevelSetting} | Set-Style -Style Warning -Property 'SDRS Automation Level'
                            }
                            $DSClusterSummary | Sort-Object Name | Table -Name 'Datastore Cluster Summary'
                        }
                        #endregion Datastore Cluster Informative Information

                        if ($InfoLevel.DSCluster -ge 3) {
                            #region Datastore Cluster Detailed Information
                            foreach ($DSCluster in $DSClusters) {
                                ## TODO: Space Load Balance Config, IO Load Balance Config, Rules
                                Section -Style Heading3 $DSCluster.Name {
                                    Paragraph ("The following table details the configuration " +
                                        "for datastore cluster $DSCluster.")
                                    BlankLine

                                    $DSClusterSummary = [PSCustomObject] @{
                                        'Name' = $DSCluster.Name
                                        'ID' = $DSCluster.Id
                                        'SDRS Automation Level' = $DSCluster.SdrsAutomationLevel
                                        'Space Utilization Threshold %' = $DSCluster.SpaceUtilizationThresholdPercent
                                        'I/O Load Balance Enabled' = $DSCluster.IOLoadBalanceEnabled
                                        'I/O Latency Threshold (ms)' = $DSCluster.IOLatencyThresholdMillisecond
                                        'Capacity GB' = [math]::Round($DSCluster.CapacityGB, 2)
                                        'FreeSpace GB' = [math]::Round($DSCluster.FreeSpaceGB, 2)
                                        '% Used' = [math]::Round(
                                            (100 - (($DSCluster.FreeSpaceGB) / ($DSCluster.CapacityGB) * 100)), 2
                                        )
                                    }
                                
                                    if ($Healthcheck.DSCluster.CapacityUtilization) {
                                        $DSClusterSummary | Where-Object {$_.'% Used' -ge 90} | Set-Style -Style Critical -Property '% Used'
                                        $DSClusterSummary | Where-Object {$_.'% Used' -ge 75 -and $_.'% Used' -lt 90} | Set-Style -Style Critical -Property '% Used'
                                    }
                                    if ($Healthcheck.DSCluster.SDRSAutomationLevel) {
                                        $DSClusterSummary | Where-Object {$_.'SDRS Automation Level' -ne 
                                            $Healthcheck.DSCluster.SDRSAutomationLevelSetting} | Set-Style -Style Warning -Property 'SDRS Automation Level'
                                    }
                                    $DSClusterSummary | Table -Name "$DSCluster Configuration" -List -ColumnWidths 50, 50
                                
                                    #region SDRS Overrides
                                    $StoragePodProps = @{
                                        'ViewType' = 'StoragePod'
                                        'Filter' = @{'Name' = $DSCluster.Name}
                                    }
                                    $StoragePod = Get-View @StoragePodProps
                                    if ($StoragePod) {
                                        $PodConfig = $StoragePod.PodStorageDrsEntry.StorageDrsConfig.PodConfig
                                        # Set default automation value variables
                                        Switch ($PodConfig.DefaultVmBehavior) {
                                            "automated" {$DefaultVmBehavior = "Default (Fully Automated)"}
                                            "manual" {$DefaultVmBehavior = "Default (No Automation (Manual Mode))"}
                                        }
                                        Switch ($PodConfig.DefaultIntraVmAffinity) {
                                            $true {$DefaultIntraVmAffinity = "Default (Yes)"}
                                            $false {$DefaultIntraVmAffinity = "Default (No)"}
                                        }
                                        $VMOverrides = $StoragePod.PodStorageDrsEntry.StorageDrsConfig.VmConfig | Where-Object {
                                            -not (
                                                ($_.Enabled -eq $null) -and
                                                ($_.IntraVmAffinity -eq $null)
                                            )
                                        }
                                    }
                                    if ($VMOverrides) {
                                        $VMOverrideDetails = foreach ($Override in $VMOverrides) {
                                            [PSCustomObject]@{
                                                'Virtual Machine' = $VMLookup."$($Override.Vm.Type)-$($Override.Vm.Value)"
                                                'SDRS Automation Level' = Switch ($Override.Enabled) {
                                                    $true {'Fully Automated'}
                                                    $false {'Disabled'}
                                                    $null {$DefaultVmBehavior}
                                                }
                                                'Keep VMDKs Together' = Switch ($Override.IntraVmAffinity) {
                                                    $true {'Yes'}
                                                    $false {'No'}
                                                    $null {$DefaultIntraVmAffinity}
                                                }
                                            }
                                        }
                                        Section -Style Heading4 'VM Overrides' {
                                            $VMOverrideDetails | Sort-Object 'Virtual Machine' | Table -Name 'VM Overrides'
                                        }
                                    }
                                    #endregion SDRS Overrides
                                }
                            }
                            #endregion Datastore Cluster Detailed Information
                        }
                    }
                }
            }
            #endregion Datastore Clusters     

            #region Virtual Machine Section
            if ($InfoLevel.VM -ge 1) {
                if ($VMs) {
                    Section -Style Heading2 'Virtual Machines' {
                        Paragraph ("The following section provides information on Virtual Machines " +
                            "managed by vCenter Server $vCenterServerName.")
                        BlankLine

                        #region Virtual Machine Informative Information
                        if ($InfoLevel.VM -eq 2) {
                            $VMSummary = foreach ($VM in $VMs) {
                                [PSCustomObject] @{
                                    'Name' = $VM.Name
                                    'Power State' = $VM.powerstate
                                    'vCPUs' = $VM.NumCpu
                                    'Cores per Socket' = $VM.CoresPerSocket
                                    'Memory GB' = [math]::Round(($VM.memoryGB), 2)
                                    'Provisioned GB' = [math]::Round(($VM.ProvisionedSpaceGB), 2)
                                    'Used GB' = [math]::Round(($VM.UsedSpaceGB), 2)
                                    'HW Version' = $VM.Version
                                    'VM Tools Status' = $VM.ExtensionData.Guest.ToolsStatus         
                                }
                            }
                            if ($Healthcheck.VM.VMTools) {
                                $VMSummary | Where-Object {$_.'VM Tools Status' -eq 'toolsNotInstalled' -or $_.'VM Tools Status' -eq 'toolsOld'} | Set-Style -Style Warning -Property 'VM Tools Status'
                            }
                            if ($Healthcheck.VM.PowerState) {
                                $VMSummary | Where-Object {$_.'Power State' -ne $Healthcheck.VM.PowerStateSetting} | Set-Style -Style Warning -Property 'Power State'
                            }
                            $VMSummary | Table -Name 'VM Summary'
                        }
                        #endregion Virtual Machine Informative Information

                        #region Virtual Machine Detailed Information
                        if ($InfoLevel.VM -ge 3) {
                            ## TODO: More VM Details to Add
                            $VMSpbmConfig = Get-SpbmEntityConfiguration -VM ($VMs) | Where-Object {$_.StoragePolicy -ne $null}
                            foreach ($VM in $VMs) {
                                Section -Style Heading3 $VM.name {
                                    $VMUptime = Get-Uptime -VM $VM
                                    $VMSpbmPolicy = $VMSpbmConfig | Where-Object {$_.entity -eq $vm}
                                    $VMSpecs = [PSCustomObject] @{
                                        'Name' = $VM.Name
                                        'ID' = $VM.Id 
                                        'Operating System' = $VM.ExtensionData.Summary.Config.GuestFullName
                                        'IP Address' = $VM.Guest.IPAddress[0]
                                        'Hardware Version' = $VM.Version
                                        'Power State' = Switch ($VM.PowerState) {
                                            PoweredOn {'Powered On'}
                                            PoweredOff {'Powered Off'}
                                        }
                                        'VM Tools Status' = $VM.ExtensionData.Guest.ToolsStatus
                                        'Fault Tolerance State' = $VM.ExtensionData.Runtime.FaultToleranceState 
                                        'Host' = $VM.VMHost.Name
                                        'Parent' = $VM.VMHost.Parent.Name
                                        'Parent Folder' = $VM.Folder.Name
                                        'Parent Resource Pool' = $VM.ResourcePool.Name 
                                        'vCPUs' = $VM.NumCpu
                                        'Cores per Socket' = $VM.CoresPerSocket
                                        'CPU Resources' = "$($VM.VMResourceConfiguration.CpuSharesLevel) / $($VM.VMResourceConfiguration.NumCpuShares)"
                                        'CPU Reservation' = $VM.VMResourceConfiguration.CpuReservationMhz
                                        'CPU Limit' = "$($VM.VMResourceConfiguration.CpuReservationMhz) MHz" 
                                        'CPU Hot Add Enabled' = $VM.ExtensionData.Config.CpuHotAddEnabled
                                        'CPU Hot Remove Enabled' = $VM.ExtensionData.Config.CpuHotRemoveEnabled 
                                        'Memory Allocation' = "$([math]::Round(($VM.memoryGB), 2)) GB" 
                                        'Memory Resources' = "$($VM.VMResourceConfiguration.MemSharesLevel) / $($VM.VMResourceConfiguration.NumMemShares)"
                                        'Memory Hot Add Enabled' = $VM.ExtensionData.Config.MemoryHotAddEnabled
                                        'vDisks' = $VM.ExtensionData.Summary.Config.NumVirtualDisks
                                        'Used Space' = "$([math]::Round(($VM.UsedSpaceGB), 2)) GB"
                                        'Provisioned Space' = "$([math]::Round(($VM.ProvisionedSpaceGB), 2)) GB"
                                        'Changed Block Tracking Enabled' = $VM.ExtensionData.Config.ChangeTrackingEnabled
                                        'Storage Based Policy' = $VMSpbmPolicy.StoragePolicy.Name
                                        'Storage Based Policy Compliance' = $VMSpbmPolicy.ComplianceStatus
                                        'vNICs' = $VM.ExtensionData.Summary.Config.NumEthernetCards
                                        'Notes' = $VM.Notes
                                        'Boot Time' = $VM.ExtensionData.Runtime.BootTime
                                        'Uptime Days' = $VMUptime.UptimeDays
                                    }
                                
                                    if ($Healthcheck.VM.VMTools) {
                                        $VMSpecs | Where-Object {$_.'VM Tools Status' -eq 'toolsNotInstalled' -or $_.'VM Tools Status' -eq 'toolsOld'} | Set-Style -Style Warning -Property 'VM Tools Status'
                                    }
                                    if ($Healthcheck.VM.PowerState) {
                                        $VMSpecs | Where-Object {$_.'Power State' -ne $Healthcheck.VM.PowerStateSetting} | Set-Style -Style Warning -Property 'Power State'
                                    }
                                    if ($Healthcheck.VM.CpuHotAddEnabled) {
                                        $VMSpecs | Where-Object {$_.'CPU Hot Add Enabled' -eq $true} | Set-Style -Style Warning -Property 'CPU Hot Add Enabled'
                                    }
                                    if ($Healthcheck.VM.CpuHotRemoveEnabled) {
                                        $VMSpecs | Where-Object {$_.'CPU Hot Remove Enabled' -eq $true} | Set-Style -Style Warning -Property 'CPU Hot Remove Enabled'
                                    } 
                                    if ($Healthcheck.VM.MemoryHotAddEnabled) {
                                        $VMSpecs | Where-Object {$_.'Memory Hot Add Enabled' -eq $true} | Set-Style -Style Warning -Property 'Memory Hot Add Enabled'
                                    } 
                                    if ($Healthcheck.VM.ChangeBlockTrackingEnabled) {
                                        $VMSpecs | Where-Object {$_.'Changed Block Tracking Enabled' -eq $false} | Set-Style -Style Warning -Property 'Changed Block Tracking Enabled'
                                    } 
                                    if ($Healthcheck.VM.SpbmPolicyCompliance) {
                                        $VMSpecs | Where-Object {$_.'Storage Based Policy Compliance' -eq 'nonCompliant'} | Set-Style -Style Critical -Property 'Storage Based Policy Compliance'
                                    } 
                                    $VMSpecs | Table -Name 'Virtual Machines' -List -ColumnWidths 50, 50
                                }
                            } 
                            #endregion Virtual Machine Summary Information
                        }
                        BlankLine

                        #region VM Snapshot Information
                        if ($InfoLevel.VM -ge 2) {
                            $VMSnapshots = $VMs | Get-Snapshot 
                            if ($VMSnapshots) {
                                Section -Style Heading3 'VM Snapshots' {
                                    $VMSnapshotSpecs = foreach ($VMSnapshot in $VMSnapshots) {
                                        [PSCustomObject] @{
                                            'Virtual Machine' = $VMSnapshot.VM
                                            'Name' = $VMSnapshot.Name
                                            'Description' = $VMSnapshot.Description
                                            'Days Old' = ((Get-Date) - $VMSnapshot.Created).Days
                                        } 
                                    }
                                    if ($Healthcheck.VM.VMSnapshots) {
                                        $VMSnapshotSpecs | Where-Object {$_.'Days Old' -ge 7} | Set-Style -Style Warning 
                                        $VMSnapshotSpecs | Where-Object {$_.'Days Old' -ge 14} | Set-Style -Style Critical
                                    }
                                    $VMSnapshotSpecs | Table -Name 'VM Snapshots'
                                }
                            }
                        }
                        #endregion VM Snapshot Information
                    }
                }
            }
            #endregion Virtual Machine Section

            #region VMware Update Manager Section
            if ($InfoLevel.VUM -ge 1) {
                $Script:VUMBaselines = Get-PatchBaseline -Server $vCenter | Sort-Object Name
                if ($VUMBaselines) {
                    Section -Style Heading2 'VMware Update Manager' {
                        Paragraph ("The following section provides information on VMware Update Manager " +
                            "managed by vCenter Server $vCenterServerName.")
                        #region VUM Baseline Detailed Information
                        if ($InfoLevel.VUM -ge 2) {
                            Section -Style Heading3 'Baselines' {
                                $VUMBaselineSpecs = foreach ($VUMBaseline in $VUMBaselines) {
                                    [PSCustomObject] @{
                                        'Name' = $VUMBaseline.Name
                                        'Description' = $VUMBaseline.Description
                                        'Type' = $VUMBaseline.BaselineType
                                        'Target Type' = $VUMBaseline.TargetType
                                        'Last Update Time' = $VUMBaseline.LastUpdateTime
                                        '# of Patches' = ($VUMBaseline.CurrentPatches).Count
                                    }
                                }
                                $VUMBaselineSpecs | Table -Name 'VMware Update Manager Baselines'
                            }
                        }
                        #endregion VUM Baseline Detailed Information
                        BlankLine
                        #region VUM Comprehensive Information
                        $Script:VUMPatches = Get-Patch -Server $vCenter | Sort-Object -Descending ReleaseDate
                        if ($VUMPatches -and $InfoLevel.VUM -ge 5) {
                            Section -Style Heading3 'Patches' {
                                $VUMPatchSpecs = foreach ($VUMPatch in $VUMPatches) {
                                    [PSCustomObject] @{
                                        'Name' = $VUMPatch.Name
                                        'Product' = ($VUMPatch.Product).Name
                                        'Description' = $VUMPatch.Description
                                        'Release Date' = $VUMPatch.ReleaseDate
                                        'Vendor ID' = $VUMPatch.IdByVendor
                                    }
                                }
                                $VUMPatchSpecs | Table -Name 'VMware Update Manager Patches'
                            }
                        }
                        #endregion VUM Comprehensive Information
                    }
                }
            }
            #endregion VMware Update Manager Section

            #region VMware NSX-V Section
            if ($InfoLevel.NSX -ge 1) {
                #Call the NSX-V report script
                $NSXReport = "$PSScriptRoot\..\..\Reports\NSX\NSX.ps1"
                if (Test-Path $NSXReport -ErrorAction SilentlyContinue) {
                    .$NSXReport -VIServer $VIServer -credentials $credentials
                } else {
                    Write-Error "$NSXReport report does not exist"
                    break
                }
            }
            #endregion VMware NSX-V Section

            #region VMware SRM Section
            ## TODO: VMware SRM Report
            if ($InfoLevel.SRM -ge 1) {
            }
            #endregion VMware SRM Section
        }
        # Disconnect vCenter Server
        $Null = Disconnect-VIServer -Server $VIServer -Confirm:$false -ErrorAction SilentlyContinue
    }
    # Add page break between addtional vCenter instances
    #while ($Count -lt ($Target).Count) {
    #    PageBreak
    #    $Count = $Count + 1
    #}
}
#endregion Script Body