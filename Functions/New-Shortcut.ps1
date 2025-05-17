function New-Shortcut {
    <#
        .SYNOPSIS
            Creates Shortcut
        .DESCRIPTION
            Creates a ShortCut based on the parameters provided
        .PARAMETER TargetFile
            File to Target
        .PARAMETER ShortcutFile
            Shortcut Location
        .PARAMETER Arguments
            Arguments for the Shortcut
        .PARAMETER WorkingDirectory
            Working Directory to Launch in
        .PARAMETER IconLocation
            Icon for the Shortcut
        .EXAMPLE
            New-Shortcut -TargetFile 'EXEPath' -ShortcutFile '"$env:Public\Desktop\Shortcut.lnk -Arguments 'ARGS' -WorkingDirectory 'C:\Windows' -IconLocation 'C:\Temp\Icon.ico'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$TargetFile,
        [Parameter(Mandatory = $true)]$ShortcutFile,
        [Parameter(Mandatory = $true)]$Arguments,
        [Parameter(Mandatory = $true)]$WorkingDirectory,
        [Parameter(Mandatory = $true)]$IconLocation
    ) 
    BEGIN { 
        $WScriptShell = New-Object -ComObject WScript.Shell

    } #BEGIN

    PROCESS {
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
        $Shortcut.TargetPath = $TargetFile
        $Shortcut.Arguments = $Arguments
        $Shortcut.WorkingDirectory = $WorkingDirectory
        $Shortcut.IconLocation = $IconLocation
    } #PROCESS

    END { 
        $Shortcut.Save()
    } #END

} #FUNCTION