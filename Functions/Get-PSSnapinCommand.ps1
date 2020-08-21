function Get-PSSnapinCommand {
    <#
        .SYNOPSIS
            Gets Commands for a PSSnapin
        .DESCRIPTION
            Checks loaded modules for the specified PSSnapin and pulls all commands within that module
        .PARAMETER SnapinName
            The PSSnapin you are looking for commands from
        .EXAMPLE
            Get-PSSnapinCommand -SnapinName SnapinTest
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$SnapinName
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        Add-PSSnapin $SnapinName
        Get-Command | Where-Object { $_.PSSnapin.Name -eq $SnapinName }
    } #PROCESS

    END { 

    } #END

} #FUNCTION