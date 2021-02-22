function New-SCCMSession {
    <#
        .SYNOPSIS
            Starts a PowerShell Session to SCCM and connects to the Site
        .DESCRIPTION
            Imports the PowerShell Module for SCCM, and then changes location to that Site Code
        .EXAMPLE
            New-SCCMSession
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 
      
        if (-Not (Test-Path -Path 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1')) {
            Write-Host 'SCCM Console is not Installed, or Module not found'
        }
        else {
            Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'

            $SCCMSiteCode = (Get-PSDrive | Where-Object { $_.Provider.Name -eq 'CMSite' }).Name
            $Location = $SCCMSiteCode + ':'
        }


    } #BEGIN

    PROCESS {
        if (Test-Path -Path 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1') {
            Set-Location $Location
        }

    } #PROCESS

    END { 

    } #END

} #FUNCTION