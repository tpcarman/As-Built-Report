# Documentation-Scripts

A collection of PowerShell scripts to document the configuration of datacentre infrastucture in Text, XML, HTML & MS Word formats.

# Getting Started
Below is a simple list of instructions on how to use these scripts.

## Pre-requisites

All scripts within this repository require [PScribo](https://github.com/iainbrighton/PScribo)

Other PowerShell modules and PSSnapins are dependant on which script you choose to run.

- VMware vSphere As Built [(VMware PowerCLI Module)](https://www.powershellgallery.com/packages/VMware.PowerCLI/10.0.0.7895300)
- VMware SRM As Built [(VMware SRM Cmdlets)](https://github.com/benmeadowcroft/SRM-Cmdlets.git)
- Pure Storage As Built [(Pure Storage PowerShell SDK)](https://www.powershellgallery.com/packages/PureStoragePowerShellSDK/1.7.4.0)
- Nutanix As Built [(Nutanix Cmdlets PSSnapin)](https://portal.nutanix.com) (Requires Nutanix portal access)
- Cisco UCS As Built [(Cisco UCS PowerTool)](https://software.cisco.com/download) (Requires Cisco portal access)

## Installing PScribo
PScribo can be installed via two methods;
- Automatically via PowerShell Gallery;
  - Run ```Install-Module PScribo```

- Manually by downloading the [GitHub package](https://github.com/iainbrighton/PScribo)
  - Download and unblock the latest .zip file.
  - Extract the .zip into your $PSModulePath, e.g. ~\Documents\WindowsPowerShell\Modules.
    Ensure the extracted folder is named 'PScribo'.
  - Run ```Import-Module PScribo```

 

