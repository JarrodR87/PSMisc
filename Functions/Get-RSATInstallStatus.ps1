function Get-RSATInstallStatus {
    <#
        .SYNOPSIS
            Gets RSAT Installation Status for current PC
        .DESCRIPTION
            Checks Windows Capabilities and lists RSAT Install Status
        .EXAMPLE
            Get-RSATInstallStatus
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        $RSATStatus = Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State
    } #PROCESS

    END { 
        $RSATStatus
    } #END

} #FUNCTION

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