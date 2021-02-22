function Set-APCConfig {
    <#
        .SYNOPSIS
            Applies a Config to an APC or group of APC's
        .DESCRIPTION
            Applies either a Config or CSF File to multiple or singular APC's
        .PARAMETER APCS
            APC's to apply to
        .PARAMETER Username
            APC Username to login via FTP
        .PARAMETER Password
            APC Password to login via FTP
        .PARAMETER SettingsFile
            INI/CSF File to Apply
        .EXAMPLE
            Set-APCConfig -APCS '<APC IP's/NAME's>' -Username 'APC Username' -Password 'APC Password' -SettingsFile 'Path to INI/CSF File'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$APCS,
        [Parameter(Mandatory = $true)]$Username,
        [Parameter(Mandatory = $true)]$Password,
        [Parameter(Mandatory = $true)]$SettingsFile
    ) 
    BEGIN { 
        $PWDir = Get-Location

        Set-Location c:\temp

        $UploadConfig = @"
$Username
$Password
put $SettingsFile
bye
"@

    } #BEGIN

    PROCESS {
        $UploadConfig | out-file FTPCommand.txt

        foreach ($APC in $APCS) {
            ftp -s:FTPCommand.txt $APC
        }

        Remove-Item FTPCommand.txt

        Set-Location $PWDir

    } #PROCESS

    END { 

    } #END

} #FUNCTION