# As-Built-Report

As-Built-Report is a PowerShell module which generates As-Built documentation for many common datacentre
infrastructure systems. Reports can be generated in Text, XML, HTML and MS Word formats and can be presented with
custom styling to align with your company/customer's brand. The following systems are currently fully supported,
with many more being added very shortly:

- [VMware vSphere](/Src/Public/Reports/vSphere/README.md)

# Getting Started

The following simple list of instructions will get you started with the As-Built-Report module.

## Pre-requisites

All CmdLets and Functions require the [PScribo](https://github.com/iainbrighton/PScribo) module version 0.7.24 or later.
PScribo can be installed from the PowerShell Gallery with the following command.

```powershell
Install-Module PScribo
```

Each of the specific As-Built report types may also require other modules or PSSnapins.
The pre-requisites for each report type will be documented within its own `README.md` located in the `Src` directory.

## Installing As-Built-Report

Clone this repository with the following command.

```powershell
git clone https://github.com/tpcarman/As-Built-Report.git
```

Change directory into the cloned repository and import the module manifest.

```powershell
cd .\As-Built-Report
Import-Module .\Src\As-Built-Report.psd1
```

## Using As Built Report

Each report type utilises a common set of parameters. Additional parameters specific to a particular
report type will be detailed in the individual report's `README.md` file, along with any relevant examples.
Each report type will have its own sub-directory, within the `Src` directory, which will contain its `README.md`.

For a full list of common parameters and examples you can view the `New-AsBuiltReport` CmdLet help with the following command.

```powershell
Get-Help New-AsBuiltReport -Full
```

Here are some examples to get you going.

```powershell
# The following creates a VMware vSphere As Built report in HTML & Word formats.
# The document will highlight particular issues which exist within the environment by including the HealthChecks switch.
PS C:\>New-AsBuiltReport -Target 192.168.1.100 -Username admin -Password admin -Format HTML,Word -Type vSphere -Healthchecks

# The following creates a Pure Storage FlashArray As Built report in Text format and appends a
# timestamp to the filename. It also uses stored credentials to connect to system.
PS C:\>$Creds = Get-Credential
PS C:\>New-AsBuiltReport -Target 192.168.1.100 -Credentials $Creds -Format Text -Type FlashArray -Timestamp

# The following creates a Cisco UCS As Built report in default format (Word) with a customised style.
PS C:\>New-AsBuiltReport -IP 192.168.1.100 -Username admin -Password admin -Type UCS -StyleName ACME

# The following creates a VMware vSphere As Built report in HTML format,
# using the configuration in the asbuilt.json file located in the C:\scripts\ folder.
PS C:\>New-AsBuiltReport -IP 192.168.1.100 -Username admin -Password admin -Format HTML -Type vSphere -AsBuiltConfigPath C:\scripts\asbuilt.json
```

# Release Notes
## 0.2.0
### What's New
- New As Built JSON configuration structure
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
