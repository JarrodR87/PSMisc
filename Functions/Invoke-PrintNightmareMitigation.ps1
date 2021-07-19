function Invoke-PrintNightmareMitigation {
    <#
        .SYNOPSIS
            Invokes Mitigatioins for PrintNightmare Vulnerability
        .DESCRIPTION
            Stops and Disabled the Service, and/or Sets the Deny ACL to the Drivers Directory. Can also be run to reverse the process
        .PARAMETER FixType
            Determines the single, or multiple actions to take, SetService and SetACL will implement the Mitigations. RemoveService and RemoveACL will remove the Mitigations
        .EXAMPLE
            Invoke-PrintNightmareMitigation -FixType SetService -ComputerName 'TestPC'
        .EXAMPLE
            Invoke-PrintNightmareMitigation -FixType SetACL,SetService -ComputerName 'TestPC'
        .EXAMPLE
            Invoke-PrintNightmareMitigation -FixType RemoveACL,RemoveService -ComputerName 'TestPC'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][ValidateSet("SetService", "RemoveService", "SetACL", "RemoveACL")]$FixType,
        [Parameter()]$ComputerName
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        foreach ($Computer in $ComputerName) {
            if ($FixType -eq 'SetService') {
                Invoke-Command -ComputerName $Computer -ScriptBlock {
                    Get-Service spooler | Stop-Service
                    Get-Service spooler | Set-Service -StartupType Disabled
                }
            }

            if ($FixType -eq 'RemoveService') {
                Invoke-Command -ComputerName $Computer -ScriptBlock {
                    Get-Service spooler | Set-Service -StartupType Automatic
                    Get-Service spooler | Start-Service
                }
            }

            if ($FixType -eq 'SetACL') {
                Invoke-Command -ComputerName $Computer -ScriptBlock {
                    $Path = "C:\Windows\System32\spool\drivers"
                    $Acl = Get-Acl $Path
                    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("System", "Modify", "ContainerInherit, ObjectInherit", "None", "Deny")
                    $Acl.AddAccessRule($AccessRule)
                    Set-Acl $Path $Acl
                }
            }

            if ($FixType -eq 'RemoveACL') {
                Invoke-Command -ComputerName $Computer -ScriptBlock {
                    $Path = "C:\Windows\System32\spool\drivers"
                    $Acl = Get-Acl $Path
                    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("System", "Modify", "ContainerInherit, ObjectInherit", "None", "Deny")
                    $Acl.RemoveAccessRule($AccessRule)
                    Set-Acl $Path $Acl
                }
            }
        }
    } #PROCESS

    END { 

    } #END

} #FUNCTION