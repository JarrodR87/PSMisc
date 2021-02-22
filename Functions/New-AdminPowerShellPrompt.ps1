function New-AdminPowerShellPrompt {
    <#
        .SYNOPSIS
            Launches a PowerShell Session on the current PC as the specified Admin User
        .DESCRIPTION
            Uses PowerShell to start a new PowerShell Session as an Admin on the specified Domain or the current domain if none specified
        .PARAMETER AdminUser
            Admin User Name without Domain
        .PARAMETER Domain
            Optional Domain name. Will use the current domain if none specified
        .EXAMPLE
            New-AdminPowerShellPrompt -Domain TestDomain.com -AdminUser TestAdmin
        .EXAMPLE
            New-AdminPowerShellPrompt -AdminUser TestAdmin
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$AdminUser,
        [Parameter()]$Domain
    ) 
    BEGIN { 
        if ($NULL -eq $Domain) {
            $Domain = (Get-ADDomain).DNSRoot
        }
    } #BEGIN

    PROCESS {
        Start-Process powershell.exe -Credential $Domain\$AdminUser -NoNewWindow -ArgumentList "Start-Process powershell.exe -Verb runAs"
    } #PROCESS

    END { 

    } #END

} #FUNCTION