<<<<<<< HEAD
# As-Built Report

A collection of PowerShell scripts to generate as-built reports on the configuration of datacentre infrastucture in Text, XML, HTML & MS Word formats.
=======
# As Built Report

A collection of PowerShell scripts to generate as built reports on the configuration of datacentre infrastucture in Text, XML, HTML & MS Word formats.
>>>>>>> refs/remotes/origin/dev

# Getting Started
Below is a simple list of instructions on how to use these scripts.

## Pre-requisites

All scripts within this repository require [PScribo](https://github.com/iainbrighton/PScribo). See below for installation instructions.

Other PowerShell modules and PSSnapins will be required in order to execute scripts and generate reports. The pre-requisites for each report will be documented within its README.md.

## Installing PScribo
PScribo can be installed via two methods;
- Automatically via PowerShell Gallery;
    
    `Install-Module PScribo`

- Manually by downloading the [GitHub package](https://github.com/iainbrighton/PScribo)
  - Download and unblock the latest .zip file.
  - Extract the .zip into your $PSModulePath, e.g. ~\Documents\WindowsPowerShell\Modules.
    Ensure the extracted folder is named 'PScribo'.

    `Import-Module PScribo`

<<<<<<< HEAD
# Using As-Built Report
=======
# Using As Built Report
>>>>>>> refs/remotes/origin/dev

Each report script utilises a common set of script parameters. Some report scripts will use additional parameters. Additional report script parameters and relevant examples will be shown in the report's README.md.

### PARAMETER Target
    Specifies the IP/FQDN of the target system.
    This parameter is mandatory.

### PARAMETER Username
    Specifies the username of the target system.

### PARAMETER Password
    Specifies the password of the target system.

### PARAMETER Credentials
    Specifies the credentials of the target system.

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

### PARAMETER AsBuiltConfigPath
<<<<<<< HEAD
    Specifies the path to the As-Built report configuration file.
=======
    Specifies the path to the As Built report configuration file.
>>>>>>> refs/remotes/origin/dev
    This parameter is optional. If not specified the script will prompt the user to provide the configuration information.
    
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
- Create a VMware vSphere As Built Report in HTML format. Append timestamp to the filename. Highlight configuration issues within the report. Save report to specified path.

    `.\New-AsBuiltReport.ps1 -Target 192.168.1.10 -Username admin -Password admin -Type vSphere -Format Html -Timestamp -Path 'C:\Users\Tim\Documents' -Healthchecks`

- Create a Pure Storage FlashArray As Built Report in Word & Text formats. Create a report for multiple FlashArrays. Report is saved to script folder.

    `.\New-AsBuiltReport.ps1 -Target '192.168.1.100,192.168.1.110' -Username pureuser -Password pureuser -Type FlashArray -Format Word,Text`

- Create a Nutanix As Built Report in Word & HTML formats. Send reports via email.

    `.\New-AsBuiltReport.ps1 -Target '192.168.1.100,192.168.1.110' -Username admin -Password admin -Type Nutanix -Format Word,Html -SendEmail`

<<<<<<< HEAD
# Release Notes
## 0.2.0
### What's New
- New As-Built JSON configuration structure
=======
# Reports

## VMware vSphere As Built Report
- Information relating to the VMware vSphere As Built Report can be found in the report's [README.md](https://github.com/tpcarman/As-Built-Report/tree/master/Reports/vSphere)

# Release Notes
## 0.2.0
### What's New
- New As Built JSON configuration structure
>>>>>>> refs/remotes/origin/dev
  - new `AsBuiltConfigPath` parameter
  - allows unique configuration files to be created and saved
  - if `AsBuiltConfigPath` parameter is not specified, user is prompted for As Built report configuration information
  - `New-AsBuiltConfig.ps1` & `Config.json` files are no longer required 

## All Releases
### Known Issues
- Table Of Contents (TOC) may be missing in Word formatted report

    When opening the DOC report, MS Word prompts the following 
    
    `"This document contains fields that may refer to other files. Do you want to update the fields in this document?"`
    
    `Yes / No`

    Clicking `No` will prevent the TOC fields being updated and leaving the TOC empty.

    Always reply `Yes` to this message when prompted by MS Word.

- In HTML documents, word-wrap of table cell contents is not working, causing the following issues;
  - Cell contents may overflow table columns
  - Tables may overflow page margin
  - [PScribo Issue #83](https://github.com/iainbrighton/PScribo/issues/83)

- In Word documents, some tables are not sized proportionately. To prevent cell overflow issues in HTML documents, most tables are auto-sized, this causes some tables to be out of proportion.
    
    - [PScribo Issue #83](https://github.com/iainbrighton/PScribo/issues/83)