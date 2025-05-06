function Invoke-SMTPPortTest {
    <#
        .SYNOPSIS
            Tests connectivity to a specified SMTP host on common SMTP ports.
        .DESCRIPTION
            This function tests the network connection to a given SMTP server using common SMTP ports:
            - 25 (SMTP)
            - 465 (Legacy SMTPS)
            - 587 (Modern SMTP with STARTTLS)
            - 2525 (Unofficial but widely used)
        .PARAMETER Host
            The hostname or IP address of the SMTP server to test.
        .EXAMPLE
            Invoke-SMTPPortTest -SMTPHost smtp.example.com
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$SMTPHost
    ) 
    BEGIN {
        $ports = 25, 465, 587, 2525
        Write-Host "Testing SMTP ports on $SMTPHost..." -ForegroundColor Cyan
    } #BEGIN

    PROCESS {
        foreach ($port in $ports) {
            Write-Host "Testing port $port..." -ForegroundColor Yellow
            Test-NetConnection -ComputerName $SMTPHost -Port $port
        }
    } #PROCESS

    END {
        Write-Host "SMTP port testing complete." -ForegroundColor Green
    } #END

} #FUNCTION
