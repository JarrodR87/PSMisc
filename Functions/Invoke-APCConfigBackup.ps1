function Invoke-APCConfigBackup {
    <#
        .SYNOPSIS
            Backs up APC config files with the corresponding APC Name
        .DESCRIPTION
            Downloads Config file from APC/APC's specified
        .PARAMETER APCS
            APC's to Backup the Config from
        .PARAMETER Username
            APC Username to login via FTP
        .PARAMETER Password
            APC Password to login via FTP
        .PARAMETER BackupDir
            Backup Directory where the Configs will be stored
        .EXAMPLE
            Invoke-APCConfig -APCS '<APC IP's/NAME's>' -Username 'APC Username' -Password 'APC Password' -BackupDir 'Directory to store INI Files'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$APCS,
        [Parameter(Mandatory = $true)]$Username,
        [Parameter(Mandatory = $true)]$Password,
        [Parameter(Mandatory = $true)]$BackupDir
    ) 
    BEGIN { 
        $PWDir = Get-Location

        Set-Location $BackupDir

        $DownloadConfig = @"
$Username
$Password
get config.ini
bye
"@
    } #BEGIN

    PROCESS {
        $DownloadConfig | out-file FTPCommand.txt

        foreach ($APC in $APCS) {
            ftp -s:FTPCommand.txt $APC
            Rename-Item config.ini "$APC.ini"
            Move-Item "$APC.ini" -Destination $BackupDir
        }

        Remove-Item FTPCommand.txt

        Set-Location $PWDir
    } #PROCESS

    END { 

    } #END

} #FUNCTION