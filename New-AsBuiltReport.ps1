#requires -Modules @{ModuleName="PScribo";ModuleVersion="0.7.23"}

<#
.SYNOPSIS  
    PowerShell script which documents the configuration of IT infrastructure in Word/HTML/XML/Text formats
.DESCRIPTION
    Documents the configuration of IT infrastructure in Word/HTML/XML/Text formats using PScribo.
.NOTES
    Version:        1.0
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
    Credits:        @iainbrighton - PScribo module
.LINK
    https://github.com/tpcarman/Documentation-Scripts
    https://github.com/iainbrighton/PScribo	
.PARAMETER Target
    Specifies the IP/FQDN of the system to connect.
    This parameter is mandatory.
    Specifying multiple IPs is supported for some As Built reports.
    Multiple IPs must be separated by a comma and enclosed in single quotes (').
.PARAMETER Username
    Specifies the username of the system.
    This parameter is mandatory.
.PARAMETER Password
    Specifies the password of the system.
    This parameter is mandatory.
.PARAMETER Type
    Specifies the type of report that will generated.
    This parameter is mandatory.
.PARAMETER Format
    Specifies the output format of the report.
    This parameter is mandatory.
    The supported output formats are WORD, HTML, XML & TEXT.
    Multiple output formats may be specified, separated by a comma.
    By default, the output format will be set to WORD.
.PARAMETER StyleName
    Specifies the document style name of the report.
    This parameter is optional and does not have a default value.
.PARAMETER Path
    Specifies the path to save the report.
    This parameter is optional. If not specified the report will be saved in the script folder.
.PARAMETER AddDateTime
    Specifies whether to append a date/time string to the report filename.
    This parameter is optional. 
    By default, the date/time string is not added to the report filename.
.PARAMETER Healthcheck
    Highlights certain issues within the system report.
    This parameter is optional.
.EXAMPLE
    .\New-AsBuiltReport.ps1 -IP 192.168.1.100 -Username admin -Password admin -Format HTML,Word -Type vSphere -Healthcheck
    Creates a VMware vSphere As Built Document in HTML & Word formats. The document will highlight particular issues which exist within the environment.
.EXAMPLE
    .\New-AsBuiltReport.ps1 -IP 192.168.1.100 -Username admin -Password admin -Format Text -Type FlashArray -AddDateTime
    Creates a Pure Storage FlashArray As Built document in Text format and appends the current date and time to the filename.
.EXAMPLE
    .\New-AsBuiltReport.ps1 -IP 192.168.1.100 -Username admin -Password admin -Type UCS -Style ACME
    Creates a Cisco UCS As Built document in default format (Word) with a customised style.
#>

#region Script Parameters
[CmdletBinding(SupportsShouldProcess = $False)]
Param(

    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Please provide the IP/FQDN of the system')]
    [ValidateNotNullOrEmpty()]
    [Alias('Cluster', 'Server', 'IP')]
    [String]$Target = '',

    [Parameter(Position = 1, Mandatory = $False, ParameterSetName = "Param1", HelpMessage = 'Please provide the username to connect to the system')]
    [ValidateNotNullOrEmpty()]
    [String]$Username = '',

    [Parameter(Position = 2, Mandatory = $False, ParameterSetName = "Param1", HelpMessage = 'Please provide the password to connect to the system')]
    [ValidateNotNullOrEmpty()]
    [String]$Password = '',

    [Parameter(Position = 3, Mandatory = $False, ParameterSetName = "Param2", HelpMessage = 'Please provide credentails to connect to the system')]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$Credentials,

    [Parameter(Position = 4, Mandatory = $True, HelpMessage = 'Please provide the document type')]
    [ValidateNotNullOrEmpty()]
    [String]$Type = '',

    [Parameter(Position = 5, Mandatory = $False, HelpMessage = 'Please provide the document output format')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Word', 'Html', 'Text', 'Xml')]
    [Array]$Format = 'Word',

    [Parameter(Mandatory = $False, HelpMessage = 'Please provide the custom style name')]
    [ValidateNotNullOrEmpty()] 
    [String]$StyleName = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify whether to append a date/time string to the document filename')]
    [Switch]$AddDateTime = $False,

    [Parameter(Mandatory = $False, HelpMessage = 'Please provide the path to the document output file')]
    [ValidateNotNullOrEmpty()]
    [Alias('Folder')] 
    [String]$Path = (Get-Location).Path,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify whether to highlight any configuration issues within the document')]
    [Switch]$Healthcheck = $False
)
#endregion Script Parameters
Clear-Host

#region Configuration Settings
# Convert specified Password to secure string
if ($credentials -and (!($username -and !($password)))) {
}
    Elseif (!($Credentials) -and ($username -and !($password))) {
        $Password = Read-host -prompt "Password"
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
    }
    Elseif (($Username -and $Password) -and !($Credentials)) {
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
    }   

    $ScriptPath = (Get-Location).Path

# Set variables from report configuration JSON file
$ReportConfigFile = Join-Path $ScriptPath $("Reports\$Type\$Type.json")
If (Test-Path $ReportConfigFile -ErrorAction SilentlyContinue) {  
    $ReportConfig = Get-Content $ReportConfigFile | ConvertFrom-json
    $Report = $ReportConfig.Report
    $Filename = $Report.Name
    if ($AddDateTime) {
        $Filename = $Filename + " - " + (Get-Date -Format 'yyyy-MM-dd_HH.mm.ss')
    }
    $Version = $Report.Version
}
else {
    Write-Error "$Type report JSON configuration file does not exist."
    break
}
# Set variables from base configuration JSON file
$BaseConfigFile = Join-Path $ScriptPath "config.json"
If (!(Test-Path $BaseConfigFile -ErrorAction SilentlyContinue)) {  
    .\New-AsBuiltConfig.ps1
}
else {
    $BaseConfig = Get-Content $BaseConfigFile | ConvertFrom-json
    $Author = $BaseConfig.Report.Author
    $Company = $BaseConfig.Company
    $Mail = $BaseConfig.Mail
}
#endregion Configuration Settings

#region Create Report
$AsBuiltReport = Document $Filename -Verbose {

    # Set document style
    if ($StyleName) {
        $DocStyle = Join-Path $ScriptPath $("Styles\$StyleName.ps1")
        If (Test-Path $DocStyle -ErrorAction SilentlyContinue) {
            .$DocStyle 
        }
        else {
            Write-Warning "Style name $Stylename does not exist"
        }
    }

    # Generate report
    if ($Type) {
        $ScriptFile = Join-Path $ScriptPath $("Reports\$Type\$Type.ps1")
        if (Test-Path $scriptFile -ErrorAction SilentlyContinue) {
            .$ScriptFile
        }
        else {
            Write-Error "$Type report does not exist"
            break
        }
    }
}
#endregion Create Report

# Create and export document to specified format and path.
$AsBuiltReport | Export-Document -Path $Path -Format $Format