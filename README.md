# Documentation-Scripts

A collection of PowerShell scripts to document the configuration of datacentre infrastucture in Text, XML, HTML & MS Word formats.

# Getting Started
Below is a simple list of instructions on how to use these scripts.

## Pre-requisites

All scripts within this repository require [PScribo](https://github.com/iainbrighton/PScribo). See below for installation instructions.

Other PowerShell modules and PSSnapins are dependant on which script you choose to run.

- VMware vSphere As Built [(VMware PowerCLI Module)](https://www.powershellgallery.com/packages/VMware.PowerCLI/10.0.0.7895300)
- VMware SRM As Built [(VMware SRM Cmdlets)](https://github.com/benmeadowcroft/SRM-Cmdlets.git)
- Pure Storage As Built [(Pure Storage PowerShell SDK)](https://www.powershellgallery.com/packages/PureStoragePowerShellSDK/1.7.4.0)
- Nutanix As Built [(Nutanix Cmdlets PSSnapin)](https://portal.nutanix.com) (Requires Nutanix portal access)
- Cisco UCS As Built [(Cisco UCS PowerTool)](https://software.cisco.com/download) (Requires Cisco portal access)

## Installing PScribo
PScribo can be installed via two methods;
- Automatically via PowerShell Gallery;
  - Run `Install-Module PScribo`

- Manually by downloading the [GitHub package](https://github.com/iainbrighton/PScribo)
  - Download and unblock the latest .zip file.
  - Extract the .zip into your $PSModulePath, e.g. ~\Documents\WindowsPowerShell\Modules.
    Ensure the extracted folder is named 'PScribo'.
  - Run `Import-Module PScribo`

# Using the Documentation Scripts

Each script utilises a common set of script parameters. Some scripts will use additional parameters. Additional script parameters and relevant examples will be shown in the script's README.md.

### PARAMETER Target
    Specifies the IP/FQDN of the target system.
    This parameter is mandatory.

### PARAMETER Username
    Specifies the username of the target system.
    This parameter is mandatory.

### PARAMETER Password
    Specifies the password of the target system.
    This parameter is mandatory.

### PARAMETER Type
    Specifies the type of report that will generated.
    Type paramater must match the report filename in the \Reports\<ReportType> folder.
    This parameter is mandatory.

### PARAMETER Format
    Specifies the output format of the report.
    This parameter is mandatory.
    The supported output formats are WORD, HTML, XML & TEXT.
    Multiple output formats may be specified, separated by a comma.
    By default, the output format will be set to WORD.

### PARAMETER StyleName
    Specifies a custom document style to be used for the report.
    The style name must match the filename in the \Styles folder.
    This parameter is optional and does not have a default value.

### PARAMETER Path
    Specifies the path to save the report.
    This parameter is optional. If not specified the report will be saved in the script folder.
    
### PARAMETER Timestamp
    Specifies whether to append a timestamp string to the report filename.
    This parameter is optional. 
    By default, the timestamp string is not added to the report filename.

### PARAMETER Healthchecks
    Highlights certain issues within the system report.
    Some reports may not provide this functionality.
    This parameter is optional.

### PARAMETER SendEmail
    Sends report to specified recipients as email attachments.
    This parameter is optional.

# Examples
Create a VMware vSphere As Built Report in HTML format. Append timestamp to the filename. Highlight configuration issues within the report. Save report to specified path.

`.\New-AsBuiltReport.ps1 -Target 192.168.1.10 -Username admin -Password admin -Type vSphere -Format Html -Timestamp -Path 'C:\Users\Tim\Documents' -Healthchecks`

Create a Pure Storage FlashArray As Built Report in Word & Text formats. Create a report for multiple FlashArrays. Report is saved to script folder.

`.\New-AsBuiltReport.ps1 -Target '192.168.1.100,192.168.1.110' -Username pureuser -Password pureuser -Type FlashArray -Format Word,Text`

Create a Nutanix As Built Report in Word & HTML formats. Send reports via email.

`.\New-AsBuiltReport.ps1 -Target '192.168.1.100,192.168.1.110' -Username admin -Password admin -Type Nutanix -Format Word,Html -SendEmail`