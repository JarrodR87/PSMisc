function New-RemoteDomainProgram {
    <#
        .SYNOPSIS
            Runs a Program or command as a user from a different domain
        .DESCRIPTION
            Runs a program using remote domain and remote username to execute it as if you were on that domain. May still show you locally as the user logged onto the machine, but will work correctly for access to remote domain resources.
        .PARAMETER User
            The Remote Domain User who has access to execute the command
        .PARAMETER Domain
            The Remote Domain you want to execute the command against
        .PARAMETER Command
            The Command to execute with the remote credentials
        .EXAMPLE
            New-RemoteDomainProgram -User TestUser -Domain TestDomain.com -Command PowerShell.exe
        .EXAMPLE
            New-RemoteDomainProgram -User TestUser -Domain TestDomain.com -Command mmc.exe
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$User,
        [Parameter(Mandatory = $true)]$Command,
        [Parameter()]$Domain
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        runas /netonly /user:$Domain\$User $Command
    } #PROCESS

    END { 

    } #END

} #FUNCTION