function New-FortiNACAuthHeader {
    <#
        .SYNOPSIS
            Creates Authentication Header needed by FortiNAC API Calls
        .DESCRIPTION
            Creates the FortiNAC API Header for Authentication based on the Key from the FortiNAC Manegement Interface
        .PARAMETER APIToken
            Token created in the FortiNAC Interface under Administrators
        .EXAMPLE
            New-FortiNACAuthHeader
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$APIToken
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        $FortiNACAuthHeader = @{Authorization = "Bearer $APIToken" }
    } #PROCESS

    END { 
        $FortiNACAuthHeader
    } #END

} #FUNCTION