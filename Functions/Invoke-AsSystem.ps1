function Invoke-AsSystem {
    <#
        .SYNOPSIS
            Runs a Program as NT Authority System
        .DESCRIPTION
            Uses a copy of PSExec to launch the specified Program as System
        .PARAMETER PSExecPath
            Path to psexec/psexec64
        .PARAMETER Program
            Program to run as System
        .EXAMPLE
            Invoke-AsSystem -PSExecPath "\\FILESERVER\PsExec64.exe" -Program powershell.exe
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$PSExecPath,
        [Parameter(Mandatory = $true)][string]$Program
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        Start-Process -FilePath cmd.exe -Verb Runas -ArgumentList "/k $PSExecPath -i -s $Program"
    } #PROCESS

    END { 

    } #END

} #FUNCTION