#requires -Modules @{ModuleName="PScribo";ModuleVersion="0.7.23"}
<#
.SYNOPSIS  
    PowerShell script which documents the configuration of IT infrastructure in Word/HTML/XML/Text formats
.DESCRIPTION
    Documents the configuration of IT infrastructure in Word/HTML/XML/Text formats using PScribo.
.NOTES
    Version:        0.1.1
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
.PARAMETER AsBuiltConfigPath
    Enter the full path to an As Built report configuration JSON file
    This parameter is optional and does not have a default value.
    If this parameter is not specified, the user running the script will be prompted for this configuration information on first run, with the option to save the configuration to a file.
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
.PARAMETER AsBuiltConfigPath
    Enter the full patch to a configuration JSON file
    This parameter is optional and does not have a default value.
    If this parameter is not specified, the user running the script will be prompted for this configuration information on first run, with the option to save the configuration to a file.
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
.EXAMPLE
    .\New-AsBuiltReport.ps1 -IP 192.168.1.100 -Username admin -Password admin -Format HTML -Type vSphere -AsBuiltConfigPath c:\scripts\asbuilt.json
    Creates a VMware vSphere As Built Documentet in HTML format, using the configuration located in the asbuilt.json file in the c:\scripts\ folder.
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
    [Switch]$SendEmail = $False,
    [Parameter(Mandatory = $False, HelpMessage = 'Provide the file path to an existing As Built Configuration JSON file')]
    [string]$AsBuiltConfigPath
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

# Import the As Built Config if one has been specified, else prompt the user to enter the information
if ($AsBuiltConfigPath) {
    Write-Verbose "AsBuiltConfigPath has been specified, importing the information from the JSON file at $AsBuiltConfigPath"
    if (!(Test-Path -Path $AsBuiltConfigPath)) {
        Write-Error "The patch specified for the As Built configuration file can not be resolved"
        break
    }
}
else {
    Clear-Host
    Write-Host '---------------------------------------------' -ForegroundColor Blue
    Write-Host '  <     As Built Report Configuration     >  ' -ForegroundColor Blue
    Write-Host '---------------------------------------------' -ForegroundColor Blue   
    $SaveAsBuiltConfig = Read-Host -Prompt "Would you like to save the As Built Configuration to a file? (y/n)"
    if ($SaveAsBuiltConfig -eq "y") {
        $AsBuiltName = Read-Host -Prompt "Enter a name for the as built configuration file"
        $AsBuiltExportPath = Read-Host -Prompt "Enter the path to save the As Built Configuration JSON to, including a trailing backslash, for example; c:\scripts\"
        $AsBuiltConfigPath = $AsBuiltExportPath + $AsBuiltName + ".json"
    }

    Clear-Host
    Write-Host '---------------------------------------------' -ForegroundColor Blue
    Write-Host '  <      As Built Report Information      >  ' -ForegroundColor Blue
    Write-Host '---------------------------------------------' -ForegroundColor Blue  
    $AsBuiltAuthor = Read-Host -Prompt "Enter the name of the Author for this As Built Document"
    $CompanyFullName = Read-Host -Prompt "Enter the Full Company Name"
    $CompanyShortName = Read-Host -Prompt "Enter the Company Short Name"
    $CompanyContact = Read-Host -Prompt "Enter the Company Contact"
    $CompanyEmailAddress = Read-Host -Prompt "Enter the Company Email Address"
    $CompanyPhone = Read-Host -Prompt "Enter the Company Phone"
    $CompanyAddress = Read-Host -Prompt "Enter the Company Address"

    Clear-Host
    Write-Host '---------------------------------------------' -ForegroundColor Blue
    Write-Host '  <          Mail Configuration           >  ' -ForegroundColor Blue
    Write-Host '---------------------------------------------' -ForegroundColor Blue  
    $ConfigureMailSettings = Read-Host -Prompt "Would you like to enter SMTP configuration? (y/n)"
    if ($ConfigureMailSettings -eq "y") {
        $MailServer = Read-Host -Prompt "Enter the Email Server FQDN / IP Address"
        $MailServerPort = Read-Host -Prompt "Enter the Email Server port number"
        $MailServerUseSSL = Read-Host -Prompt "Use SSL for mail server connection? (true/false)"
        $MailCredentials = Read-Host -Prompt "Require Authentication? (true/false)"
        $MailFrom = Read-Host -Prompt "Enter the Email Sender address"
        $MailTo = Read-Host -Prompt "Enter the Email Server receipient address"
        $MailBody = Read-Host -Prompt "Enter the Email Message Body content"
    }
    $Body = [Ordered]@{
        Report  = [Ordered]@{
            Author = $AsBuiltAuthor
        }
        Company = [Ordered]@{
            FullName  = $CompanyFullName
            ShortName = $CompanyShortName
            Contact   = $CompanyContact
            Email     = $CompanyEmailAddress
            Phone     = $CompanyPhone
            Address   = $CompanyAddress
        }
        Mail    = [Ordered]@{
            Server     = $MailServer
            Port       = $MailServerPort
            UseSSL     = $MailServerUseSSL
            Credential = $MailCredentials
            From       = $MailFrom
            To         = $MailTo
            Body       = $MailBody
        }   
    }
    if ($SaveAsBuiltConfig -eq "y") {
        $Body | ConvertTo-Json | Out-File $AsBuiltConfigPath
        $BaseConfig = Get-Content $AsBuiltConfigPath | ConvertFrom-Json
        $Author = $BaseConfig.Report.Author
        $Company = $BaseConfig.Company
        $Mail = $BaseConfig.Mail
    }
    else {
        $Body | ConvertTo-Json | Out-File "$env:TEMP\AsBuiltReport.json" -Force
        $BaseConfig = Get-Content "$env:TEMP\AsBuiltReport.json" | ConvertFrom-Json
        $Author = $BaseConfig.Report.Author
        $Company = $BaseConfig.Company
        $Mail = $BaseConfig.Mail
        Remove-Item -Path "$env:TEMP\AsBuiltReport.json" -Confirm:$false
    }
}
#endregion Configuration Settings

if ($SendEmail -and $Mail.Credential) {
    Clear-Host
    Write-Host '---------------------------------------------' -ForegroundColor Blue
    Write-Host '  <        Mail Server Credentials        >  ' -ForegroundColor Blue
    Write-Host '---------------------------------------------' -ForegroundColor Blue  
    $MailCreds = Get-Credential -Message 'Please enter mail server credentials'
}

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

#region Send-Email
# Create and export document to specified format and path.
$Output = $AsBuiltReport | Export-Document -PassThru -Path $Path -Format $Format
if ($SendEmail) {
    if ($Mail.Credential) {
        if ($Mail.UseSSL) {
            Send-MailMessage -Attachments $Output -To $Mail.To -From $Mail.From -Subject $Report.Name -Body $Mail.Body -SmtpServer $Mail.Server -Port $Mail.Port -UseSsl -Credential $MailCreds
        }
        else {
            Send-MailMessage -Attachments $Output -To $Mail.To -From $Mail.From -Subject $Report.Name -Body $Mail.Body -SmtpServer $Mail.Server -Port $Mail.Port -UseSsl
        }
    }
    elseif ($Mail.UseSSL) {
        Send-MailMessage -Attachments $Output -To $Mail.To -From $Mail.From -Subject $Report.Name -Body $Mail.Body -SmtpServer $Mail.Server -Port $Mail.Port -UseSsl
    }
    else {
        Send-MailMessage -Attachments $Output -To $Mail.To -From $Mail.From -Subject $Report.Name -Body $Mail.Body -SmtpServer $Mail.Server -Port $Mail.Port
    }
}
#endregion Send-Email