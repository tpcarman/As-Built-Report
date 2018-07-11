#requires -Modules @{ModuleName = "PScribo"; ModuleVersion = "0.7.23"},CiscoUcsPS

#region Configuration Settings
###############################################################################################
#                                    CONFIG SETTINGS                                          #
###############################################################################################

# If custom style not set, use Cisco style
if (!$StyleName) {
    .\Styles\Cisco.ps1
}

# Connect to Cisco UCS domain using supplied credentials
$handle = Connect-Ucs -Name $Target -Credential $Credentials
#endregion Configuration Settings

#region Script Body
###############################################################################################
#                                       SCRIPT BODY                                           #
###############################################################################################


Section -Style Heading1 -Name 'System' {

    Section -Style Heading2 -Name 'Status' {
        $system = Get-UcsStatus -Ucs $handle #| Select-Object Name, VirtualIpv4Address, HaReady, FiALeadership, FiAManagementServicesState, FiBLeadership, FiBManagementServicesState
        $a = @{
            Name         = $system.Name
            VIP          = $system.VirtualIpv4Address
            UCSM         = (Get-UcsMgmtController -Ucs $handle -Subject system | Get-UcsFirmwareRunning).Version
            HaReady      = $system.HaReady
            #--- Get Full State and Logical backup configuration ---#
            BackupPolicy = (Get-UcsMgmtBackupPolicy -Ucs $handle | Select AdminState).AdminState
            ConfigPolicy = (Get-UcsMgmtCfgExportPolicy -Ucs $handle | Select AdminState).AdminState
            #--- Get Call Home admin state ---#
            CallHome     = (Get-UcsCallHome -Ucs $handle | Select-Object AdminState).AdminState
            <#
            #--- Get System and Server power statistics ---#
            $DomainHash.System.Chassis_Power = @()
            $DomainHash.System.Chassis_Power += Get-UcsChassisStats -Ucs $handle | Select-Object Dn, InputPower, InputPowerAvg, InputPowerMax, OutputPower, OutputPowerAvg, OutputPowerMax, Suspect
            $DomainHash.System.Chassis_Power | % {$_.Dn = $_.Dn -replace ('(sys[/])|([/]stats)', "") }
            $DomainHash.System.Server_Power = @()
            $DomainHash.System.Server_Power += Get-UcsComputeMbPowerStats -Ucs $handle | Sort-Object -Property Dn | Select-Object Dn, ConsumedPower, ConsumedPowerAvg, ConsumedPowerMax, InputCurrent, InputCurrentAvg, InputVoltage, InputVoltageAvg, Suspect
            $DomainHash.System.Server_Power | % {$_.Dn = $_.Dn -replace ('([/]board.*)', "") }
            #--- Get Server temperatures ---#
            $DomainHash.System.Server_Temp = @()
            $DomainHash.System.Server_Temp += Get-UcsComputeMbTempStats -Ucs $handle | Sort-Object -Property Ucs, Dn | Select-Object Dn, FmTempSenIo, FmTempSenIoAvg, FmTempSenIoMax, FmTempSenRear, FmTempSenRearAvg, FmTempSenRearMax, FmTempSenRearL, FmTempSenRearLAvg, FmTempSenRearLMax, FmTempSenRearR, FmTempSenRearRAvg, FmTempSenRearRMax, Suspect
            $DomainHash.System.Server_Temp | % {$_.Dn = $_.Dn -replace ('([/]board.*)', "") }
            #>
        }
        $t = $a | select vip, ucsm, HaReady
        $t | table     
    }

    Section -Style Heading2 -Name 'Chassis Power Statistics' {
        
    }

    Section -Style Heading2 -Name 'Server Power Statistics' {
        
    }

    Section -Style Heading2 -Name 'Server Temperature Statistics' {
        
    }
}

Section -Style Heading1 -Name 'Inventory' {

    Section -Style Heading2 -Name 'Fabric Interconnects' {

    }

    Section -Style Heading2 -Name 'Chassis' {
        
    }

    Section -Style Heading2 -Name 'IOMs' {
        
    }

    Section -Style Heading2 -Name 'Blades' {
        
    }

    Section -Style Heading2 -Name 'Rack Servers' {
        $UcsRackUnit = Get-UcsRackUnit | Sort-Object ServerID | Select-Object @{L = 'Rack Id'; E = {$_.ServerId}}, Model, Serial, @{L = 'Service Profile'; E = {$_.AssignedToDn}}, @{L = 'CPUs'; E = {$_.NumOfCpus}}, @{L = 'Cores'; E = {$_.NumOfCores}}, Threads
        <#>
        @{L = 'Available Memory'; E = {$_.AvailableMemory}}, , 
                @{L = 'Number of Adapters'; E = {$_.NumOfAdaptors}}, @{L = 'Number of Ethernet Interfaces'; E = {$_.NumOfEthHostIfs}}, @{L = 'Number of FC Host Interfaces'; E = {$_.NumOfFcHostIfs}}, , Presence, @{L = 'Operability'; E = {$_.OperState}}, 
                    Operability, @{L = 'Power'; E = {$_.OperPower}}, Serial
                $UcsRackUnit | Table -Name 'Server Inventory'
                #>
    }

    Section -Style Heading2 -Name 'Rack Adapters' {
        
    }
}

Section -Style Heading1 -Name 'Policies' {

    Section -Style Heading2 -Name 'System Policies' {
        
    }

    Section -Style Heading2 -Name 'Maintenance Policies' {
        
    }
    
    Section -Style Heading2 -Name 'Host Firmware Packages' {
        
    }

    Section -Style Heading2 -Name 'LDAP' {

        Section -Style Heading3 -Name 'Providers' {
        
        }

        Section -Style Heading3 -Name 'Group Maps' {
        
        }
        
    }
}

Section -Style Heading1 -Name 'Pools' {

    Section -Style Heading2 -Name 'Mgmt IP Pool' {
        
    }

    Section -Style Heading2 -Name 'UUID Pools' {
        
    }

    Section -Style Heading2 -Name 'Server Pools' {
        
    }

    Section -Style Heading2 -Name 'MAC Pools' {
        
    }

    Section -Style Heading2 -Name 'IP Pools' {
        
    }

    Section -Style Heading2 -Name 'WWN Pools' {
        
    }
    
}

Section -Style Heading1 -Name 'Service Profiles' {
    
}

Section -Style Heading1 -Name 'LAN' {
    
    Section -Style Heading2 -Name 'System QoS' {
        
    }

    Section -Style Heading2 -Name 'VLANs' {
        
    }

    Section -Style Heading2 -Name 'LAN Uplinks' {
        
    }

    Section -Style Heading2 -Name 'Server Links' {
        
    }

    Section -Style Heading2 -Name 'Network Control Policies' {
        
    }

    Section -Style Heading2 -Name 'QoS Policies' {
        
    }
}

Section -Style Heading1 -Name 'SAN' {
    
}

Section -Style Heading1 -Name 'Fault Summary' {
    
}
#endregion Script Body

# Disconnect UCS Chassis
$Null = Disconnect-Ucs -Ucs $handle