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
    Credits:        Iain Brighton (@iainbrighton) - PScribo module
                    Carl Webster (@carlwebster) - Documentation Script Concept
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
.PARAMETER Password
    Specifies the password of the system.
.PARAMETER Credentials
    Specifies the credentials of the target system.
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
.PARAMETER Timestamp
    Specifies whether to append a timestamp string to the report filename.
    This parameter is optional. 
    By default, the timestamp string is not added to the report filename.
.PARAMETER Healthchecks
    Highlights certain issues within the system report.
    Some reports may not provide this functionality.
    This parameter is optional.
.PARAMETER SendEmail
    Sends report to specified recipients as email attachments.
    This parameter is optional.
.EXAMPLE
    .\New-AsBuiltReport.ps1 -IP 192.168.1.100 -Username admin -Password admin -Format HTML,Word -Type vSphere -Healthchecks
    Creates a VMware vSphere As Built Document in HTML & Word formats. The document will highlight particular issues which exist within the environment.
.EXAMPLE
    .\New-AsBuiltReport.ps1 -IP 192.168.1.100 -Credentials $Creds -Format Text -Type FlashArray -Timestamp
    Creates a Pure Storage FlashArray As Built document in Text format and appends a timestamp to the filename. Uses stored credentials to connect to system.
.EXAMPLE
    .\New-AsBuiltReport.ps1 -IP 192.168.1.100 -Username admin -Password admin -Type UCS -StyleName ACME
    Creates a Cisco UCS As Built document in default format (Word) with a customised style.
.EXAMPLE
    .\New-AsBuiltReport.ps1 -IP 192.168.1.100 -Username admin -Password admin -Type Nutanix -SendEmail
    Creates a Nutanix As Built document in default format (Word). Report will be attached and sent via email.
#>

#region Script Parameters
[CmdletBinding(SupportsShouldProcess = $False)]
Param(

    [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Please provide the IP/FQDN of the system')]
    [ValidateNotNullOrEmpty()]
    [Alias('Cluster', 'Server', 'IP')]
    [String]$Target,

    [Parameter(Position = 1, Mandatory = $True, ParameterSetName = "UserPass", HelpMessage = 'Please provide the username to connect to the system')]
    [ValidateNotNullOrEmpty()]
    [String]$Username,

    [Parameter(Position = 2, Mandatory = $True, ParameterSetName = "UserPass", HelpMessage = 'Please provide the password to connect to the system')]
    [ValidateNotNullOrEmpty()]
    [String]$Password,

    [Parameter(Position = 3, Mandatory = $False, ParameterSetName = "Credentials", HelpMessage = 'Please provide credentails to connect to the system')]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$Credentials,

    [Parameter(Position = 4, Mandatory = $True, HelpMessage = 'Please provide the document type')]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [Parameter(Position = 5, Mandatory = $False, HelpMessage = 'Please provide the document output format')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Word', 'Html', 'Text', 'Xml')]
    [Array]$Format = 'Word',

    [Parameter(Mandatory = $False, HelpMessage = 'Please provide the custom style name')]
    [ValidateNotNullOrEmpty()] 
    [String]$StyleName,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify whether to append a timestamp to the document filename')]
    [Switch]$Timestamp = $False,

    [Parameter(Mandatory = $False, HelpMessage = 'Please provide the path to the document output file')]
    [ValidateNotNullOrEmpty()]
    [Alias('Folder')] 
    [String]$Path = (Get-Location).Path,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify whether to highlight any configuration issues within the document')]
    [Switch]$Healthchecks = $False,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify whether to send report via Email')]
    [Switch]$SendEmail = $False
)
#endregion Script Parameters
Clear-Host

#region Configuration Settings

# Check credentials have been supplied
if ($Credentials -and (!($Username -and !($Password)))) {
}
Elseif (!($Credentials) -and ($Username -and !($Password))) {
    # Convert specified Password to secure string
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
    
}
Elseif (($Username -and $Password) -and !($Credentials)) {
    # Convert specified Password to secure string
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
}
Elseif (!$Credentials -and (!($Username -and !($Password)))) {
    Write-Error "Please supply credentials to connect to $target"
    Break
}

# Set variables from report configuration JSON file
$ScriptPath = (Get-Location).Path
$ReportConfigFile = Join-Path $ScriptPath $("Reports\$Type\$Type.json")
If (Test-Path $ReportConfigFile -ErrorAction SilentlyContinue) {  
    $ReportConfig = Get-Content $ReportConfigFile | ConvertFrom-json
    $Report = $ReportConfig.Report
    $Filename = $Report.Name
    $Version = $Report.Version
    $Options = $ReportConfig.Options
    $InfoLevel = $ReportConfig.InfoLevel
    if ($Healthchecks) {
        $Healthcheck = $ReportConfig.HealthCheck
    }
    if ($Timestamp) {
        $Filename = $Filename + " - " + (Get-Date -Format 'yyyy-MM-dd_HH.mm.ss')
    }
}
else {
    Write-Error "$Type report JSON configuration file does not exist."
    break
}
# Set variables from base configuration JSON file
$BaseConfigFile = Join-Path $ScriptPath "config.json"
If (!(Test-Path $BaseConfigFile -ErrorAction SilentlyContinue)) {
    # Run script to generate config file if it does not exist
    .\New-AsBuiltConfig.ps1
}
else {
    $BaseConfig = Get-Content $BaseConfigFile | ConvertFrom-json
    $Author = $BaseConfig.Report.Author
    $Company = $BaseConfig.Company
    $Mail = $BaseConfig.Mail
    if ($SendEmail -and $Mail.Credential){
        $MailCreds = Get-Credential -Message 'Please enter mail server credentials'
    }
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
$Output = $AsBuiltReport | Export-Document -PassThru -Path $Path -Format $Format

if ($SendEmail) {
    if ($Mail.Credential) {
        Send-MailMessage -Attachments $Output -To $Mail.To -From $Mail.From -Subject $Report.Name -Body $Mail.Body -SmtpServer $Mail.Server -Port $Mail.Port -UseSsl -Credential $MailCreds
    }
    else {
        Send-MailMessage -Attachments $Output -To $Mail.To -From $Mail.From -Subject $Report.Name -Body $Mail.Body -SmtpServer $Mail.Server -Port $Mail.Port -UseSsl
    }
}