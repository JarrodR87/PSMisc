function Get-LocalBitLockerReoveryKeys {
    <#
        .SYNOPSIS
            Collects Local BitLocker Reovery Keys
        .DESCRIPTION
            Collects Recovery Keys for Local BitLocker Encrypted Drives
        .EXAMPLE
            Get-LocalBitLockerReoveryKeys
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 
        $BitLockerVolumes = Get-BitLockerVolume
        $BitLockerReoveryKeys = @()
    } #BEGIN

    PROCESS {
        foreach ($BitLockerVolume in $BitLockerVolumes) {
            $Row = New-Object PSObject
            $Row | Add-Member -MemberType noteproperty -Name "MountPoint" -Value $BitLockerVolume.MountPoint
            $Row | Add-Member -MemberType noteproperty -Name "RecoveryKey" -Value ($BitLockerVolume.KeyProtector | where-object { $_.KeyProtectorType -like 'RecoveryPassword' }).RecoveryPassword

            $BitLockerReoveryKeys += $Row
            $BitLockerVolume = $NULL
        }
    } #PROCESS

    END { 
        $BitLockerReoveryKeys
    } #END

} #FUNCTION