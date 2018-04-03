<#
.SYNOPSIS  
    Creates initial JSON configuration file for New-AsBuilt documentation scripts.
.DESCRIPTION
    Creates initial JSON configuration file for New-AsBuilt documentation scripts.
.NOTES
    Version:        1.0
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
.LINK
    https://github.com/tpcarman/Documentation-Scripts
#>

$body = [Ordered]@{
    Report  = [Ordered]@{
        Author = $Env:USERNAME
    }
    Company = [Ordered]@{
        Name    = ''
        Contact = ''
        Email   = ''
        Phone   = ''
        Address = ''
    }
    Mail    = [Ordered]@{
        Server = ''
        Port   = 25
        UseSSL = $false
        From   = ''
        To     = ''
    }   
}
$body | ConvertTo-Json | Out-File .\config.json