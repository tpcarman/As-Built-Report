#requires -Modules @{ModuleName = "PScribo"; ModuleVersion = "0.7.23"},CiscoUcsPS

#region Configuration Settings
###############################################################################################
#                                    CONFIG SETTINGS                                          #
###############################################################################################
$ScriptPath = (Get-Location).Path
#$ReportConfigFile = Join-Path $ScriptPath $("Reports\$Type\$Type.json")
$ReportConfigFile = Join-Path $ScriptPath $("Reports\UCS\UCS.json")
If (Test-Path $ReportConfigFile -ErrorAction SilentlyContinue) {
    $ReportConfig = Get-Content $ReportConfigFile | ConvertFrom-json
}
# If custom style not set, use Nutanix style
if (!$StyleName) {
    .\Styles\Cisco.ps1
}

# Connect to Cisco UCS domain using supplied credentials
$UCSC = Connect-Ucs -Name $Target -Credential $Credentials
#endregion Configuration Settings

#region Script Body
###############################################################################################
#                                       SCRIPT BODY                                           #
###############################################################################################


Section -Style Heading1 -Name 'System' {

    Section -Style Heading2 -Name 'Status' {

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
$Null = Disconnect-Ucs -Ucs $Target