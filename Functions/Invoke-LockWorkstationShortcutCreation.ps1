function Invoke-LockWorkstationShortcutCreation {
    <#
        .SYNOPSIS
            Creates a Lock Workstation Shortcut on the Public Users Desktop
        .DESCRIPTION
            Creates a new Shortcut, and can optionally delete an old copy of this Shortcut, on the Public Users Desktop
        .PARAMETER RemoveExisting
            True/False to remove the old copy if existing
        .EXAMPLE
            Invoke-LockWorkstationShortcutCreation
        .EXAMPLE
            Invoke-LockWorkstationShortcutCreation -RemoveExisting True
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)][ValidateSet("True", "False")]$RemoveExisting
    ) 
    BEGIN { 
        if ($RemoveExisting -eq 'True') {
            Remove-Item "$env:Public\Desktop\LockWorkstation.lnk" -Force -ErrorAction SilentlyContinue
        }
      
        $LockWorkstation = @{
            TargetFile       = """C:\Windows\System32\rundll32.exe"""
            ShortcutFile     = "$env:Public\Desktop\LockWorkstation.lnk"
            Arguments        = "user32.dll, LockWorkStation"
            WorkingDirectory = 'C:\Windows\System32'
            IconLocation     = 'C:\Windows\system32\mstsc.exe,13'
        }
    } #BEGIN

    PROCESS {
        New-Shortcut @LockWorkstation
    } #PROCESS

    END { 

    } #END

} #FUNCTION