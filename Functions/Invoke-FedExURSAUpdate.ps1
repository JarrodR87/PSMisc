function Invoke-FedExURSAUpdate {
    <#
        .SYNOPSIS
            Downloads FedEx Ursav Update and places it in specified location
        .DESCRIPTION
            Uses the PSFTP Module to download the Fedex Ursa Update
        .PARAMETER P1
            C
        .EXAMPLE
            Invoke-FedExURSAUpdate -UrsaLocalLocation C:\Temp
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$UrsaLocalLocation
    ) 
    BEGIN { 
        Import-Module PSFTP
        $FedExFTPCredential = [System.Management.Automation.PSCredential]::new("anonymous", [System.Security.SecureString]::new())
    } #BEGIN

    PROCESS {
        Set-FTPConnection -Server ftp://ftp.fedex.com -Session FedExUrsa -UsePassive -Credentials $FedExFTPCredential
        $Session = Get-FTPConnection -Session FedExUrsa 
        $URSAVFile = Get-FTPChildItem -Session $Session -Path /pub/ursa/URSAV5/ | Where-Object -FilterScript { $_.name -like 'ursav' }
        $URSAVFile | Get-FTPItem -Session $Session -LocalPath $UrsaLocalLocation
    } #PROCESS

    END { 

    } #END

} #FUNCTION