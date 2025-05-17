function Invoke-RSATInstallation {
    <#
        .SYNOPSIS
            Installs all RSAT Tools on Current PC
        .DESCRIPTION
            Queries all RSAT Tools available and Installs them. Requires internet Access
        .EXAMPLE
            Invoke-RSATInstallation
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
    } #PROCESS

    END { 

    } #END

} #FUNCTION
