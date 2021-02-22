function Get-IISLogDirectory {
    <#
        .SYNOPSIS
            Gets Primary IIS Log Location for the Servers specified
        .DESCRIPTION
            Gets Primary Log Location for the Servers Specified, but the Site Level could be different
        .PARAMETER ComputerName
            Specified Computers to check Default IIS Log Location on
        .EXAMPLE
            Get-IISLogDirectory IISServer01
        .EXAMPLE
            Get-IISLogDirectory IISServer01,IISServer02
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$ComputerName
    ) 
    BEGIN { 
        $IISResults = @()
    } #BEGIN

    PROCESS {
        foreach ($IISServer in $ComputerName) {
            $IISLogs = Invoke-Command -ComputerName $IISServer -ScriptBlock { (Get-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults' -Name 'logfile') }
        
            $Row = New-Object PSObject
            $Row | Add-Member -MemberType noteproperty -Name "ComputerName" -Value ($IISLogs.PSComputerName | out-string)
            $Row | Add-Member -MemberType noteproperty -Name "directory" -Value ($IISLogs.directory | out-string)

            $IISResults += $Row
    
        }

        $IISResults

    } #PROCESS

    END { 
        
    } #END

} #FUNCTION