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
  - Run ```Install-Module PScribo```

- Manually by downloading the [GitHub package](https://github.com/iainbrighton/PScribo)
  - Download and unblock the latest .zip file.
  - Extract the .zip into your $PSModulePath, e.g. ~\Documents\WindowsPowerShell\Modules.
    Ensure the extracted folder is named 'PScribo'.
  - Run ```Import-Module PScribo```

## Using the Documentation Scripts

Each script utilises a common set of script parameters. Some scripts will use additional parameters. Additional script parameters will be shown in the script's README.md.

### PARAMETER Format
    Specifies the output format of the report.
    This parameter is mandatory.
    The supported output formats are WORD, HTML, XML & TEXT.
    Multiple output formats may be specified, separated by a comma.
    By default, the output format will be set to WORD.

### PARAMETER Path
    Specifies the path to save the report.
    This parameter is optional. If not specified the report will be saved in the script folder.
    
### PARAMETER ReportName
    Specifies the report name.
    This parameter is optional.
    By default, the report name is 'VMware vSphere As Built Documentation'. 

### PARAMETER Author
    Specifies the report's author.
    This parameter is optional and does not have a default value.

### PARAMETER Version
    Specifies the report version number.
    This parameter is optional and does not have a default value.

### PARAMETER Status
    Specifies the report document status.
    This parameter is optional.
    By default, the document status is set to 'Released'.

### PARAMETER AddDateTime
    Specifies whether to append a date/time string to the report filename.
    This parameter is optional. 
    By default, the date/time string is not added to the report filename.

### PARAMETER CompanyName
    Specifies a Company Name for the report.
    This parameter is optional and does not have a default value.

### PARAMETER CompanyContact
    Specifies the Company Contact's Name.
    This parameter is optional and does not have a default value.

### PARAMETER CompanyEmail
    Specifies the Company Contact's Email Address.
    This parameter is optional and does not have a default value.

### PARAMETER CompanyPhone
    Specifies the Company Contact's Phone Number.
    This parameter is optional and does not have a default value.

### PARAMETER CompanyAddress
    Specifies the Company Office Address
    This parameter is optional and does not have a default value.

