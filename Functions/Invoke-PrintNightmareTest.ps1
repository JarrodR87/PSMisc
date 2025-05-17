function Invoke-PrintNightmareTest {
    <#
        .SYNOPSIS
            Test Service and ACL for PrintNightmare Vulnerability
        .DESCRIPTION
            Tests ACL for System being Denied and returns current Print Spooler Status and StartupType
        .PARAMETER ComputerName
            Computer or Computers to Test. Expectes an array of Names
        .EXAMPLE
            Invoke-PrintNightmareTest -ComputerName 'Test1','Test2'
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]$ComputerName
    ) 
    BEGIN { 
        $PrintNightmareStatus = @()
    } #BEGIN

    PROCESS {
        foreach ($Computer in $ComputerName) {
            $Service = Invoke-Command -ComputerName $Computer -ScriptBlock { Get-Service Spooler }

            $ACLTest = Invoke-Command -ComputerName $Computer -ScriptBlock {
                $Path = "C:\Windows\System32\spool\drivers"
                $Acl = Get-Acl $Path
                $Access = $Acl.Access
                $AccessFiltered = $Access | where-object { ($_.Identityreference -eq 'NT AUTHORITY\SYSTEM') }
                $AccessFiltered2 = $AccessFiltered | where-object { ($_.AccessControlType -eq 'Deny') }
                $AccessFiltered2
            }

            $Row = New-Object PSObject
            $Row | Add-Member -MemberType noteproperty -Name "Computer" -Value $Computer
            $Row | Add-Member -MemberType noteproperty -Name "ServiceStatus" -Value $Service.Status
            $Row | Add-Member -MemberType noteproperty -Name "ServiceStartType" -Value $Service.StartType
            $Row | Add-Member -MemberType noteproperty -Name "ACLSet" -Value ([bool]$ACLTest)

            $PrintNightmareStatus += $Row
        }
        
    } #PROCESS

    END { 
        $PrintNightmareStatus
    } #END

} #FUNCTION
