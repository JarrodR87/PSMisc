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
