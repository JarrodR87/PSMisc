function Invoke-WSUSServerSynchronization {
    <#
        .SYNOPSIS
            Starts a WSUS Synchronization for Updates
        .DESCRIPTION
            Gets the WSUS Server and initiates a Synchronization against it
        .PARAMETER WSUSServer
            Server Name or FQDN Depending on how you have it configured
        .PARAMETER WSUSServerPort
            Optional - Only needed if Ports are not default
        .PARAMETER SSL
            True or False, Not needed, but will default to non SSL if not specified
        .EXAMPLE
            Invoke-WSUSServerSynchronization -WSUSServer WSUS01 -WSUSServerPort 8538 -SSL 'True'
        .EXAMPLE
            Invoke-WSUSServerSynchronization -WSUSServer WSUS01
        .EXAMPLE
            Invoke-WSUSServerSynchronization -WSUSServer WSUS01 -SSL 'True'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$WSUSServer,
        [Parameter()]$WSUSServerPort,
        [Parameter()]$SSL
    ) 
    BEGIN { 
        if ($SSL -eq 'True') {
            if ($NULL -eq $WSUSServerPort) {
                $WSUSServerPort = 8531
            }
            
            $WSUSServer = (Get-WsusServer -Name $WSUSServer -UseSsl -PortNumber $WSUSServerPort)
        }
        else {
            if ($NULL -eq $WSUSServerPort) {
                $WSUSServerPort = 8530
            }
            $WSUSServer = (Get-WsusServer -Name $WSUSServer -PortNumber $WSUSServerPort)
        }

    } #BEGIN

    PROCESS {
        $WSUSServer.GetSubscription().StartSynchronization()
    } #PROCESS

    END { 

    } #END

} #FUNCTION