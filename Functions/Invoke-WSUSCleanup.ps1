function Invoke-WSUSCleanup {
    <#
        .SYNOPSIS
            Initiates a WSUS Cleanup
        .DESCRIPTION
            Starts a WSUS Cleanup, and outputs the results as an Object
        .PARAMETER WSUSServer
            Server FQDN
        .PARAMETER SSL
            Sets whether the Server is using SSL or not
        .PARAMETER WSUSServerPort
            Port to connect ot the Server on (Typically 8530 for non-SSL and 8531 for SSL)
        .PARAMETER supersededUpdates
            One of the Flags for what to cleanup. This will remove Superseded Updates
        .PARAMETER expiredUpdates
            One of the Flags for what to cleanup. This will remove Expired Updates
        .PARAMETER obsoleteUpdates
            One of the Flags for what to cleanup. This will remove Obsolete Updates
        .PARAMETER compressUpdates
            One of the Flags for what to cleanup. This will Compress Updates
        .PARAMETER obsoleteComputers
            One of the Flags for what to cleanup. This will remove Obsolete Computers
        .PARAMETER unneededContentFiles
            One of the Flags for what to cleanup. This will remove any unnedded Content Files
        .EXAMPLE
            $WSUSCleanup = @{
                WSUSServer           = 'WSUSSERVER.WSUS.TEST'
                WSUSServerPort       = '8531'
                SSL                  = $true
                supersededUpdates    = $true
                expiredUpdates       = $true
                obsoleteUpdates      = $true
                compressUpdates      = $true
                obsoleteComputers    = $true
                unneededContentFiles = $true
            }    
        
            Invoke-WSUSCleanup @WSUSCleanup
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]$WSUSServer,
        [Parameter()][switch]$SSL,
        [Parameter()][Int32]$WSUSServerPort,
        [Parameter()][switch]$supersededUpdates,
        [Parameter()][switch]$expiredUpdates,
        [Parameter()][switch]$obsoleteUpdates,
        [Parameter()][switch]$compressUpdates,
        [Parameter()][switch]$obsoleteComputers,
        [Parameter()][switch]$unneededContentFiles
    )
    BEGIN { 
        [void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration");
        $WSUSObject = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($WSUSServer, $SSL, $WSUSServerPort);

        $WSUSCleanupResults = @()
    } #BEGIN

    PROCESS {
        $CleanupManager = $WSUSObject.GetCleanupManager();
        $CleanupScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope($supersededUpdates, $expiredUpdates, $obsoleteUpdates, $compressUpdates, $obsoleteComputers, $unneededContentFiles);
        $WSUSCleanupResults = $CleanupManager.PerformCleanup($CleanupScope)
    } #PROCESS

    END { 
        $WSUSCleanupResults
    } #END

} #FUNCTION