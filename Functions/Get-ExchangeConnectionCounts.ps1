function Get-ExchangeConnectionCounts {
    <#
        .SYNOPSIS
            Gets Exchange Connection Counts
        .DESCRIPTION
            Gets Connection Counts for OWA, RPC, and EAS
        .PARAMETER ComputerName
            Exchange Server, or Servers to check
        .EXAMPLE
            Get-ExchangeConnectionCounts -Computername TESTPC1
        .EXAMPLE
            Get-ExchangeConnectionCounts -Computername TESTPC1, TESTPC2     
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$ComputerName
    ) 
    BEGIN { 
        $ExchangeConnections = @()
    } #BEGIN

    PROCESS {
        Foreach ($Computer in $Computername) {
            $RPC = (Get-Counter "\MSExchange RpcClientAccess\User Count" -ComputerName $Computer).CounterSamples[0].Cookedvalue 
            $OWA = (Get-Counter "\MSExchange OWA\Current Unique Users"   -ComputerName $Computer).CounterSamples[0].Cookedvalue
            $EAS = [math]::Truncate((Get-Counter "\MSExchange ActiveSync\Requests/sec" -ComputerName $Computer).CounterSamples[0].Cookedvalue)


            $Row = New-Object PSObject
            $Row | Add-Member -MemberType noteproperty -Name "Computername" -Value $Computer
            $Row | Add-Member -MemberType noteproperty -Name "RPC" -Value $RPC
            $Row | Add-Member -MemberType noteproperty -Name "OWA" -Value $OWA
            $Row | Add-Member -MemberType noteproperty -Name "EAS" -Value $EAS

            $ExchangeConnections += $Row
        }
    } #PROCESS

    END { 
        $ExchangeConnections
    } #END

} #FUNCTION