#requires -Modules @{ModuleName="PScribo";ModuleVersion="0.7.22"},VMware.VimAutomation.Core

#region Configuration Settings
###############################################################################################
#                                    CONFIG SETTINGS                                          #
###############################################################################################
$ScriptPath = (Get-Location).Path
$ReportConfigFile = Join-Path $ScriptPath $("Reports\$Type\$Type.json")
If (Test-Path $ReportConfigFile -ErrorAction SilentlyContinue) {
    $ReportConfig = Get-Content $ReportConfigFile | ConvertFrom-json
    $InfoLevel = $ReportConfig.InfoLevel
    if ($Healthcheck) {
        $HealthCheck = $ReportConfig.HealthCheck
    }    
}
# If custom style not set, use VMware style
if (!$StyleName) {
    .\Styles\VMware.ps1
}

# Connect to vCenter Server using supplied credentials
$vCenter = Connect-VIServer $IP -Credential $Credentials

#endregion Configuration Settings

#region Script Functions
###############################################################################################
#                                    SCRIPT FUNCTIONS                                         #
###############################################################################################
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
            foreach ($ESXiHost in $VMHost) {

                if ($ESXiHost.GetType().Name -eq 'string') {
                
                    try {
                        $ESXiHost = Get-VMHost $ESXiHost -ErrorAction Stop
                    }
                    catch [Exception] {
                        Write-Warning "VMHost $ESXiHost does not exist"
                    }
                }
                
                elseif ($ESXiHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]) {
                    Write-Warning 'You did not pass a string or a VMHost object'
                    Return
                }

                $ConfigManagerView = Get-View $ESXiHost.ExtensionData.ConfigManager.NetworkSystem
                $PNICs = $ConfigManagerView.NetworkInfo.Pnic

                foreach ($PNIC in $PNICs) {

                    $PhysicalNicHintInfo = $ConfigManagerView.QueryNetworkHint($PNIC.Device)

                    if ($PhysicalNicHintInfo.ConnectedSwitchPort) {

                        $Connected = $true
                    }
                    else {
                        $Connected = $false
                    }

                    $Object = [pscustomobject]@{                        
                    
                        VMHost           = $ESXiHost.Name
                        NIC              = $PNIC.Device
                        Connected        = $Connected
                        Switch           = $PhysicalNicHintInfo.ConnectedSwitchPort.DevId
                        HardwarePlatform = $PhysicalNicHintInfo.ConnectedSwitchPort.HardwarePlatform
                        SoftwareVersion  = $PhysicalNicHintInfo.ConnectedSwitchPort.SoftwareVersion
                        MangementAddress = $PhysicalNicHintInfo.ConnectedSwitchPort.MgmtAddr
                        PortId           = $PhysicalNicHintInfo.ConnectedSwitchPort.PortId

                    }
                    
                    $CDPObject += $Object
                }
            }
        }
        catch [Exception] {
            
            throw 'Unable to retrieve CDP info'
        }
    }
    end {
        
        Write-Output $CDPObject
    }
}

function Get-InstallDate {
    Get-VMHost $VMhost | Sort-Object Name | ForEach-Object {
        $esxcli = Get-EsxCli -VMHost $_.name -V2
        $thisUUID = $esxcli.system.uuid.get.Invoke()
        $decDate = [Convert]::ToInt32($thisUUID.Split("-")[0], 16)
        $installDate = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($decDate))
        [pscustomobject][ordered]@{
            Name        = "$($_.name)"
            InstallDate = $installDate
        } # end custom object
    } # end host loop
}

function Get-vCenterLicense {
    <#
    .SYNOPSIS
    Function to retrieve vCenter licenses.
    
    .DESCRIPTION
    Function to retrieve vCenter licenses.
    
    .PARAMETER LicenseKey
    License key to query

    .INPUTS
    String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-vCenterLicense
    
    .EXAMPLE
    PS> Get-vCenterLicense -LicenseKey 'F2JQE-5SE2W-3KSN7-0SMH6-93NSH'
#>
    [CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (
    
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$LicenseKey  
    ) 
    
    begin {
    
        $LicenseObject = @()    
        
        # --- Get access to the vCenter License Manager
        $ServiceInstance = Get-View ServiceInstance
        $LicenseManager = Get-View $ServiceInstance.Content.LicenseManager
    }
    
    process {
    
        try {
            
            if ($LicenseKey) {
               
                # --- Query the License Manager
                foreach ($Key in $LicenseKey) {
                
                    if ($License = $LicenseManager.Licenses | Where-Object {$_.LicenseKey -eq $Key}) {
                        
                        $Object = [pscustomobject]@{                        
                            
                            #Key = $License.LicenseKey
                            Key   = "*****-*****-*****" + $License.LicenseKey.Substring(17);
                            Type  = $License.Name
                            Total = $License.Total
                            Used  = $License.Used
                            
                        }
                        
                        $LicenseObject += $Object
                    }
                    else {
                        Write-Verbose "Unable to find license key $Key"
                    }                    
                }
                            
            }
            else {

                # --- Query the License Manager
                foreach ($License in $LicenseManager.Licenses) {
                
                    $Object = [pscustomobject]@{                        
                    
                        #Key = $License.LicenseKey
                        Key   = "*****-*****-*****" + $License.LicenseKey.Substring(17);
                        Type  = $License.Name
                        Total = $License.Total
                        Used  = $License.Used
                    
                    }
                
                    $LicenseObject += $Object
                }
            }
        }
            
        catch [Exception] {
        
            throw "Unable to retrieve Licenses for vCenter $defaultVIServer"
        } 
    }
    
    end {
        Write-Output $LicenseObject
    }
}

function Get-VMHostUptime {
    [CmdletBinding()] 
    Param (
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][Alias('Name')][string]$VMHosts,
        [string]$Cluster
    )
    Process {
        If ($VMHosts) {
            foreach ($VMHost in $VMHosts) {Get-View  -ViewType hostsystem -Property name, runtime.boottime -Filter @{'name' = "$VMHost"} | Select-Object Name, @{N = 'UptimeDays'; E = {[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalDays), 1)}}, @{N = 'UptimeHours'; E = {[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalHours), 1)}}, @{N = 'UptimeMinutes'; E = {[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalMinutes), 1)}}
            }
        }
 
        elseif ($Cluster) {
            foreach ($VMHost in (Get-VMHost -Location $Cluster)) {Get-View  -ViewType hostsystem -Property name, runtime.boottime -Filter @{'name' = "$VMHost"} | Select-Object Name, @{N = 'UptimeDays'; E = {[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalDays), 1)}}, @{N = 'UptimeHours'; E = {[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalHours), 1)}}, @{N = 'UptimeMinutes'; E = {[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalMinutes), 1)}}
            }
        }
 
        else {
            Get-View  -ViewType hostsystem -Property name, runtime.boottime | Select-Object Name, @{N = 'UptimeDays'; E = {[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalDays), 1)}}, @{N = 'UptimeHours'; E = {[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalHours), 1)}}, @{N = 'UptimeMinutes'; E = {[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalMinutes), 1)}}
        }
    }
    <#
 .Synopsis
  Shows the uptime of VMHosts
 .Description
  Calculates the uptime of VMHosts provided, or VMHosts in the cluster provided
 .Parameter VMHosts
  The VMHosts you want to get the uptime of. Can be a single host or multiple hosts provided by the pipeline
 .Example
  Get-VMHostUptime
  Shows the uptime of all VMHosts in your vCenter
 .Example
  Get-VMHostUptime vmhost1
  Shows the uptime of vmhost1
 .Example
  Get-VMHostUptime -cluster cluster1
  Shows the uptime of all vmhosts in cluster1
 .Example
  Get-VMHost -location folder1 | Get-VMHostUptime
  Shows the uptime of VMHosts in folder1
 .Link
  http://cloud.kemta.net
 #>
}

Function Get-ESXiBootDevice {
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
        Get-ESXiBootDevice -VMHostname esxi-01
#>
    param(
        [Parameter(Mandatory = $false)][String]$VMHostname
    )

    if ($VMHostname) {
        $vmhosts = Get-VMhost -Name $VMHostname
    }
    else {
        $vmhosts = Get-VMHost
    }

    $results = @()
    foreach ($vmhost in ($vmhosts | Sort-Object -Property Name)) {
        $esxcli = Get-EsxCli -V2 -VMHost $vmhost
        $bootDetails = $esxcli.system.boot.device.get.Invoke()

        # Check to see if ESXi booted over the network
        $networkBoot = $false
        if ($bootDetails.BootNIC) {
            $networkBoot = $true
            $bootDevice = $bootDetails.BootNIC
        }
        elseif ($bootDetails.StatelessBootNIC) {
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
            }
            catch {
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
                }
                elseif ($device.IsLocal -eq $true -and $networkBoot -eq $false) {
                    $bootType = "local"
                }
                elseif ($device.IsLocal -eq $false -and $networkBoot -eq $false) {
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

        $tmp = [pscustomobject] @{
            Host     = $vmhost.Name;
            Device   = $bootDevice;
            BootType = $bootType;
            Vendor   = $bootVendor;
            Model    = $bootModel;
            SizeMB   = $bootSize;
            IsSAS    = $bootIsSAS;
            IsSSD    = $bootIsSSD;
            IsUSB    = $bootIsUSB;
        }
        $results += $tmp
    }
    $results
}
#endregion Script Functions

#region Script Body
###############################################################################################
#                                         SCRIPT BODY                                         #
###############################################################################################
# vCenter Server Section
Section -Style Heading1 'vCenter Server' {
    $VCAdvSettings = Get-AdvancedSetting -Entity $vCenter
    $VCServerFQDN = ($VCAdvSettings | Where-Object {$_.name -eq 'VirtualCenter.FQDN'}).Value

    Paragraph "The following section details the configuration of vCenter server $VCServerFQDN."
    
    Section -Style Heading2 $VCServerFQDN {
        $VCAdvSettingsHash = @{}
        $VCAdvSettingsHash = @{
            FQDN                       = $VCServerFQDN
            IPv4                       = ($VCAdvSettings | Where-Object {$_.name -like 'VirtualCenter.AutoManagedIPV4'}).Value
            Version                    = $vCenter.Version
            Build                      = $vCenter.Build
            
            HttpPort                   = ($VCAdvSettings | Where-Object {$_.name -eq 'config.vpxd.rhttpproxy.httpport'}).Value
            HttpsPort                  = ($VCAdvSettings | Where-Object {$_.name -eq 'config.vpxd.rhttpproxy.httpsport'}).Value

            InstanceId                 = ($VCAdvSettings | Where-Object {$_.name -eq 'instance.id'}).Value
            PasswordExpiry             = ($VCAdvSettings | Where-Object {$_.name -eq 'VirtualCenter.VimPasswordExpirationInDays'}).Value
            PlatformServicesController = ($VCAdvSettings | Where-Object {$_.name -eq 'config.vpxd.sso.admin.uri'}).Value
        }
        $vCenterSettings = $VCAdvSettingsHash | Select-Object @{L = 'Name'; E = {$_.FQDN}}, @{L = 'IP Address'; E = {$_.IPv4}}, @{L = 'Version'; E = {$_.Version}}, @{L = 'Build'; E = {$_.Build}}, `
        @{L = 'Instance Id'; E = {$_.InstanceId}}, @{L = 'Password Expiry in Days'; E = {$_.PasswordExpiry}}, @{L = 'HTTP Port'; E = {$_.httpport}}, @{L = 'HTTPS Port'; E = {$_.httpsport}}, `
        @{L = 'Platform Services Controller'; E = {$_.PlatformServicesController}} 
        $vCenterSettings | Table -Name $VCServerFQDN -List -ColumnWidths 50, 50 

        Section -Style Heading3 'Database Settings' {
            $VCDBSettingsHash = @{}
            $VCDBSettingsHash = @{
                DbType           = ($VCAdvSettings | Where-Object {$_.name -eq 'config.vpxd.odbc.dbtype'}).Value
                Dsn              = ($VCAdvSettings | Where-Object {$_.name -eq 'config.vpxd.odbc.dsn'}).Value
                MaxDbConnections = ($VCAdvSettings | Where-Object {$_.name -eq 'VirtualCenter.MaxDBConnection'}).Value
            }
            $VCDBSettings = $VCDBSettingsHash | Select-Object @{L = 'Database Type'; E = {$_.dbtype}}, @{L = 'Data Source Name'; E = {$_.dsn}}, @{L = 'Maximum Database Connections'; E = {$_.MaxDbConnections}}
            $VCDBSettings | Table -Name 'vCenter Database Settings' -List -ColumnWidths 50, 50 
        }
    
        Section -Style Heading3 'Mail Settings' {
            $VCMailSettingsHash = @()
            $VCMailSettingsHash = @{
                SmtpServer = ($VCAdvSettings | Where-Object {$_.name -eq 'mail.smtp.server'}).Value
                SmtpPort   = ($VCAdvSettings | Where-Object {$_.name -eq 'mail.smtp.port'}).Value
                MailSender = ($VCAdvSettings | Where-Object {$_.name -eq 'mail.sender'}).Value
            }
            $VCMailSettings = $VCMailSettingsHash | Select-Object @{L = 'SMTP Server'; E = {$_.SmtpServer}}, @{L = 'SMTP Port'; E = {$_.SmtpPort}}, @{L = 'Mail Sender'; E = {$_.mailSender}}
            $VCMailSettings | Table -Name 'vCenter Mail Settings' -List -ColumnWidths 50, 50 
        }
    
        Section -Style Heading3 'Historical Statistics' {
            $ServiceInstance = Get-View ServiceInstance
            $VCenterStatistics = Get-View ($ServiceInstance).Content.PerfManager
            $vCenterStats = @()
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
                    IntervalEnabled  = $xStatLevel.Enabled;
                    SaveDuration     = $xStatLevel.Name;
                    StatsLevel       = $xStatLevel.Level;
                }
                ## Add the hash to the array
                $vCenterStats += $vCenterStatsHash;
                $CurrentServiceIndex++
            }
            $vCenterHistoricalStats = $vCenterStats | Select-Object @{L = 'Interval Duration'; E = {$_.IntervalDuration}}, @{L = 'Interval Enabled'; E = {$_.IntervalEnabled}}, @{L = 'Save Duration'; E = {$_.SaveDuration}}, @{L = 'Statistics Level'; E = {$_.StatsLevel}}
            $vCenterHistoricalStats | Table -Name 'Historical Statistics' 
        }

        Section -Style Heading3 'Licensing' {
            $Licenses = Get-vCenterLicense | Select-Object @{L = 'Product Name'; E = {($_.type)}}, @{L = 'License Key'; E = {($_.key)}}, Total, Used, @{L = 'Available'; E = {($_.total) - ($_.Used)}}
            $Licenses | Table -Name 'Licensing' -ColumnWidths 35, 35, 10, 10, 10
        }

        Section -Style Heading3 'Roles' {
            $VCRoles = Get-VIRole -Server $vCenter | Sort-Object Name | Select-Object Name, @{L = 'System Role'; E = {$_.IsSystem}}
            $VCRoles | Table -Name 'Roles' -ColumnWidths 50, 50 
        }
        
        $Tags = Get-Tag
        if ($Tags) {
            Section -Style Heading3 'Tags' {
                $Tags = $Tags | Sort-Object Name, Category | Select-Object Name, Description, Category
                $Tags | Table -Name 'Tags'
            }
        }

        $TagCategories = Get-TagCategory 
        if ($TagCategories) {
            Section -Style Heading3 'Tag Categories' {
                $TagCategories = $TagCategories | Sort-Object name | Select-Object Name, Description, Cardinality -Unique
                $TagCategories | Table -Name 'Tag Categories' 
            }
        }
        
        $TagAssignements = Get-TagAssignment 
        if ($TagAssignements) {
            Section -Style Heading3 'Tag Assignments' {
                $TagAssignements = $TagAssignements | Sort-Object Tag | Select-Object Tag, Entity
                $TagAssignements | Table -Name 'Tag Assignments' -ColumnWidths 50, 50
            }
        }
         
        if ($InfoLevel.vCenter -ge 4) {
            Section -Style Heading3 'Alarms' {
                Paragraph 'The following table details the configuration of the vCenter Server alarms.'
                BlankLine
                #$Alarms = Get-AlarmDefinition | Where-Object {$_.Enabled} | Sort-Object name | Select-Object Name, Description
                $Alarms = Get-AlarmAction | Sort-Object AlarmDefinition | Select-Object @{L = 'Alarm Definition'; E = {$_.AlarmDefinition}}, @{L = 'Action Type'; E = {$_.ActionType}}, @{L = 'Trigger'; E = {$_.Trigger -join ", "}}
                $Alarms | Table -Name 'Alarms' 
            }
        }
    
    }
}
PageBreak

$Script:Clusters = Get-Cluster
if ($Clusters) {
    # Clusters Section
    Section -Style Heading1 'Clusters' {
        Paragraph 'The following section details the configuration of each vSphere HA/DRS cluster.'
        BlankLine
    
        # Cluster Summary
        $ClusterSummary = $Clusters | Sort-Object name | Select-Object name, @{L = 'Datacenter'; E = {($_ | Get-Datacenter)}}, @{L = 'Host Count'; E = {($_ | Get-VMhost).count}}, @{L = 'HA Enabled'; E = {($_.haenabled)}}, @{L = 'DRS Enabled'; E = {($_.drsenabled)}}, `
        @{L = 'vSAN Enabled'; E = {($_.vsanenabled)}}, @{L = 'EVC Mode'; E = {($_.EVCMode)}}, @{L = 'VM Swap File Policy'; E = {($_.VMSwapfilePolicy)}}, @{L = 'VM Count'; E = {($_ | Get-VM).count}} 
        if ($Healthcheck) {
            $ClusterSummary | Where-Object {$_.'HA Enabled' -eq $False} | Set-Style -Style Warning -Property 'HA Enabled'
            $ClusterSummary | Where-Object {$_.'HA Admission Control Enabled' -eq $False} | Set-Style -Style Warning -Property 'HA Admission Control Enabled'
            $ClusterSummary | Where-Object {$_.'DRS Enabled' -eq $False} | Set-Style -Style Warning -Property 'DRS Enabled'
        }
        $ClusterSummary | Table -Name 'Cluster Summary' 

        # Cluster Detailed Information
        foreach ($Cluster in ($Clusters)) {
            Section -Style Heading2 $Cluster {
                # vSphere HA Information
                Section -Style Heading3 'HA Configuration' {
                    Paragraph "The following table details the vSphere HA configuration for cluster $Cluster."
                    BlankLine

                    ### TODO: HA Advanced Settings, Proactive HA
                    
                    $HACluster = $Cluster | Select-Object @{L = 'HA Enabled'; E = {($_.HAEnabled)}}, @{L = 'HA Admission Control Enabled'; E = {($_.HAAdmissionControlEnabled)}}, @{L = 'HA Failover Level'; E = {($_.HAFailoverLevel)}}, `
                    @{L = 'HA Restart Priority'; E = {($_.HARestartPriority)}}, @{L = 'HA Isolation Response'; E = {($_.HAIsolationResponse)}}, @{L = 'Heartbeat Selection Policy'; E = {$_.ExtensionData.Configuration.DasConfig.HBDatastoreCandidatePolicy}}, `
                    @{L = 'Heartbeat Datastores'; E = {($_.ExtensionData.Configuration.DasConfig.HeartbeatDatastore | ForEach-Object {(get-view -id $_).name}) -join ", "}}
                    if ($Healthcheck) {
                        $HACluster | Where-Object {$_.'HA Enabled' -eq $False} | Set-Style -Style Warning -Property 'HA Enabled'
                        $HACluster | Where-Object {$_.'HA Admission Control Enabled' -eq $False} | Set-Style -Style Warning -Property 'HA Admission Control Enabled'
                    }
                    $HACluster | Table -Name "$Cluster HA Configuration" -List -ColumnWidths 50, 50 
                }

                # vSphere DRS Information
                Section -Style Heading3 'DRS Configuration' {
                    Paragraph "The following table details the vSphere DRS configuration for cluster $Cluster."
                    BlankLine

                    ## TODO: DRS Advanced Settings

                    $DRSCluster = $Cluster | Select-Object @{L = 'DRS Enabled'; E = {($_.DrsEnabled)}}, @{L = 'DRS Automation Level'; E = {($_.DrsAutomationLevel)}}, @{L = 'DRS Migration Threshold'; E = {($_.ExtensionData.Configuration.DrsConfig.VmotionRate)}}
                    if ($Healthcheck) {
                        $DRSCluster | Where-Object {$_.'DRS Enabled' -eq $False} | Set-Style -Style Warning -Property 'DRS Enabled'
                    }
                    $DRSCluster | Table -Name "$Cluster DRS Configuration" -List -ColumnWidths 50, 50 
                    BlankLine

                    # DRS Additional Options                  
                    $DRSAdvancedSettings = $Cluster | Get-AdvancedSetting | Where-Object {$_.Type -eq 'ClusterDRS'}
                    $DRSAdditionalOptionsHash = @{
                        VMDistribution = ($DRSAdvancedSettings | Where-Object {$_.name -eq 'TryBalanceVmsPerHost'}).Value
                        MemoryMetricLB = ($DRSAdvancedSettings | Where-Object {$_.name -eq 'PercentIdleMBInMemDemand'}).Value
                        CpuOverCommit  = ($DRSAdvancedSettings | Where-Object {$_.name -eq 'MaxVcpusPerClusterPct'}).Value
                    }
                    $DRSAdditionalOptions = $DRSAdditionalOptionsHash | Select-Object @{L = 'VM Distribution'; E = {$_.VMDistribution}}, @{L = 'Memory Metric for Load Balancing'; E = {$_.MemoryMetricLB}}, @{L = 'CPU Over-Commitment'; E = {$_.CpuOverCommit}}
                    $DRSAdditionalOptions | Table -Name "$Cluster DRS Additional Options" -List -ColumnWidths 50, 50
                    
                    # DRS Cluster Group Information
                    $DRSGroups = $Cluster | Get-DrsClusterGroup
                    if ($DRSGroups) {
                        Section -Style Heading4 'DRS Cluster Groups' {
                            $DRSGroups = $DRSGroups | Sort-Object GroupType, Name | Select-Object Name, @{L = 'Group Type'; E = {$_.GroupType}}, @{L = 'Members'; E = {$_.Member -join ", "}}
                            $DRSGroups | Table -Name "$Cluster DRS Cluster Groups"
                        }
                    }   

                    # DRS VM/Host Rules Information
                    $DRSVMHostRules = $Cluster | Get-DrsVMHostRule
                    if ($DRSVMHostRules) {
                        Section -Style Heading4 'DRS VM/Host Rules' {
                            $DRSVMHostRules = $DRSVMHostRules | Sort-Object Name | Select-Object Name, Type, Enabled, @{L = 'VM Group'; E = {$_.VMGroup}}, @{L = 'VMHost Group'; E = {$_.VMHostGroup}}
                            $DRSVMHostRules | Table -Name "$Cluster DRS VM/Host Rules"
                        }
                    } 

                    # DRS Rules Information
                    $DRSRules = $Cluster | Get-DrsRule
                    if ($DRSRules) {
                        Section -Style Heading4 'DRS Rules' {
                            $DRSRules = $DRSRules | Sort-Object Type | Select-Object Name, Type, Enabled, Mandatory, @{L = 'Virtual Machines'; E = {($_.VMIds | ForEach-Object {(get-view -id $_).name}) -join ", "}}
                            $DRSRules | Table -Name "$Cluster DRS Rules"
                        }
                    }
                    
                    <#
                    # VM Override Information
                    Section -Style Heading3 'VM Overrides' {
                            #### TODO: VM Overrides
                    }
                    #>                                  
                }
                

                $ClusterBaselines = $Cluster | Get-PatchBaseline
                if ($ClusterBaselines) {
                    Section -Style Heading3 'Update Manager Baselines' {
                        $ClusterBaselines = $ClusterBaselines | Sort-Object Name | Select-Object Name, Description, @{L = 'Type'; E = {$_.BaselineType}}, @{L = 'Target Type'; E = {$_.TargetType}}, @{L = 'Last Update Time'; E = {$_.LastUpdateTime}}, @{L = 'Number of Patches'; E = {($_.CurrentPatches).count}}
                        $ClusterBaselines | Table -Name "$Cluster Update Manager Baselines"
                    }
                }

                $ClusterCompliance = $Cluster | Get-Compliance
                if ($ClusterCompliance) {
                    Section -Style Heading3 'Update Manager Compliance' {
                        $ClusterCompliance = $ClusterCompliance | Sort-Object Entity, Baseline | Select-Object @{L = 'Name'; E = {$_.Entity}}, @{L = 'Baseline'; E = {($_.Baseline).Name -join ", "}}, Status
                        if ($Healthcheck) {
                            $ClusterCompliance | Where-Object {$_.Status -eq 'NotCompliant'} | Set-Style -Style Critical
                        }
                        $ClusterCompliance | Table -Name "$Cluster Update Manager Compliance"
                    }
                }
                
                # Cluster Permission
                Section -Style Heading3 'Permissions' {
                    Paragraph "The following table details the permissions assigned to cluster $Cluster."
                    BlankLine

                    $VIPermission = $Cluster | Get-VIPermission | Select-Object @{L = 'User/Group'; E = {$_.Principal}}, Role, @{L = 'Defined In'; E = {$_.Principal}}, Propagate
                    $VIPermission | Table -Name "$Cluster Permissions"
                }
            }
        }
    }
    PageBreak
}    

# Resource Pool Section
$Script:ResourcePools = Get-ResourcePool
if ($ResourcePools) {
    Section -Style Heading1 'Resource Pools' {
        Paragraph 'The following section details the configuration of each resource pool.'
        BlankLine

        # Resource Pool Specifications
        $ResourcePools = $ResourcePools | Sort-Object Parent, Name | Select-Object Name, Parent, @{L = 'CPU Shares Level'; E = {$_.CpuSharesLevel}}, @{L = 'Number of CPU Shares'; E = {$_.NumCpuShares}}, `
        @{L = 'CPU Reservation MHz'; E = {$_.CpuReservationMHz}}, @{L = 'CPU Expandable Reservation'; E = {$_.CpuExpandableReservation}}, @{L = 'CPU Limit MHz'; E = {$_.CpuLimitMHz}}, `
        @{L = 'Memory Shares Level'; E = {$_.MemSharesLevel}}, @{L = 'Number of Memory Shares'; E = {$_.NumMemShares}}, @{L = 'Memory Reservation GB'; E = {[math]::Round($_.MemReservationGB, 2)}}, `
        @{L = 'Memory Expandable Reservation'; E = {$_.MemExpandableReservation}}, @{L = 'Memory Limit GB'; E = {[math]::Round($_.MemLimitGB, 2)}}, @{L = 'Virtual Machines'; E = {(($_ | Get-VM | Sort-Object Name).Name -join ", ")}}
        $ResourcePools | Table -Name 'Resource Pools' -List -ColumnWidths 50, 50 
    }
    PageBreak
}

# ESXi Host Section
$Script:VMhosts = Get-VMHost 
if ($VMhosts) {
    Section -Style Heading1 'Hosts' {
        Paragraph 'The following section details the configuration of each VMware ESXi host.'
        BlankLine
    
        # ESXi Host Summary
        $VMhostSummary = $VMhosts | Sort-Object Name | Select-Object name, version, build, parent, @{L = 'Connection State'; E = {$_.ConnectionState}}, @{L = 'CPU Usage MHz'; E = {$_.CpuUsageMhz}}, @{L = 'Memory Usage GB'; E = {[math]::Round($_.MemoryUsageGB, 2)}}, `
        @{L = 'VM Count'; E = {($_ | Get-VM).count}}
        if ($HealthCheck.VMHost.ConnectionState) {
            $VMhostSummary | Where-Object {$_.'Connection State' -eq 'Maintenance'} | Set-Style -Style Warning
            $VMhostSummary | Where-Object {$_.'Connection State' -eq 'Disconnected'} | Set-Style -Style Critical
        }
        $VMhostSummary | Table -Name 'Host Summary'
    
        # ESXi Host Detailed Information
        foreach ($VMhost in ($VMhosts | Sort-Object Name | Where-Object {$_.ConnectionState -eq 'Connected' -or $_.ConnectionState -eq 'Maintenance'})) {        
            Section -Style Heading2 $VMhost {

                # ESXi Host Hardware Section
                Section -Style Heading3 'Hardware' {
                    Paragraph "The following section details the host hardware configuration of $VMhost."
                    BlankLine
                    $uptime = Get-VMHostUptime $VMhost
                    $esxcli = Get-EsxCli -VMHost $VMhost -V2
                    $VMHostHardware = Get-VMHostHardware -VMHost $VMhost
                    $ScratchLocation = Get-AdvancedSetting -Entity $VMhost | Where-Object {$_.Name -eq 'ScratchConfig.CurrentScratchLocation'}
                    $VMhostspec = $VMhost | Sort-Object name | Select-Object name, manufacturer, model, @{L = 'Serial Number'; E = {$VMHostHardware.SerialNumber}}, @{L = 'Asset Tag'; E = {$VMHostHardware.AssetTag}}, `
                    @{L = 'Processor Type'; E = {($_.processortype)}}, @{L = 'HyperThreading'; E = {($_.HyperthreadingActive)}}, @{L = 'CPU Socket Count'; E = {$_.ExtensionData.Hardware.CpuInfo.NumCpuPackages}}, `
                    @{L = 'CPU Core Count'; E = {$_.ExtensionData.Hardware.CpuInfo.NumCpuCores}}, @{L = 'CPU Thread Count'; E = {$_.ExtensionData.Hardware.CpuInfo.NumCpuThreads}}, `
                    @{L = 'CPU Speed MHz'; E = {[math]::Round(($_.ExtensionData.Hardware.CpuInfo.Hz) / 1000000, 0)}}, @{L = 'Memory GB'; E = {[math]::Round($_.memorytotalgb, 0)}}, `
                    @{L = 'NUMA Nodes'; E = {$_.ExtensionData.Hardware.NumaInfo.NumNodes}}, @{L = 'NIC Count'; E = {$VMHostHardware.NicCount}}, @{L = 'Maximum EVC Mode'; E = {$_.MaxEVCMode}}, `
                    @{N = 'Power Management Policy'; E = {$_.ExtensionData.Hardware.CpuPowerManagementInfo.CurrentPolicy}}, @{N = 'Scratch Location'; E = {$ScratchLocation.Value}}, @{N = 'Bios Version'; E = {$_.ExtensionData.Hardware.BiosInfo.BiosVersion}}, `
                    @{N = 'Bios Release Date'; E = {$_.ExtensionData.Hardware.BiosInfo.ReleaseDate}}, @{N = 'ESXi Version'; E = {$_.version}}, @{N = 'ESXi Build'; E = {$_.build}}, @{N = 'Uptime Days'; E = {$uptime.UptimeDays}}
                    if ($HealthCheck.VMHost.ScratchLocation) {
                        $VMhostspec | Where-Object {$_.'Scratch Location' -eq '/tmp/scratch'} | Set-Style -Style Warning -Property 'Scratch Location'
                    }
                    $VMhostspec | Table -Name "$VMhost Specifications" -List -ColumnWidths 50, 50 

                    # ESXi Host Boot Devices
                    Section -Style Heading4 'Boot Devices' {
                        $BootDevice = Get-ESXiBootDevice -VMHostname $VMhost | Select-Object Host, Device, @{L = 'Boot Type'; E = {$_.BootType}}, Vendor, Model, @{L = 'Size MB'; E = {$_.SizeMB}}, @{L = 'Is SAS'; E = {$_.IsSAS}}, @{L = 'Is SSD'; E = {$_.IsSSD}}, `
                        @{L = 'Is USB'; E = {$_.IsUSB}}
                        $BootDevice | Table -Name "$VMhost Boot Devices" -List -ColumnWidths 50, 50 
                    }

                    # ESXi Host PCI Devices
                    Section -Style Heading4 'PCI Devices' {
                        $PciHardwareDevice = $esxcli.hardware.pci.list.Invoke() | Where-Object {$_.VMKernelName -like "vmhba*" -OR $_.VMKernelName -like "vmnic*" -OR $_.VMKernelName -like "vmgfx*"} 
                        $VMhostPciDevices = $PciHardwareDevice | Sort-Object VMkernelName | Select-Object @{L = 'VMkernel Name'; E = {$_.VMkernelName}}, @{L = 'PCI Address'; E = {$_.Address}}, @{L = 'Device Class'; E = {$_.DeviceClassName}}, `
                        @{L = 'Device Name'; E = {$_.DeviceName}}, @{L = 'Vendor Name'; E = {$_.VendorName}}, @{L = 'Slot Description'; E = {$_.SlotDescription}}
                        $VMhostPciDevices | Table -Name "$VMhost PCI Devices" 
                    }
                }

                # ESXi Host System Section
                Section -Style Heading3 'System' {
                    Paragraph "The following section details the host system configuration of $VMhost."

                    # ESXi Host Licensing Information
                    Section -Style Heading4 'Licensing' {
                        $ServiceInstance = Get-View ServiceInstance
                        $LicenseManager = Get-View $ServiceInstance.Content.LicenseManager
                        $LicenseManagerAssign = Get-View $LicenseManager.LicenseAssignmentManager
                        $VMHostView = $VMhost | Get-View
                        $VMhostID = $VMHostView.Config.Host.Value
                        $VMHostLM = $LicenseManagerAssign.QueryAssignedLicenses($VMhostID)
                        $LicenseType = $VMHostView | Select-Object @{n = 'License Type'; e = {$VMHostLM.AssignedLicense.Name | Select-Object -Unique}}
                        $Licenses = $VMHost | Select-Object @{L = 'License Type'; E = {$LicenseType.'License Type'}}, @{L = 'License Key'; E = {'*****-*****-*****' + ($_.LicenseKey).Substring(17)}}
                        if ($HealthCheck.VMHost.Licensing) {
                            $Licenses | Where-Object {$_.'License Type' -eq 'Evaluation Mode'} | Set-Style -Style Warning 
                        }
                        $Licenses | Table -Name "$VMhost Licensing" -ColumnWidths 50, 50 
                    }
                
                    # ESXi Host Profile Information
                    if ($VMhost | Get-VMHostProfile) {
                        Section -Style Heading4 'Host Profile' {
                            $VMHostProfile = $VMhost | Get-VMHostProfile | Select-Object Name, Description
                            $VMHostProfile | Table -Name "$VMhost Host Profile" -ColumnWidths 50, 50 
                        }
                    }

                    # ESXi Host Image Profile Information
                    Section -Style Heading4 'Image Profile' {
                        $installdate = Get-InstallDate
                        $esxcli = Get-ESXCli -VMHost $VMhost -V2
                        $ImageProfile = $esxcli.software.profile.get.Invoke()
                        $SecurityProfile = $ImageProfile | Select-Object @{N = 'Image Profile'; E = {$_.Name}}, Vendor, @{N = 'Installation Date'; E = {$installdate.InstallDate}}
                        $SecurityProfile | Table -Name "$VMhost Image Profile" -ColumnWidths 50, 25, 25 
                    }

                    # ESXi Host Time Configuration
                    Section -Style Heading4 'Time Configuration' {
                        $VMHostTimeSettingsHash = @{
                            NtpServer  = @($VMhost | Get-VMHostNtpServer) -join ", "
                            Timezone   = $VMhost.timezone
                            NtpService = ($VMhost | Get-VMHostService | Where-Object {$_.key -eq 'ntpd'}).Running
                        }
                        $VMHostTimeSettings = $VMHostTimeSettingsHash | Select-Object @{L = 'Time Zone'; E = {$_.Timezone}}, @{L = 'NTP Service Running'; E = {$_.NtpService}}, @{L = 'NTP Server(s)'; E = {$_.NtpServer}}
                        if ($HealthCheck.VMHost.TimeConfig) {
                            $VMHostTimeSettings | Where-Object {$_.'NTP Service Running' -eq $False} | Set-Style -Style Critical -Property 'NTP Service Running'
                        }
                        $VMHostTimeSettings | Table -Name "$VMhost Time Configuration" -ColumnWidths 30, 30, 40
                    }

                    # ESXi Host Syslog Configuration
                    Section -Style Heading4 'Syslog Configuration' {
                        ### TODO: Syslog Rotate & Size, Log Directory (Adv Settings)
                        $SyslogConfig = $VMhost | Get-VMHostSysLogServer | Select-Object @{L = 'SysLog Server'; E = {$_.Host}}, Port
                        $SyslogConfig | Table -Name "$VMhost Syslog Configuration" -ColumnWidths 50, 50 
                    }

                    # ESXi Update Manager Baseline Information
                    $VMHostBaselines = $VMhost | Get-PatchBaseline
                    if ($VMHostBaselines) {
                        Section -Style Heading4 'Update Manager Baselines' {
                            $VMHostBaselines = $VMHostBaselines | Sort-object Name | Select-Object Name, Description, @{L = 'Type'; E = {$_.BaselineType}}, @{L = 'Target Type'; E = {$_.TargetType}}, @{L = 'Last Update Time'; E = {$_.LastUpdateTime}}, @{L = 'Number of Patches'; E = {($_.CurrentPatches).count}}
                            $VMHostBaselines | Table -Name "$VMhost Update Manager Baselines"
                        }
                    }

                    $VMhostCompliance = $VMhost | Get-Compliance
                    if ($VMhostCompliance) {
                        Section -Style Heading4 'Update Manager Compliance' {
                            $VMhostCompliance = $VMhostCompliance | Sort-object Baseline | Select-Object @{L = 'Baseline'; E = {($_.Baseline).Name}}, Status
                            if ($HealthCheck.VMHost.VUMCompliance) {
                                $VMhostCompliance | Where-Object {$_.Status -eq 'NotCompliant'} | Set-Style -Style Critical
                            }
                            $VMhostCompliance | Table -Name "$VMhost Update Manager Compliance"
                        }
                    }

                    if ($InfoLevel.VMHost -ge 4) {
                        # ESXi Host Advanced System Settings
                        Section -Style Heading4 'Advanced System Settings' {
                            $AdvSettings = $VMHost | Get-AdvancedSetting | Sort-Object Name | Select-Object Name, Value
                            $AdvSettings | Table -Name "$VMhost Advanced System Settings" -ColumnWidths 50, 50 
                        }
                    
                        # ESXi Host Software VIBs
                        Section -Style Heading4 'Software VIBs' {
                            $VMhostVibs = $esxcli.software.vib.list.Invoke() | Sort-Object InstallDate -Descending | Select-Object Name, ID, Version, Vendor, @{L = 'Acceptance Level'; E = {$_.AcceptanceLevel}}, @{L = 'Creation Date'; E = {$_.CreationDate}}, `
                            @{L = 'Install Date'; E = {$_.InstallDate}}
                            $VMhostVibs | Table -Name "$VMhost Software VIBs" 
                        }
                    }

                }

                # ESXi Host Storage Section
                Section -Style Heading3 'Storage' {
                    Paragraph "The following section details the host storage configuration of $VMhost."
                
                    # ESXi Host Datastore Specifications
                    Section -Style Heading4 'Datastores' {
                        $VMhostDS = $VMhost | Get-Datastore | Sort-Object name | Select-Object name, type, @{L = 'Version'; E = {$_.FileSystemVersion}}, @{L = 'Total Capacity GB'; E = {[math]::Round($_.CapacityGB, 2)}}, `
                        @{L = 'Used Capacity GB'; E = {[math]::Round((($_.CapacityGB) - ($_.FreeSpaceGB)), 2)}}, @{L = 'Free Space GB'; E = {[math]::Round($_.FreeSpaceGB, 2)}}, @{L = '% Used'; E = {[math]::Round((100 - (($_.FreeSpaceGB) / ($_.CapacityGB) * 100)), 2)}}             
                        if ($Healthcheck) {
                            $VMhostDS | Where-Object {$_.'% Used' -ge 90} | Set-Style -Style Critical
                            $VMhostDS | Where-Object {$_.'% Used' -ge 75 -and $_.'% Used' -lt 90} | Set-Style -Style Warning
                        }
                        $VMhostDS | Table -Name "$VMhost Datastores" 
                    }
                
                    # ESXi Host Storage Adapater Information
                    $VMHostHba = $VMhost | Get-VMHostHba
                    if ($VMHostHba) {
                        Section -Style Heading4 'Storage Adapters' {
                            $VMHostHbaFC = $VMhost | Get-VMHostHba -Type FibreChannel
                            if ($VMHostHbaFC) {
                                Paragraph "The following table details the fibre channel storage adapters for $VMhost."
                                Blankline
                                $VMHostHbaFC = $VMhost | Get-VMHostHba -Type FibreChannel | Sort-Object Device | Select-Object Device, Type, Model, Driver, `
                                @{L = 'Node WWN'; E = {([String]::Format("{0:X}", $_.NodeWorldWideName) -split "(\w{2})" | Where-Object {$_ -ne ""}) -join ":" }}, `
                                @{L = 'Port WWN'; E = {([String]::Format("{0:X}", $_.PortWorldWideName) -split "(\w{2})" | Where-Object {$_ -ne ""}) -join ":" }}, speed, status
                                $VMHostHbaFC | Table -Name "$VMhost FC Storage Adapters"
                            }

                            $VMHostHbaISCSI = $VMhost | Get-VMHostHba -Type iSCSI
                            if ($VMHostHbaISCSI) {
                                Paragraph "The following table details the iSCSI storage adapters for $VMhost."
                                Blankline
                                $VMHostHbaISCSI = $VMhost | Get-VMHostHba -Type iSCSI | Sort-Object Device | Select-Object Device, @{L = 'iSCSI Name'; E = {$_.IScsiName}}, Model, Driver, @{L = 'Speed'; E = {$_.CurrentSpeedMb}}, status
                                $VMHostHbaISCSI | Table -Name "$VMhost iSCSI Storage Adapters" -List -ColumnWidths 30, 70
                            }
                        }
                    }
                }

                # ESXi Host Network Configuration
                Section -Style Heading3 'Network' {
                    Paragraph "The following section details the host network configuration of $VMhost."

                    ### TODO: DNS Servers, DNS Domain, Search Domains
                
                    Section -Style Heading4 'Physical Adapters' {
                        Paragraph "The following table details the physical network adapters for $VMhost."
                        BlankLine

                        $PhysicalAdapter = $VMhost | Get-VMHostNetworkAdapter -Physical | Select-Object @{L = 'Device Name'; E = {$_.DeviceName}}, @{L = 'MAC Address'; E = {$_.Mac}}, @{L = 'Bitrate/Second'; E = {$_.BitRatePerSec}}, `
                        @{L = 'Full Duplex'; E = {$_.FullDuplex}}, @{L = 'Wake on LAN Support'; E = {$_.WakeOnLanSupported}}
                        $PhysicalAdapter | Table -Name "$VMhost Physical Adapters" -ColumnWidths 20, 20, 20, 20, 20
                    }  
                  
                    Section -Style Heading4 'Cisco Discovery Protocol' {    
                        $CDPInfo = $VMhost | Get-VMHostNetworkAdapterCDP | Select-Object NIC, Connected, Switch, @{L = 'Hardware Platform'; E = {$_.HardwarePlatform}}, @{L = 'Port ID'; E = {$_.PortId}}
                        $CDPInfo | Table -Name "$VMhost CDP Information" -ColumnWidths 20, 20, 20, 20, 20
                    }

                    Section -Style Heading4 'VMkernel Adapters' {
                        Paragraph "The following table details the VMkernel adapters for $VMhost"
                        BlankLine

                        $VMHostNetworkAdapter = $VMhost | Get-VMHostNetworkAdapter -VMKernel | Sort-Object DeviceName | Select-Object @{L = 'Device Name'; E = {$_.DeviceName}}, @{L = 'Network Label'; E = {$_.PortGroupName}}, @{L = 'MTU'; E = {$_.Mtu}}, `
                        @{L = 'MAC Address'; E = {$_.Mac}}, @{L = 'IP Address'; E = {$_.IP}}, @{L = 'Subnet Mask'; E = {$_.SubnetMask}}, `
                        @{L = 'vMotion Traffic'; E = {$_.vMotionEnabled}}, @{L = 'FT Logging'; E = {$_.FaultToleranceLoggingEnabled}}, `
                        @{L = 'Management Traffic'; E = {$_.ManagementTrafficEnabled}}, @{L = 'vSAN Traffic'; E = {$_.VsanTrafficEnabled}}
                        $VMHostNetworkAdapter | Table -Name "$VMhost VMkernel Adapters" -List -ColumnWidths 50, 50 
                    }

                    $VSSwitches = $VMhost | Get-VirtualSwitch -Standard | Sort-Object Name
                    if ($VSSwitches) {
                        Section -Style Heading4 'Standard Virtual Switches' {
                            Paragraph "The following sections detail the standard virtual switch configuration for $VMhost."
                            BlankLine
                            $VSSGeneral = $VSSwitches | Get-NicTeamingPolicy | Select-Object @{L = 'Name'; E = {$_.VirtualSwitch}}, @{L = 'MTU'; E = {$_.VirtualSwitch.Mtu}}, @{L = 'Number of Ports'; E = {$_.VirtualSwitch.NumPorts}}, `
                            @{L = 'Number of Ports Available'; E = {$_.VirtualSwitch.NumPortsAvailable}}, @{L = 'Load Balancing'; E = {$_.LoadBalancingPolicy}}, @{L = 'Failover Detection'; E = {$_.NetworkFailoverDetectionPolicy}}, `
                            @{L = 'Notify Switches'; E = {$_.NotifySwitches}}, @{L = 'Failback Enabled'; E = {$_.FailbackEnabled}}, @{L = 'Active NICs'; E = {($_.ActiveNic) -join ", "}}, `
                            @{L = 'Standby NICs'; E = {($_.StandbyNic) -join ", "}}, @{L = 'Unused NICs'; E = {($_.UnusedNic) -join ", "}} 
                            $VSSGeneral | Table -Name "$VMhost vSwitch Properties" -List -ColumnWidths 50, 50
                        }
                        
                        $VSSSecurity = $VSSwitches | Get-SecurityPolicy
                        if ($VSSSecurity) {
                            Section -Style Heading4 'Virtual Switch Security Policy' {
                                $VSSSecurity = $VSSSecurity | Select-Object @{L = 'vSwitch'; E = {$_.VirtualSwitch}}, @{L = 'MAC Address Changes'; E = {$_.MacChanges}}, @{L = 'Forged Transmits'; E = {$_.ForgedTransmits}}, `
                                @{L = 'Promiscuous Mode'; E = {$_.AllowPromiscuous}} | Sort-Object vSwitch
                                $VSSSecurity | Table -Name "$VMhost vSwitch Security Policy" 
                            }
                        }                    

                        $VSSPortgroupNicTeaming = $VSSwitches | Get-NicTeamingPolicy
                        if ($VSSPortgroupNicTeaming) {
                            Section -Style Heading4 'Virtual Switch NIC Teaming' {
                                $VSSPortgroupNicTeaming = $VSSPortgroupNicTeaming | Select-Object @{L = 'vSwitch'; E = {$_.VirtualSwitch}}, @{L = 'Load Balancing'; E = {$_.LoadBalancingPolicy}}, `
                                @{L = 'Failover Detection'; E = {$_.NetworkFailoverDetectionPolicy}}, @{L = 'Notify Switches'; E = {$_.NotifySwitches}}, @{L = 'Failback Enabled'; E = {$_.FailbackEnabled}}, @{L = 'Active NICs'; E = {($_.ActiveNic) -join ", "}}, `
                                @{L = 'Standby NICs'; E = {($_.StandbyNic) -join ", "}}, @{L = 'Unused NICs'; E = {($_.UnusedNic) -join ", "}} | Sort-Object vSwitch
                                $VSSPortgroupNicTeaming | Table -Name "$VMhost vSwitch NIC Teaming" 
                            }
                        }                        
                        
                        $VSSPortgroups = $VSSwitches | Get-VirtualPortGroup -Standard
                        if ($VSSPortgroups) {
                            Section -Style Heading4 'Virtual Port Groups' {
                                $VSSPortgroups = $VSSPortgroups | Select-Object @{L = 'vSwitch'; E = {$_.VirtualSwitchName}}, @{L = 'Portgroup'; E = {$_.Name}}, @{L = 'VLAN ID'; E = {$_.VLanId}} | Sort-Object vSwitch, Portgroup
                                $VSSPortgroups | Table -Name "$VMhost vSwitch Port Group Information" 
                            }
                        }                
                        
                        $VSSPortgroupSecurity = $VSSwitches | Get-VirtualPortGroup | Get-SecurityPolicy 
                        if ($VSSPortgroupSecurity) {
                            Section -Style Heading4 'Virtual Port Group Security Policy' {
                                $VSSPortgroupSecurity = $VSSPortgroupSecurity | Select-Object @{L = 'vSwitch'; E = {$_.virtualportgroup.virtualswitchname}}, @{L = 'Portgroup'; E = {$_.VirtualPortGroup}}, @{L = 'MAC Changes'; E = {$_.MacChanges}}, `
                                @{L = 'Forged Transmits'; E = {$_.ForgedTransmits}}, @{L = 'Promiscuous Mode'; E = {$_.AllowPromiscuous}} | Sort-Object vSwitch, VirtualPortGroup
                                $VSSPortgroupSecurity | Table -Name "$VMhost vSwitch Port Group Security Policy" 
                            }
                        }                    

                        $VSSPortgroupNicTeaming = $VSSwitches | Get-VirtualPortGroup  | Get-NicTeamingPolicy 
                        if ($VSSPortgroupNicTeaming) {
                            Section -Style Heading4 'Virtual Port Group NIC Teaming' {
                                $VSSPortgroupNicTeaming = $VSSPortgroupNicTeaming | Select-Object @{L = 'vSwitch'; E = {$_.virtualportgroup.virtualswitchname}}, @{L = 'Portgroup'; E = {$_.VirtualPortGroup}}, @{L = 'Load Balancing'; E = {$_.LoadBalancingPolicy}}, `
                                @{L = 'Failover Detection'; E = {$_.NetworkFailoverDetectionPolicy}}, @{L = 'Notify Switches'; E = {$_.NotifySwitches}}, @{L = 'Failback Enabled'; E = {$_.FailbackEnabled}}, @{L = 'Active NICs'; E = {($_.ActiveNic) -join ", "}}, `
                                @{L = 'Standby NICs'; E = {($_.StandbyNic) -join ", "}}, @{L = 'Unused NICs'; E = {($_.UnusedNic) -join ", "}} | Sort-Object vSwitch, VirtualPortGroup
                                $VSSPortgroupNicTeaming | Table -Name "$VMhost vSwitch Port Group NIC Teaming" 
                            }
                        }                        
                    }
                }                

                # ESXi Host Security Section
                Section -Style Heading3 'Security' {
                    Paragraph "The following section details the host security configuration of $VMhost."
                
                    Section -Style Heading4 'Lockdown Mode' {
                        $LockDownMode = $VMhost | Get-View | Select-Object @{N = 'Lockdown Mode'; E = {$_.Config.AdminDisabled}}
                        $LockDownMode | Table -Name "$VMhost Lockdown Mode" -List -ColumnWidths 50, 50
                    }

                    Section -Style Heading4 'Services' {
                        $Services = $VMhost | Get-VMHostService | Sort-Object Key | Select-Object @{N = 'Name'; E = {$_.Key}}, Label, Policy, Running, Required
                        if ($Healthcheck) {
                            $Services | Where-Object {$_.'Name' -eq 'TSM-SSH' -and $_.Running} | Set-Style -Style Warning
                            $Services | Where-Object {$_.'Name' -eq 'TSM' -and $_.Running} | Set-Style -Style Warning
                            $Services | Where-Object {$_.'Name' -eq 'ntpd' -and $_.Running -eq $False} | Set-Style -Style Critical
                        }
                        $Services | Table -Name "$VMhost Services" 
                    }

                    Section -Style Heading4 'Firewall' {
                        $Firewall = $VMhost | Get-VMHostFirewallException | Sort-Object Name | Select-Object Name, Enabled, @{N = 'Incoming Ports'; E = {$_.IncomingPorts}}, @{N = 'Outgoing Ports'; E = {$_.OutgoingPorts}}, Protocols, @{N = 'Service Running'; E = {$_.ServiceRunning}}
                        $Firewall | Table -Name "$VMhost Firewall Configuration" 
                    }

                    Section -Style Heading4 'Authentication Services' {
                        $AuthServices = $VMhost | Get-VMHostAuthentication | Select-Object Domain, @{N = 'Domain Membership'; E = {$_.DomainMembershipStatus}}, @{N = 'Trusted Domains'; E = {$_.TrustedDomains}}
                        $AuthServices | Table -Name "$VMhost Authentication Services" -ColumnWidths 25, 25, 50 
                    }

                    <#
                Section -Style Heading4 'Host Certificate' {
                    ### TODO: Host Certificate
                }
                #>
                }

                # VMHost / Virtual Machines Section
                $VMHostVM = $VMhost | Get-VM
                if ($VMHostVM) {
                    Section -Style Heading3 'Virtual Machines' {
                        Paragraph "The following section details virtual machine settings for $VMhost."
                        Blankline
                        # Virtual Machine Information
                        $VMHostVM = $VMHostVM | Sort-Object Name | Select-Object Name, @{L = 'Power State'; E = {$_.powerstate}}, @{L = 'CPUs'; E = {$_.NumCpu}}, @{L = 'Cores per Socket'; E = {$_.CoresPerSocket}}, @{L = 'Memory GB'; E = {[math]::Round(($_.memoryGB), 2)}}, @{L = 'Provisioned GB'; E = {[math]::Round(($_.ProvisionedSpaceGB), 2)}}, `
                        @{L = 'Used GB'; E = {[math]::Round(($_.UsedSpaceGB), 2)}}, @{L = 'HW Version'; E = {$_.version}}, @{L = 'VM Tools Status'; E = {$_.ExtensionData.Guest.ToolsStatus}}
                        if ($Healthcheck) {
                            $VMHostVM | Where-Object {$_.'VM Tools Status' -eq 'toolsNotInstalled' -or $_.'VM Tools Status' -eq 'toolsOld'} | Set-Style -Style Warning -Property 'VM Tools Status'
                        }
                        $VMHostVM | Table -Name "$VMhost VM Summary"
                
                        # VM Startup/Shutdown Information
                        $VMStartPolicy = $VMhost | Get-VMStartPolicy | Where-Object {$_.StartAction -ne 'None'}
                        if ($VMStartPolicy) {
                            Section -Style Heading4 'VM Startup/Shutdown' {
                                $VMStartPolicies = $VMStartPolicy | Select-Object @{L = 'VM Name'; E = {$_.VirtualMachineName}}, @{L = 'Start Action'; E = {$_.StartAction}}, `
                                @{L = 'Start Delay'; E = {$_.StartDelay}}, @{L = 'Start Order'; E = {$_.StartOrder}}, @{L = 'Stop Action'; E = {$_.StopAction}}, @{L = 'Stop Delay'; E = {$_.StopDelay}}, `
                                @{L = 'Wait for Heartbeat'; E = {$_.WaitForHeartbeat}}
                                $VMStartPolicies | Table -Name "$VMhost VM Startup/Shutdown Policy" 
                            }
                        }
                
                        <#
                # VM Swap File Location
                Section -Style Heading4 'VM Swap File Location' {
                    ### TODO: Swap File Location
                }
                #>
                    }
                }
            }
        }
    }
    PageBreak
}    

# Create Distributed Virtual Switch Section if they exist
$Script:VDSwitches = Get-VDSwitch
if ($VDSwitches) {
    Section -Style Heading1 'Distributed Virtual Switches' {
        Paragraph 'The following section details the Distributed Virtual Switch configuration.'
        BlankLine

        # Distributed Virtual Switch Summary
        $VDSSummary = $VDSwitches | Select-Object @{L = 'VDSwitch'; E = {$_.Name}}, Datacenter, @{L = 'Manufacturer'; E = {$_.Vendor}}, Version, @{L = 'Number of Uplinks'; E = {$_.NumUplinkPorts}}, @{L = 'Number of Ports'; E = {$_.NumPorts}}, `
        @{L = 'Host Count'; E = {(($_ | Get-VMhost).count)}}        
        $VDSSummary | Table -Name 'Distributed Virtual Switch Summary'

        # Distributed Virtual Switch Detailed Information
        foreach ($VDS in ($VDSwitches)) {
            Section -Style Heading2 $VDS {  
                Section -Style Heading3 'General Properties' {
                    $VDSwitch = Get-VDSwitch $VDS | Select-Object Name, Datacenter, @{L = 'Manufacturer'; E = {$_.Vendor}}, Version, @{L = 'Number of Uplinks'; E = {$_.NumUplinkPorts}}, `
                    @{L = 'Number of Ports'; E = {$_.NumPorts}}, @{L = 'MTU'; E = {$_.Mtu}}, @{L = 'Network I/O Control Enabled'; E = {$_.ExtensionData.Config.NetworkResourceManagementEnabled}}, `
                    @{L = 'Discovery Protocol'; E = {$_.LinkDiscoveryProtocol}}, @{L = 'Discovery Protocol Operation'; E = {$_.LinkDiscoveryProtocolOperation}}, @{L = 'Connected Hosts'; E = {(($_ | Get-VMhost | Sort-Object Name).Name -join ", ")}}
                    $VDSwitch | Table -Name "$VDS General Properties" -List -ColumnWidths 50, 50 
                }

                $VdsUplinks = $VDS | Get-VDPortgroup | Where-Object {$_.IsUplink -eq $true} | Get-VDPort
                if ($VdsUplinks) {
                    Section -Style Heading3 'Uplinks' {
                        $VdsUplinks = $VdsUplinks | Sort-Object Switch, ProxyHost, Name | Select-Object @{L = 'VDSwitch'; E = {$_.Switch}}, @{L = 'VM Host'; E = {$_.ProxyHost}}, @{L = 'Uplink Name'; E = {$_.Name}}, @{L = 'Physical Network Adapter'; E = {$_.ConnectedEntity}}, @{L = 'Uplink Port Group'; E = {$_.Portgroup}}
                        $VdsUplinks | Table -Name "$VDS Uplinks"
                    }
                }                
                
                Section -Style Heading3 'Security' {
                    $VDSSecurity = $VDS | Get-VDSecurityPolicy | Select-Object VDSwitch, @{L = 'Allow Promiscuous'; E = {$_.AllowPromiscuous}}, @{L = 'Forged Transmits'; E = {$_.ForgedTransmits}}, @{L = 'MAC Address Changes'; E = {$_.MacChanges}}
                    $VDSSecurity | Table -Name "$VDS Security" 
                }

                Section -Style Heading3 'Traffic Shaping' {
                    $VDSTrafficShaping = $VDS | Get-VDTrafficShapingPolicy -Direction Out
                    [Array]$VDSTrafficShaping += $VDS | Get-VDTrafficShapingPolicy -Direction In
                    $VDSTrafficShaping = $VDSTrafficShaping | Sort-Object Direction | Select-Object VDSwitch, Direction, Enabled, @{L = 'Average Bandwidth (kbit/s)'; E = {$_.AverageBandwidth}}, @{L = 'Peak Bandwidth (kbit/s)'; E = {$_.PeakBandwidth}}, @{L = 'Burst Size (KB)'; E = {$_.BurstSize}}
                    $VDSTrafficShaping | Table -Name "$VDS Traffic Shaping"
                }

                Section -Style Heading3 'Port Groups' {
                    $VDSPortgroups = $VDS | Get-VDPortgroup | Sort-Object Name | Select-Object VDSwitch, @{L = 'Portgroup'; E = {$_.Name}}, Datacenter, @{L = 'VLAN Configuration'; E = {$_.VlanConfiguration}}, @{L = 'Port Binding'; E = {$_.PortBinding}}, @{L = 'Number of Ports'; E = {$_.NumPorts}}
                    $VDSPortgroups | Table -Name "$VDS Port Group Information" 
                }

                Section -Style Heading4 "Port Group Security" {
                    $VDSPortgroupSecurity = $VDS | Get-VDPortgroup | Get-VDSecurityPolicy | Select-Object @{L = 'VDSwitch'; E = {($VDS.Name)}} , @{L = 'Port Group'; E = {$_.VDPortgroup}}, @{L = 'Allow Promiscuous'; E = {$_.AllowPromiscuous}}, @{L = 'Forged Transmits'; E = {$_.ForgedTransmits}}, @{L = 'MAC Address Changes'; E = {$_.MacChanges}}
                    $VDSPortgroupSecurity | Table -Name "$VDS Portgroup Security"
                }
                
                Section -Style Heading4 "Port Group NIC Teaming" {
                    $VDSPortgroupNICTeaming = $VDS | Get-VDPortgroup | Get-VDUplinkTeamingPolicy | Sort-Object VDPortgroup | Select-Object @{L = 'VDSwitch'; E = {($VDS.Name)}} , @{L = 'Port Group'; E = {$_.VDPortgroup}}, @{L = 'Load Balancing'; E = {$_.LoadBalancingPolicy}}, @{L = 'Failover Detection'; E = {$_.FailoverDetectionPolicy}}, `
                    @{L = 'Notify Switches'; E = {$_.NotifySwitches}}, @{L = 'Failback Enabled'; E = {$_.EnableFailback}}, @{L = 'Active Uplinks'; E = {($_.ActiveUplinkPort) -join ", "}}, @{L = 'Standby Uplinks'; E = {($_.StandbyUplinkPort) -join ", "}}, @{L = 'Unused Uplinks'; E = {@($_.UnusedUplinkPort) -join ", "}}
                    $VDSPortgroupNICTeaming | Table -Name "$VDS Portgroup NIC Teaming"
                }  

                $VDSPvlan = $VDS | Get-VDSwitchPrivateVLAN | Sort-Object PrimaryVlanId, PrivateVlanType, SecondaryVlanId | Select-Object @{L = 'Primary VLAN ID'; E = {$_.PrimaryVlanId}}, @{L = 'Private VLAN Type'; E = {$_.PrivateVlanType}}, @{L = 'Secondary VLAN ID'; E = {$_.SecondaryVlanId}}
                if ($VDSPvlan) {
                    Section -Style Heading3 'Private VLANs' {
                        $VDSPvlan | Table -Name "$VDS Private VLANs"
                    }
                }            
                <#
                Section -Style Heading3 'LACP' {
                }
                                   

                Section -Style Heading3 'Netflow' {
                }

                Section -Style Heading3 'Network I/O Control' {
                }
                #>
            }
        }
    }   
    PageBreak
}

# Storage Section
$Script:Datastores = Get-Datastore 
If ($Datastores) {
    Section -Style Heading1 'Storage' {
        Paragraph 'The following section details the VMware vSphere storage configuration.'
        BlankLine

        # Datastore Summary
        $DatastoreSummary = $Datastores | Sort-Object Name | Select-Object name, type, @{L = 'Total Capacity GB'; E = {[math]::Round($_.CapacityGB, 2)}}, @{L = 'Used Capacity GB'; E = {[math]::Round((($_.CapacityGB) - ($_.FreeSpaceGB)), 2)}}, `
        @{L = 'Free Space GB'; E = {[math]::Round($_.FreeSpaceGB, 2)}}, @{L = '% Used'; E = {[math]::Round((100 - (($_.FreeSpaceGB) / ($_.CapacityGB) * 100)), 2)}}, @{L = 'Host Count'; E = {($_ | Get-VMhost).count}}
        if ($Healthcheck) {
            $DatastoreSummary | Where-Object {$_.'% Used' -ge 90} | Set-Style -Style Critical
            $DatastoreSummary | Where-Object {$_.'% Used' -ge 75 -and $_.'% Used' -lt 90} | Set-Style -Style Warning
        }
        $DatastoreSummary | Table -Name 'Datastore Summary' 
 
        # Datastore Specifications
        Section -Style Heading2 'Datastore Specifications' {
            $DatastoreSpecs = $Datastores | Sort-Object datacenter, name | Select-Object name, datacenter, type, @{L = 'Version'; E = {$_.FileSystemVersion}}, State, @{L = 'SIOC Enabled'; E = {$_.StorageIOControlEnabled}}, `
            @{L = 'Congestion Threshold ms'; E = {$_.CongestionThresholdMillisecond}}   
            $DatastoreSpecs | Table -Name 'Datastore Specifications' 
        }
        
        # Get VMFS volumes. Ignore local SCSILuns.
        $ScsiLuns = $Datastores | Where-Object {$_.Type -eq 'vmfs'} | Get-ScsiLun | Where-Object {$_.IsLocal -eq $false}
        if ($ScsiLuns) {
            Section -Style Heading2 'SCSI LUN Information' {
                $SCSILunTable = $ScsiLuns | Sort-Object vmhost | Select-Object vmhost, @{L = 'Runtime Name'; E = {$_.runtimename}}, @{L = 'Canonical Name'; E = {$_.canonicalname}}, @{L = 'Capacity GB'; E = {[math]::Round($_.CapacityGB, 2)}}, vendor, model, @{L = 'Is SSD'; E = {$_.isssd}}, @{L = 'Multipath Policy'; E = {$_.multipathpolicy}}
                $SCSILunTable | Table -Name 'SCSI LUN Information'
            }     
        }
    
        $DSClusters = Get-DatastoreCluster
        if ($DSClusters) {
            # Datastore Cluster Information
            Section -Style Heading2 'Datastore Clusters' {
                $DSClusters = $DSClusters | Sort-Object Name | Select-Object Name, @{L = 'SDRS Automation Level'; E = {$_.SdrsAutomationLevel}}, @{L = 'Space Utilization Threshold %'; E = {$_.SpaceUtilizationThresholdPercent}}, @{L = 'I/O Load Balance Enabled'; E = {$_.IOLoadBalanceEnabled}}, @{L = 'I/O Latency Threshold ms'; E = {$_.IOLatencyThresholdMillisecond}}, `
                @{L = 'Capacity GB'; E = {[math]::Round($_.CapacityGB, 2)}}, @{L = 'FreeSpace GB'; E = {[math]::Round($_.FreeSpaceGB, 2)}}, @{L = '% Used'; E = {[math]::Round((100 - (($_.FreeSpaceGB) / ($_.CapacityGB) * 100)), 2)}}
                if ($Healthcheck) {
                    $DsClusters | Where-Object {$_.'% Used' -ge 90} | Set-Style -Style Critical
                    $DsClusters | Where-Object {$_.'% Used' -ge 75 -and $_.'% Used' -lt 90} | Set-Style -Style Warning
                }   
                $DsClusters | Table -Name 'Datastore Clusters' 
            }
        }
    }
    PageBreak
}    

# Virtual Machine Section
$Script:VMs = Get-VM 
if ($VMs) {
    Section -Style Heading1 'Virtual Machines' {
        Paragraph 'The following section provides detailed information about Virtual Machines.'
        BlankLine
        # Virtual Machine Information
        $VMSummary = $VMs | Sort-Object Name | Select-Object Name, @{L = 'Power State'; E = {$_.powerstate}}, @{L = 'CPUs'; E = {$_.NumCpu}}, @{L = 'Cores per Socket'; E = {$_.CoresPerSocket}}, @{L = 'Memory GB'; E = {[math]::Round(($_.memoryGB), 2)}}, @{L = 'Provisioned GB'; E = {[math]::Round(($_.ProvisionedSpaceGB), 2)}}, `
        @{L = 'Used GB'; E = {[math]::Round(($_.UsedSpaceGB), 2)}}, @{L = 'HW Version'; E = {$_.version}}, @{L = 'VM Tools Status'; E = {$_.ExtensionData.Guest.ToolsStatus}}
        if ($Healthcheck) {
            $VMSummary | Where-Object {$_.'VM Tools Status' -eq 'toolsNotInstalled' -or $_.'VM Tools Status' -eq 'toolsOld'} | Set-Style -Style Warning -Property 'VM Tools Status'
        }
        $VMSummary | Table -Name 'VM Summary' 
    
        # VM Snapshot Information
        $VMSnapshots = $VMs | Get-Snapshot 
        if ($VMSnapshots) {
            Section -Style Heading2 'VM Snapshots' {
                $VMSnapshots = $VMSnapshots | Select-Object @{L = 'Virtual Machine'; E = {$_.VM}}, Name, Description, @{L = 'Days Old'; E = {((Get-Date) - $_.Created).Days}} 
                if ($Healthcheck) {
                    $VMSnapshots | Where-Object {$_.'Days Old' -ge 7} | Set-Style -Style Warning -Property 'Days Old'
                    $VMSnapshots | Where-Object {$_.'Days Old' -ge 14} | Set-Style -Style Critical -Property 'Days Old'
                }
                $VMSnapshots | Table -Name 'VM Snapshots'
            }
        }
    
    }
    #PageBreak
}

# VMware Update Manager Section
Section -Style Heading1 'VMware Update Manager' {
    Paragraph 'The following section provides detailed information about VMware Update Manager.'
    $Script:VUMBaselines = Get-PatchBaseline
    if ($VUMBaselines) {
        Section -Style Heading2 'Baselines' {
            #Baseline Information
            $VUMBaselines = $VUMBaselines | Sort-Object Name | Select-Object Name, Description, @{L = 'Type'; E = {$_.BaselineType}}, @{L = 'Target Type'; E = {$_.TargetType}}, @{L = 'Last Update Time'; E = {$_.LastUpdateTime}}, @{L = 'Number of Patches'; E = {($_.CurrentPatches).count}}
            $VUMBaselines | Table -Name 'VMware Update Manager Baselines'
        }
    }
    BlankLine
    $VUMPatches = Get-Patch
    if ($VUMPatches -and $InfoLevel.VUM -ge 4) {
        Section -Style Heading2 'Patches' {
            # Patch Information
            $VUMPatches = Get-Patch | Sort-Object -Descending ReleaseDate | Select-Object Name, @{L = 'Product'; E = {($_.Product).Name}}, Description, @{L = 'Release Date'; E = {$_.ReleaseDate}}, Severity, @{L = 'Vendor Id'; E = {$_.IdByVendor}}
            $VUMPatches | Table -Name 'VMware Update Manager Patches'
        }
    }
}
#endregion Script Body

# Disconnect vCenter Server
$Null = Disconnect-VIServer -Server $IP -Confirm:$false