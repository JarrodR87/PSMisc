function Get-SQLDBInfo {
    <#
        .SYNOPSIS
            Q
        .DESCRIPTION
            Q
        .PARAMETER SQLServers
            S
        .EXAMPLE
            G
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$SQLServers
    ) 
    BEGIN { 

        $SQLDBInfo = @()
       
    } #BEGIN

    PROCESS {
        foreach ($SQLServer in $SQLServers) {
            $SQLServerDBQuery = (Get-SqlDatabase -ServerInstance $SQLServer | Select-Object *)
            
            foreach ($SQLServerDBQueryItem in $SQLServerDBQuery) {
                $Row = New-Object PSObject
                $Row | Add-Member -MemberType noteproperty -Name "DatabaseEngineType" -Value $SQLServerDBQueryItem.DatabaseEngineType
                $Row | Add-Member -MemberType noteproperty -Name "DatabaseEngineEdition" -Value $SQLServerDBQueryItem.DatabaseEngineEdition
                $Row | Add-Member -MemberType noteproperty -Name "Name" -Value $SQLServerDBQueryItem.Name
                $Row | Add-Member -MemberType noteproperty -Name "Collation" -Value $SQLServerDBQueryItem.Collation
                $Row | Add-Member -MemberType noteproperty -Name "CompatibilityLevel" -Value $SQLServerDBQueryItem.CompatibilityLevel
                $Row | Add-Member -MemberType noteproperty -Name "CreateDate" -Value $SQLServerDBQueryItem.CreateDate
                $Row | Add-Member -MemberType noteproperty -Name "DataSpaceUsage" -Value $SQLServerDBQueryItem.DataSpaceUsage
                $Row | Add-Member -MemberType noteproperty -Name "IndexSpaceUsage" -Value $SQLServerDBQueryItem.IndexSpaceUsage
                $Row | Add-Member -MemberType noteproperty -Name "LastBackupDate" -Value $SQLServerDBQueryItem.LastBackupDate
                $Row | Add-Member -MemberType noteproperty -Name "LastDifferentialBackupDate" -Value $SQLServerDBQueryItem.LastDifferentialBackupDate
                $Row | Add-Member -MemberType noteproperty -Name "LastGoodCheckDbTime" -Value $SQLServerDBQueryItem.LastGoodCheckDbTime
                $Row | Add-Member -MemberType noteproperty -Name "LastLogBackupDate" -Value $SQLServerDBQueryItem.LastLogBackupDate
                $Row | Add-Member -MemberType noteproperty -Name "PrimaryFilePath" -Value $SQLServerDBQueryItem.PrimaryFilePath
                $Row | Add-Member -MemberType noteproperty -Name "RecoveryModel" -Value $SQLServerDBQueryItem.RecoveryModel
                $Row | Add-Member -MemberType noteproperty -Name "ReplicationOptions" -Value $SQLServerDBQueryItem.ReplicationOptions
                $Row | Add-Member -MemberType noteproperty -Name "SizeMB" -Value $SQLServerDBQueryItem.Size
                $Row | Add-Member -MemberType noteproperty -Name "SpaceAvailableMB" -Value ($SQLServerDBQueryItem.SpaceAvailable/1024)
                $Row | Add-Member -MemberType noteproperty -Name "ServerVersion" -Value $SQLServerDBQueryItem.ServerVersion
                $Row | Add-Member -MemberType noteproperty -Name "LogFiles" -Value $SQLServerDBQueryItem.LogFiles
                $Row | Add-Member -MemberType noteproperty -Name "SQLServer" -Value $SQLServer

                $SQLDBInfo += $Row

                $SQLServerDBQuery = $null
            }            
        }

    } #PROCESS

    END { 
        $SQLDBInfo
    } #END

} #FUNCTION