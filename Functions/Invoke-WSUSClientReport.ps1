function Invoke-WSUSClientReport {
    <#
        .SYNOPSIS
            Forces the PC to report Update status to WSUS
        .DESCRIPTION
            Starts an update session to scan for updates, and then reports current Update Status to the WSUS Server configured for the PC
        .EXAMPLE
            Invoke-WSUSClientReport
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        $updateSession = new-object -com "Microsoft.Update.Session"; $updates = $updateSession.CreateupdateSearcher().Search($criteria).Updates
        wuauclt /reportnow
    } #PROCESS

    END { 

    } #END

} #FUNCTION