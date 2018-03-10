#requires -Modules @{ModuleName="PScribo";ModuleVersion="0.7.21.110"},VMware.VimAutomation.Core,Meadowcroft.Srm

#region Script Help
<#
.SYNOPSIS  
    PowerShell script to document the configuration of VMware Site Recovery Manager in Word/HTML/Text formats
.DESCRIPTION
    Documents the configuration of VMware Site Recovery Manager in Word/HTML/Text formats
.NOTES
    Version:        0.1
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
    Credits:        @iainbrighton - PScribo module
.LINK
    https://github.com/tpcarman/Documentation-Scripts
    https://github.com/iainbrighton/PScribo	
.PARAMETER ReportName
    Specifies the report name.
    This parameter is optional.
    By default, the report name is 'VMware vSphere As Built Documentation'.
.PARAMETER ReportType
    (Currently Not in Use)
    Sepecifies the type of report to produce.
    Report types are as follows:
        * Summary
        * Detailed
        * Full
    This parameter is optional.
    By default, the report type is set to 'Detailed'.   
.PARAMETER Author
    Specifies the report's author.
    This parameter is optional and has a default value.
.PARAMETER Version
    Specifies the report version number.
    This parameter is optional and does not have a default value.
.PARAMETER Status
    Specifies the report document status.
    This parameter is optional.
    By default, the document status is set to 'Released'.
.PARAMETER Format
    Specifies the output format of the report.
    This parameter is mandatory.
    The supported output formats are WORD, HTML & TEXT.
    Multiple output formats may be specified.
    By default, the output format will be set to WORD.
.PARAMETER Style
    Specifies the document style of the report.
    This parameter is optional and does not have a default value.
.PARAMETER Path
    Specifies the path to save the report.
    This parameter is optional. If not specified the report will be saved in the current directory/folder.
.PARAMETER AddDateTime
    Specifies whether to append a date/time string to the report filename.
    This parameter is optional. 
    By default, the date/time string is not added to the report filename.
.PARAMETER SrmServer
    Specifies the IP/FQDN of the VMware SRM Server on which to connect.
    This parameter is mandatory.
.PARAMETER CompanyName
    Specifies the Company Name
    This parameter is optional and does not have a default value.
.PARAMETER CompanyContact
    Specifies the Company Contact's Name
    This parameter is optional and does not have a default value.
.PARAMETER CompanyEmail
    Specifies the Company Contact's Email Address
    This parameter is optional and does not have a default value.
.PARAMETER CompanyPhone
    Specifies the Company Contact's Phone Number
    This parameter is optional and does not have a default value.
.PARAMETER CompanyAddress
    Specifies the Company Office Address
    This parameter is optional and does not have a default value.
.PARAMETER SmtpServer
    (Currently Not in Use)
    Specifies the SMTP server address.
    This parameter is optional and does not have a default value.
.PARAMETER SmtpPort
    (Currently Not in Use)
    Specifies the SMTP port.
    If SmtpServer is used, this is an optional parameter.
	By default, the SMTP port is 25.
.PARAMETER UseSSL
    (Currently Not in Use)
    Specifies whether to use SSL for the SmtpServer.
    If SmtpServer is used, this is an optional parameter.
	Default is $False.
.PARAMETER From
    (Currently Not in Use)
	Specifies the From email address.
	If SmtpServer is used, this is a mandatory parameter.
.PARAMETER To
    (Currently Not in Use)
	Specifies the To email address.
	If SmtpServer is used, this is a mandatory parameter.
.EXAMPLE

#>
#endregion Script Help

#region Script Parameters
[CmdletBinding()]
Param(

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the path to save the report')]
    [ValidateNotNullOrEmpty()] 
    [String]$Path = $env:USERPROFILE + '\Documents',

    [Parameter(Mandatory = $True, HelpMessage = 'Please provide the IP/FQDN of the SRM Server')]
    [ValidateNotNullOrEmpty()]
    [String]$SrmServer = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the document output format')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Word", "Html", "Text")]
    [Array]$Format = 'WORD',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the document report type')]
    [ValidateNotNullOrEmpty()] 
    [String]$ReportType = 'Detailed',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the document report style')]
    [ValidateNotNullOrEmpty()] 
    [String]$Style = 'Default',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify whether to append a date/time string to the report filename')]
    [Switch]$AddDateTime = $False,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report name')]
    [ValidateNotNullOrEmpty()] 
    [String]$ReportName = 'VMware Site Recovery Manager As Built Documentation',
    
    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report author name')]
    [ValidateNotNullOrEmpty()] 
    [String]$Author = $env:USERNAME,

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report version number')]
    [ValidateNotNullOrEmpty()] 
    [String]$Version = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the report document status')]
    [ValidateNotNullOrEmpty()] 
    [String]$Status = 'Released',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Name')]
    [ValidateNotNullOrEmpty()] 
    [String]$CompanyName = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Address')]
    [ValidateNotNullOrEmpty()] 
    [String]$CompanyAddress = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Contact Name')]
    [ValidateNotNullOrEmpty()] 
    [String]$CompanyContact = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Contact Email Address')]
    [ValidateNotNullOrEmpty()] 
    [String]$CompanyEmail = '',

    [Parameter(Mandatory = $False, HelpMessage = 'Specify the Company Contact Phone Number')]
    [ValidateNotNullOrEmpty()] 
    [String]$CompanyPhone = ''
)
#endregion Script Parameters

Clear-Host

# Add Date & Time to document filename
if ($AddDateTime -and $CompanyName) {
    $Filename = "$CompanyName - $ReportName - " + (Get-Date -Format 'dd-MM-yyyy_HH.mm.ss')
}
elseif ($AddDateTime -and !$CompanyName) {
    $Filename = "$ReportName - " + (Get-Date -Format 'dd-MM-yyyy_HH.mm.ss')
}
elseif ($CompanyName) {
    $Filename = "$CompanyName - $ReportName"
}
else {
    $Filename = $ReportName
}



#region Document Template
$Document = Document $Filename -Verbose {
    # Document Options
    DocumentOption -EnableSectionNumbering -PageSize A4 -DefaultFont 'Calibri' -MarginLeftAndRight 71 -MarginTopAndBottom 71
    
    # Styles
    #region Default Document Style
    if ($Style -eq 'Default') {
        Style -Name 'Title' -Size 24 -Color '185F9D' -Font 'Calibri' -Align Center
        Style -Name 'Title 2' -Size 18 -Color '85C237' -Font 'Calibri' -Align Center
        Style -Name 'Title 3' -Size 12 -Color '85C237' -Font 'Calibri' -Align Left
        Style -Name 'Heading 1' -Size 16 -Color '185F9D' -Font 'Calibri'
        Style -Name 'Heading 2' -Size 14 -Color '185F9D' -Font 'Calibri'
        Style -Name 'Heading 3' -Size 12 -Color '185F9D' -Font 'Calibri'
        Style -Name 'Heading 4' -Size 11 -Color '185F9D' -Font 'Calibri'
        Style -Name 'Heading 5' -Size 10 -Color '185F9D' -Font 'Calibri' -Italic
        Style -Name 'H1 Exclude TOC' -Size 16 -Color '185F9D' -Font 'Calibri'
        Style -Name 'Normal' -Size 10 -Font 'Calibri' -Default
        Style -Name 'TOC' -Size 16 -Color '185F9D' -Font 'Calibri'
        Style -Name 'TableDefaultHeading' -Size 10 -Color 'FFFFFF' -BackgroundColor '464547' -Font 'Calibri'
        Style -Name 'TableDefaultRow' -Size 10 -Font 'Calibri'
        Style -Name 'TableDefaultAltRow' -Size 10 -BackgroundColor 'DDDDDD' -Font 'Calibri'
        Style -Name 'Error' -Size 10 -Font 'Calibri' -BackgroundColor 'EA5054'
        Style -Name 'Warning' -Size 10 -Font 'Calibri' -BackgroundColor 'FFFF00'
        Style -Name 'Info' -Size 10 -Font 'Calibri' -BackgroundColor '9CC2E5'
        Style -Name 'OK' -Size 10 -Font 'Calibri' -BackgroundColor '92D050'

        TableStyle -Id 'TableDefault' -HeaderStyle 'TableDefaultHeading' -RowStyle 'TableDefaultRow' -AlternateRowStyle 'TableDefaultAltRow' -BorderColor '464547' -Align Left -BorderWidth 0.5 -Default
    
        # Cover Page
        BlankLine -Count 11
        Paragraph -Style Title $ReportName
        If ($CompanyName) {
            Paragraph -Style Title2 $CompanyName
            BlankLine -Count 29
        }
        else {
            BlankLine -Count 30 
        }
        Paragraph -Style Title3 $Author
        Paragraph -Style Title3 (Get-Date -Format D)
        BlankLine
        PageBreak
    }
    #endregion Default Document Style
   
    # Table of Contents
    TOC -Name 'Table of Contents'
    PageBreak
    
    #endregion Document Template

    #region Script Variables
    $Creds = Get-Credential -Message 'Please enter vCenter Server credentials'
    $Srm = Connect-SrmServer $SrmServer -Credential $creds

    #endregion Script Variables

    #region Script Body
    # SRM Server Section
    Section -Style Heading1 'SRM Server' {
        Paragraph "The following section details the configuration of the Site Recovery Manager server."
        BlankLine
        
        #Section -Style Heading2
    }
}
#endregion Script Body

# Create and export document to specified format and path.
$Document | Export-Document -Path $Path -PassThru -Format $Format

# Disconnect vCenter Server
Disconnect-SrmServer -Server $SrmServer -Confirm:$false
