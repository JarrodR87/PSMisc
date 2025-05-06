function Clear-SystemKerberosTickets {
    <#
        .SYNOPSIS
            Purges Kerberos tickets for the SYSTEM account.
        .DESCRIPTION
            This function runs `klist -li 0x3e7 purge` to remove all Kerberos tickets associated with the SYSTEM logon session. It checks for administrative privileges before execution.
        .EXAMPLE
            Clear-SystemKerberosTickets
    #>
    [CmdletBinding()]
    Param(

    ) 
    BEGIN { 
        # Check for administrative privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

        if (-not $isAdmin) {
            Write-Warning "You must run this PowerShell session as Administrator."
            break
        }
    } #BEGIN

    PROCESS {
        Write-Host "Purging Kerberos tickets for SYSTEM account..." -ForegroundColor Yellow
        klist -li 0x3e7 purge
    } #PROCESS

    END { 
        Write-Host "Done." -ForegroundColor Green
    } #END
} #FUNCTION
