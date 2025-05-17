function Get-WSUSDownstreamServers {
    <#
        .SYNOPSIS
            Gets WSUS Downstream Servers from the Parent WSUS Server
        .DESCRIPTION
            Gets Downstream WSUS Server from specified Parent and returns a PowerShell Object
        .PARAMETER WSUSServer
            Parent WSUS Server FQDN
        .PARAMETER SSL
            Sets whether the Server is using SSL or not
        .PARAMETER WSUSServerPort
            Port to connect ot the Server on (Typically 8530 for non-SSL and 8531 for SSL)
        .EXAMPLE
            $WSUSDownstreams = @{
                WSUSServer           = 'WSUSSERVER.WSUS.TEST'
                WSUSServerPort       = '8531'
                SSL                  = $true
            }    
        
            Get-WSUSDownstreamServers @WSUSDownstreams
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]$WSUSServer,
        [Parameter()][switch]$SSL,
        [Parameter()][Int32]$WSUSServerPort
    ) 
    BEGIN { 
        $WSUSObject = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($WSUSServer, $SSL, $WSUSServerPort);
        $WSUSDownstreamServers = [Microsoft.UpdateServices.Administration.AdminProxy]::DownstreamServerCollection;

    } #BEGIN

    PROCESS {
           $WSUSDownstreamServers = $WSUSObject.GetDownstreamServers();
    } #PROCESS

    END { 
        $WSUSDownstreamServers
    } #END

} #FUNCTION
