function Get-UserSessions {
    <#
        .SYNOPSIS
            Gets User Sessions from specified PC using QUser
        .DESCRIPTION
            Queries User Sessions on specified system and then displays them as a PowerShell Object
        .PARAMETER Computername
            Computer to check Sessions of
        .EXAMPLE
            Get-UserSessions -Computername 'TESTPC01'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$Computername
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        $Users = (((quser /SERVER:$Computername) -replace '^>', '') -replace '\s{2,}', ',').Trim()

        $Users | ForEach-Object {
            if ($_.Split(',').Count -eq 5) {
                Write-Output ($_ -replace '(^[^,]+)', '$1,')
            }
            else {
                Write-Output $_
            }
        } | ConvertFrom-Csv
    } #PROCESS

    END { 

    } #END

} #FUNCTION