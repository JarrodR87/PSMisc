function New-UserHomeDirectory {
    <#
        .SYNOPSIS
            Creates User Home Directories and assigns permissions
        .DESCRIPTION
            Creates User Home Directories in the specified location and sets the User to have Full Control Permissions to it
        .PARAMETER Identity
            User or Users to create Directories for
        .PARAMETER Path
            Path to the Directory where the User Directory should be created
        .PARAMETER Domain
            Optional - Will use current domain if none entered
        .EXAMPLE
            New-UserHomeDirectory -Identity TestUser -Path \\Server\UserDirectory\
        .EXAMPLE
            New-UserHomeDirectory -Identity TestUser,TestUser2 -Path \\Server\UserDirectory\
        .EXAMPLE
            New-UserHomeDirectory -Identity TestUser,TestUser2 -Domain TestDomain.com -Path \\Server\UserDirectory\
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$Identity,
        [Parameter(Mandatory = $true)]$Path,
        [Parameter()]$Domain
    ) 
    BEGIN { 
        if ($NULL -eq $Domain) {
            $Domain = (Get-ADDomain).DNSRoot
        }

        $Path = $Path.Trimend('\')
        $Path = $Path + '\'
    } #BEGIN

    PROCESS {
        foreach ($User in $Identity) {
            $Username = (Get-ADUser $User -Server $Domain).SamAccountName
            $HomePath = $Path + $User
            if (-Not (Test-Path -PathType Container -Path $HomePath)) {
                New-Item -Path $Path -ItemType Directory -Name $Username
            }
            $HomeAcl = Get-Acl $HomePath
            $HomeAr = New-Object System.Security.AccessControl.FileSystemAccessRule("$Username", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $HomeAcl.SetAccessRule($HomeAr)
            Set-Acl $HomePath $HomeAcl
        }
    } #PROCESS

    END { 

    } #END

} #FUNCTION