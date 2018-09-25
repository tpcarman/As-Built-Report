function New-AsBuiltReport {
    <#
    .SYNOPSIS  
        Documents the configuration of IT infrastructure in Word/HTML/XML/Text formats using PScribo.
    .DESCRIPTION
        Documents the configuration of IT infrastructure in Word/HTML/XML/Text formats using PScribo.
    .NOTES
        Version:        0.3.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
                        Carl Webster (@carlwebster) - Documentation Script Concept
    .LINK
        https://github.com/tpcarman/As-Built-Report
        https://github.com/iainbrighton/PScribo 
    .PARAMETER Target
        Specifies the IP/FQDN of the system to connect.
        Specifying multiple Targets (separated by a comma) is supported for some As-Built reports.
    .PARAMETER Username
        Specifies the username of the system.
    .PARAMETER Password
        Specifies the password of the system.
    .PARAMETER Credentials
        Specifies the credentials of the target system.
    .PARAMETER Type
        Specifies the type of report that will be generated.
    .PARAMETER Format
        Specifies the output format of the report.
        The supported output formats are WORD, HTML, XML & TEXT.
        Multiple output formats may be specified, separated by a comma.
    .PARAMETER StyleName
        Specifies the document style name of the report.
    .PARAMETER Path
        Specifies the path to save the report. If not specified the report will be saved in the script folder.
    .PARAMETER AsBuiltConfigPath
        Enter the full path to an As Built report configuration JSON file
        If this parameter is not specified, the user running the script will be prompted for this 
        configuration information on first run, with the option to save the configuration to a file.
    .PARAMETER Timestamp
        Specifies whether to append a timestamp string to the report filename.
        By default, the timestamp string is not added to the report filename.
    .PARAMETER Healthchecks
        Highlights certain issues within the system report.
        Some reports may not provide this functionality.
    .PARAMETER SendEmail
        Sends report to specified recipients as email attachments.
    .PARAMETER AsBuiltConfigPath
        Enter the full patch to a configuration JSON file.
        If this parameter is not specified, the user running the script will be prompted for this 
        configuration information on first run, with the option to save the configuration to a file.
    .EXAMPLE
        PS C:\>New-AsBuiltReport -Target 192.168.1.100 -Username admin -Password admin -Format HTML,Word -Type vSphere -Healthchecks

        Creates a VMware vSphere As Built Document in HTML & Word formats. The document will highlight particular issues which exist within the environment.
    .EXAMPLE
        PS C:\>$Creds = Get-Credential
        PS C:\>New-AsBuiltReport -Target 192.168.1.100 -Credentials $Creds -Format Text -Type FlashArray -Timestamp

        Creates a Pure Storage FlashArray As Built document in Text format and appends a timestamp to the filename. Uses stored credentials to connect to system.
    .EXAMPLE
        PS C:\>New-AsBuiltReport -IP 192.168.1.100 -Username admin -Password admin -Type UCS -StyleName ACME

        Creates a Cisco UCS As Built document in default format (Word) with a customised style.
    .EXAMPLE
        PS C:\>New-AsBuiltReport -IP 192.168.1.100 -Username admin -Password admin -Type Nutanix -SendEmail

        Creates a Nutanix As Built document in default format (Word). Report will be attached and sent via email.
    .EXAMPLE
        PS C:\>New-AsBuiltReport -IP 192.168.1.100 -Username admin -Password admin -Format HTML -Type vSphere -AsBuiltConfigPath C:\scripts\asbuilt.json
        
        Creates a VMware vSphere As Built Document in HTML format, using the configuration in the asbuilt.json file located in the C:\scripts\ folder.
    #>

    #region Script Parameters
    [CmdletBinding(SupportsShouldProcess = $False)]
    Param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Please provide the IP/FQDN of the system')]
        [ValidateNotNullOrEmpty()]
        [Alias('Cluster', 'Server', 'IP')]
        [String[]]$Target,
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
        [ValidateScript(
            {
                $ReportTypes = Get-ChildItem "$PSScriptRoot\Reports\" | Select-Object -ExpandProperty Name
                if ($ReportTypes -contains $_) {
                    return $True
                } else {
                    throw "Invalid Type specified, $($_). Please use one of the following: $([string]::join(',',$ReportTypes))"
                }
            }
        )]
        [String]
        $Type,
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
    <#
    Elseif (!($Credentials) -and ($Username -and !($Password))) {
        # Convert specified Password to secure string
        #$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        #$Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
    }#>
    Elseif (($Username -and $Password) -and !($Credentials)) {
        # Convert specified Password to secure string
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
    }#>
    Elseif (!$Credentials -and (!($Username -and !($Password)))) {
        Write-Error "Please supply credentials to connect to $target"
        Break
    }

    # Set variables from report configuration JSON file
    $ReportConfigFile = "$PSScriptRoot\Reports\$Type\$Type.json"
    If (Test-Path $ReportConfigFile -ErrorAction SilentlyContinue) {  
        $ReportConfig = Get-Content $ReportConfigFile -Raw | ConvertFrom-json
        $Report = $ReportConfig.Report
        $ReportName = $Report.Name
        $Version = $Report.Version
        $Status = $Report.Status
        $Options = $ReportConfig.Options
        $InfoLevel = $ReportConfig.InfoLevel
        if ($Healthchecks) {
            $Healthcheck = $ReportConfig.HealthCheck
        }
        if ($Timestamp) {
            $FileName = $ReportName + " - " + (Get-Date -Format 'yyyy-MM-dd_HH.mm.ss')
        } else {
            $FileName = $ReportName
        }
    } else {
        Write-Error "$Type report JSON configuration file does not exist."
        break
    }

    # Import the As Built Config if one has been specified, else prompt the user to enter the information
    if ($AsBuiltConfigPath) {
        Write-Verbose "AsBuiltConfigPath has been specified, importing the information from the JSON file at $AsBuiltConfigPath"
        # Check location for As Built configuration file
        if (!(Test-Path -Path $AsBuiltConfigPath)) {
            Write-Error "The path specified for the As Built configuration file can not be resolved"
            break
        } else {
            $BaseConfig = Get-Content $AsBuiltConfigPath -Raw | ConvertFrom-Json
            $Author = $BaseConfig.Report.Author
            $Company = $BaseConfig.Company
            $MailServer = $BaseConfig.Mail.Server
            $MailServerPort = $BaseConfig.Mail.Port
            $MailCredentials = $BaseConfig.Mail.Credential
            $MailServerUseSSL = $BaseConfig.Mail.UseSSL      
            $MailFrom = $BaseConfig.Mail.From
            $MailTo = $BaseConfig.Mail.To
            $MailBody = $BaseConfig.Mail.Body
            Clear-Host
            # As Built Report Email Configuration
            Write-Host '---------------------------------------------' -ForegroundColor Cyan
            Write-Host '  <          Email Configuration          >  ' -ForegroundColor Cyan
            Write-Host '---------------------------------------------' -ForegroundColor Cyan  
            #if (!($SendEmail)) {
            #    $ConfigureMailSettings = Read-Host -Prompt "Would you like to enter SMTP configuration? (y/n)"
            #    while ("y", "n" -notcontains $ConfigureMailSettings) {
            #        $ConfigureMailSettings = Read-Host -Prompt "Would you like to enter SMTP configuration? (y/n)"
            #    }
            #}
            if ($SendEmail -and !($MailServer)) {
                $MailServer = Read-Host -Prompt "Enter the Email Server FQDN / IP Address"
                while (($MailServer -eq $null) -or ($MailServer -eq "")) {
                    $MailServer = Read-Host -Prompt "Enter the Email Server FQDN / IP Address" 
                }
                if (($MailServer -eq 'smtp.office365.com') -or ($MailServer -eq 'smtp.gmail.com')) {
                    $MailServerPort = Read-Host -Prompt "Enter the Email Server port number [587]"
                    if (($MailServerPort -eq $null) -or ($MailServerPort -eq "")) {
                        $MailServerPort = '587'
                    }
                } else {
                    $MailServerPort = Read-Host -Prompt "Enter the Email Server port number [25]"
                    if (($MailServerPort -eq $null) -or ($MailServerPort -eq "")) {
                        $MailServerPort = '25'
                    }
                }
                $MailServerUseSSL = Read-Host -Prompt "Use SSL for mail server connection? (true/false)"
                while ("true", "false" -notcontains $MailServerUseSSL) {
                    $MailServerUseSSL = Read-Host -Prompt "Use SSL for mail server connection? (true/false)"
                }
                $MailCredentials = Read-Host -Prompt "Require Mail Server Authentication? (true/false)"
                while ("true", "false" -notcontains $MailCredentials) {
                    $MailCredentials = Read-Host -Prompt "Require Mail Server Authentication? (true/false)"
                }
                $MailFrom = Read-Host -Prompt "Enter the Email Sender address"
                while (($MailFrom -eq $null) - ($MailFrom -eq "")) {
                    $MailFrom = Read-Host -Prompt "Enter the Email Sender address" 
                }
                $MailRecipients = @()
                do {
                    $MailTo = Read-Host -Prompt "Enter the Email Server receipient address"
                    $MailRecipients += $MailTo
                    $AnotherRecipient = @()
                    while ("y", "n" -notcontains $AnotherRecipient) {
                        $AnotherRecipient = Read-Host -Prompt "Do you want to enter another recipient? (y/n)" 
                    }
                }until($AnotherRecipient -eq "n")
                #[Array]$MailTo = Read-Host -Prompt "Enter the Email Server receipient address"
                #while (($MailTo -eq $null) -or ($MailTo -eq "")) {
                #    [Array]$MailTo = Read-Host -Prompt "Enter the Email Server receipient address" 
                #}
                $MailBody = Read-Host -Prompt "Enter the Email Message Body content [$("$ReportName attached")]"
                if (($MailBody -eq $null) -or ($MailBody -eq "")) {
                    $MailBody = "$ReportName attached"
                }
            }
            if ($SendEmail -and $MailCredentials) {
                Clear-Host
                Write-Host '---------------------------------------------' -ForegroundColor Cyan
                Write-Host '  <        Email Server Credentials       >  ' -ForegroundColor Cyan
                Write-Host '---------------------------------------------' -ForegroundColor Cyan
                $MailCredentials = Get-Credential -Message "Please enter the credentials for $MailServer"
            }
        }
    } else {
        Clear-Host
        # As Built Report Configuration Information
        Write-Host '---------------------------------------------' -ForegroundColor Cyan
        Write-Host '  <     As Built Report Configuration     >  ' -ForegroundColor Cyan
        Write-Host '---------------------------------------------' -ForegroundColor Cyan
        $SaveAsBuiltConfig = Read-Host -Prompt "Would you like to save the As Built configuration file? (y/n)"
        while ("y", "n" -notcontains $SaveAsBuiltConfig) {
            $SaveAsBuiltConfig = Read-Host -Prompt "Would you like to save the As Built configuration file? (y/n)"
        }
        if ($SaveAsBuiltConfig -eq "y") {
            $AsBuiltName = Read-Host -Prompt "Enter the name for the As Built report configuration file [AsBuiltReport]"
            if (($AsBuiltName -eq $null) -or ($AsBuiltName -eq "")) {
                $AsBuiltName = "AsBuiltReport"
            }
            $AsBuiltExportPath = Read-Host -Prompt "Enter the path to save the As Built report configuration file [$PSScriptRoot]"
            if (($AsBuiltExportPath -eq $null) -or ($AsBuiltExportPath -eq "")) {
                $AsBuiltExportPath = $PSScriptRoot
            }
            $AsBuiltConfigPath = Join-Path $AsBuiltExportPath $("$AsBuiltName.json")
            $BaseConfig = Get-Content $AsBuiltConfigPath -Raw | ConvertFrom-Json
        }

        Clear-Host
        # As Built Report Information
        Write-Host '---------------------------------------------' -ForegroundColor Cyan
        Write-Host '  <      As Built Report Information      >  ' -ForegroundColor Cyan
        Write-Host '---------------------------------------------' -ForegroundColor Cyan  
        
        $ReportName = Read-Host -Prompt "Enter the name of the As Built report [$($Report.Name)]"
        if (($ReportName -eq $null) -or ($ReportName -eq "")) {
            $ReportName = $Report.Name
        }
        if ($Timestamp) {
            $FileName = $ReportName + " - " + (Get-Date -Format 'yyyy-MM-dd_HH.mm.ss')
        } else {
            $FileName = $ReportName
        }
        $Version = Read-Host -Prompt "Enter the As Built report version [$($Report.Version)]"
        if (($Version -eq $null) -or ($Version -eq "")) {
            $Version = $Report.Version
        }
        $Status = Read-Host -Prompt "Enter the As Built report status [$($Report.Status)]"
        if (($Status -eq $null) -or ($Status -eq "")) {
            $Status = $Report.Status
        }
        $AsBuiltAuthor = Read-Host -Prompt "Enter the name of the Author for this As Built report [$Env:USERNAME]"
        if (($AsBuiltAuthor -eq $null) -or ($AsBuiltAuthor -eq "")) {
            $AsBuiltAuthor = $Env:USERNAME
        }
        Clear-Host
        Write-Host '---------------------------------------------' -ForegroundColor Cyan
        Write-Host '  <          Company Information          >  ' -ForegroundColor Cyan
        Write-Host '---------------------------------------------' -ForegroundColor Cyan
        $CompanyAsBuiltInfo = Read-Host -Prompt "Would you like to enter Company information for the As Built report? (y/n)"
        while ("y", "n" -notcontains $CompanyAsBuiltInfo) {
            $CompanyAsBuiltInfo = Read-Host -Prompt "Would you like to enter Company information for the As Built report? (y/n)"
        }
        if ($CompanyAsBuiltInfo -eq 'y') {
            $CompanyFullName = Read-Host -Prompt "Enter the Full Company Name"
            $CompanyShortName = Read-Host -Prompt "Enter the Company Short Name"
            $CompanyContact = Read-Host -Prompt "Enter the Company Contact"
            $CompanyEmailAddress = Read-Host -Prompt "Enter the Company Email Address"
            $CompanyPhone = Read-Host -Prompt "Enter the Company Phone"
            $CompanyAddress = Read-Host -Prompt "Enter the Company Address"
        }    

        Clear-Host
        # As Built Report Email Configuration
        Write-Host '---------------------------------------------' -ForegroundColor Cyan
        Write-Host '  <          Email Configuration          >  ' -ForegroundColor Cyan
        Write-Host '---------------------------------------------' -ForegroundColor Cyan  
        if (!($SendEmail)) {
            $ConfigureMailSettings = Read-Host -Prompt "Would you like to enter SMTP configuration? (y/n)"
            while ("y", "n" -notcontains $ConfigureMailSettings) {
                $ConfigureMailSettings = Read-Host -Prompt "Would you like to enter SMTP configuration? (y/n)"
            }
        }
        if (($SendEmail) -or ($ConfigureMailSettings -eq "y")) {
            $MailServer = Read-Host -Prompt "Enter the Email Server FQDN / IP Address"
            while (($MailServer -eq $null) -or ($MailServer -eq "")) {
                $MailServer = Read-Host -Prompt "Enter the Email Server FQDN / IP Address" 
            }
            if (($MailServer -eq 'smtp.office365.com') -or ($MailServer -eq 'smtp.gmail.com')) {
                $MailServerPort = Read-Host -Prompt "Enter the Email Server port number [587]"
                if (($MailServerPort -eq $null) -or ($MailServerPort -eq "")) {
                    $MailServerPort = '587'
                }
            } else {
                $MailServerPort = Read-Host -Prompt "Enter the Email Server port number [25]"
                if (($MailServerPort -eq $null) -or ($MailServerPort -eq "")) {
                    $MailServerPort = '25'
                }
            }
            $MailServerUseSSL = Read-Host -Prompt "Use SSL for mail server connection? (true/false)"
            while ("true", "false" -notcontains $MailServerUseSSL) {
                $MailServerUseSSL = Read-Host -Prompt "Use SSL for mail server connection? (true/false)"
            }
            $MailCredentials = Read-Host -Prompt "Require Mail Server Authentication? (true/false)"
            while ("true", "false" -notcontains $MailCredentials) {
                $MailCredentials = Read-Host -Prompt "Require Mail Server Authentication? (true/false)"
            }
            $MailFrom = Read-Host -Prompt "Enter the Email Sender address"
            while (($MailFrom -eq $null) -or ($MailFrom -eq "")) {
                $MailFrom = Read-Host -Prompt "Enter the Email Sender address" 
            }
            $MailRecipients = @()
            do {
                $MailTo = Read-Host -Prompt "Enter the Email Server receipient address"
                $MailRecipients += $MailTo
                $AnotherRecipient = @()
                while ("y", "n" -notcontains $AnotherRecipient) {
                    $AnotherRecipient = Read-Host -Prompt "Do you want to enter another recipient? (y/n)" 
                }
            }until($AnotherRecipient -eq "n")
            #[Array]$MailTo = Read-Host -Prompt "Enter the Email Server receipient address"
            #while (($MailTo -eq $null) -or ($MailTo -eq "")) {
            #    [Array]$MailTo = Read-Host -Prompt "Enter the Email Server receipient address" 
            #}
            $MailBody = Read-Host -Prompt "Enter the Email Message Body content [$("$ReportName attached")]"
            if (($MailBody -eq $null) -or ($MailBody -eq "")) {
                $MailBody = "$ReportName attached"
            }
        }
        $Body = [Ordered]@{
            Report = [Ordered]@{
                Author = $AsBuiltAuthor
            }
            Company = [Ordered]@{
                FullName = $CompanyFullName
                ShortName = $CompanyShortName
                Contact = $CompanyContact
                Email = $CompanyEmailAddress
                Phone = $CompanyPhone
                Address = $CompanyAddress
            }
            Mail = [Ordered]@{
                Server = $MailServer
                Port = $MailServerPort
                UseSSL = $MailServerUseSSL
                Credential = $MailCredentials
                From = $MailFrom
                To = $MailRecipients
                Body = $MailBody
            }   
        }
        if ($SaveAsBuiltConfig -eq "y") {
            $Body | ConvertTo-Json -Depth 10 | Out-File $AsBuiltConfigPath
            $BaseConfig = Get-Content $AsBuiltConfigPath -Raw | ConvertFrom-Json
            $Author = $BaseConfig.Report.Author
            $Company = $BaseConfig.Company
            $Mail = $BaseConfig.Mail
            if ($SendEmail -and $MailCredentials) {
                Clear-Host
                Write-Host '---------------------------------------------' -ForegroundColor Cyan
                Write-Host '  <        Email Server Credentials       >  ' -ForegroundColor Cyan
                Write-Host '---------------------------------------------' -ForegroundColor Cyan 
                $MailCredentials = Get-Credential -Message "Please enter the credentials for $MailServer"
            }
        } else {
            $Body | ConvertTo-Json -depth 10 | Out-File "$env:TEMP\AsBuiltReport.json" -Force
            $BaseConfig = Get-Content "$env:TEMP\AsBuiltReport.json" -Raw | ConvertFrom-Json
            $Author = $BaseConfig.Report.Author
            $Company = $BaseConfig.Company
            $Mail = $BaseConfig.Mail
            if ($SendEmail -and $MailCredentials) {
                Clear-Host
                Write-Host '---------------------------------------------' -ForegroundColor Cyan
                Write-Host '  <        Email Server Credentials       >  ' -ForegroundColor Cyan
                Write-Host '---------------------------------------------' -ForegroundColor Cyan 
                $MailCredentials = Get-Credential -Message "Please enter the credentials for $MailServer"
            }
            Remove-Item -Path "$env:TEMP\AsBuiltReport.json" -Confirm:$false
        }
    }
    #endregion Configuration Settings

    #region Create Report
    Clear-Host
    # Create As Built report
    $AsBuiltReport = Document $FileName -Verbose {
        # Set document style
        if ($StyleName) {
            $DocStyle = "$PSScriptRoot\Styles\$StyleName.ps1"
            if (Test-Path $DocStyle -ErrorAction SilentlyContinue) {
                .$DocStyle 
            } else {
                Write-Warning "Style name $StyleName does not exist"
            }
        }
        # Generate report
        if ($Type) {
            $ScriptFile = "$PSScriptRoot\Reports\$Type\$Type.ps1"
            if (Test-Path $ScriptFile -ErrorAction SilentlyContinue) {
                .$ScriptFile
            } else {
                Write-Error "$Type report does not exist"
                break
            }
        }
    }
    # Create and export document to specified format and path.
    $Document = $AsBuiltReport | Export-Document -PassThru -Path $Path -Format $Format
    #endregion Create Report

    #region Send-Email
    # Attach report(s) and send via email.
    if ($SendEmail) {
        if ($MailCredentials) {
            if ($MailServerUseSSL) {
                Send-MailMessage -Attachments $Document -To $MailTo -From $MailFrom -Subject $ReportName -Body $MailBody -SmtpServer $MailServer -Port $MailServerPort -UseSsl -Credential $MailCredentials
            } else {
                Send-MailMessage -Attachments $Document -To $MailTo -From $MailFrom -Subject $ReportName -Body $MailBody -SmtpServer $MailServer -Port $MailServerPort -UseSsl
            }
        } elseif ($MailServerUseSSL) {
            Send-MailMessage -Attachments $Document -To $MailTo -From $MailFrom -Subject $ReportName -Body $MailBody -SmtpServer $MailServer -Port $MailServerPort -UseSsl
        } else {
            Send-MailMessage -Attachments $Document -To $MailTo -From $MailFrom -Subject $ReportName -Body $MailBody -SmtpServer $MailServer -Port $MailServerPort
        }
    }
    #endregion Send-Email
}
