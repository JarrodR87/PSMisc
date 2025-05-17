function Set-DuoStandaloneRegistrySettings {
    <#
        .SYNOPSIS
            Sets Duo Registry Settings when not set via GPO
        .DESCRIPTION
            An example of this use would be for a remote domain system
        .PARAMETER DuoHost
            Duo Host
        .PARAMETER SKey
            Duo Secret Key
        .PARAMETER IKey
            Duo Integration Key
        .PARAMETER AutoPush
            AutoPush Settings for Duo App
        .PARAMETER ElevationOfflineEnable
            Elevation Offline Enabled
        .PARAMETER ElevationOfflineEnrollment
            Elevation Offline Enrollment
        .PARAMETER ElevationProtectionMode
            Elevation Protection Mode
        .PARAMETER EnableSmartCards
            Enable Smart Cards
        .PARAMETER FailOpen
            Fail Open
        .PARAMETER OfflineAvailable
            Offline Available
        .PARAMETER OfflineMaxUsers
            Offline Max Users
        .PARAMETER RdpOnly
            RDP Only
        .PARAMETER WrapSmartCards
            Wrap Smart Cards
        .EXAMPLE
            $DuoStandaloneRegistrySettings = @{
                DuoHost                     = 'api-xxxxxxxx.duosecurity.com'
                SKey                        = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
                IKey                        = 'XXXXXXXXXXXXXXXXXXXX'
                AutoPush                    = '1'
                ElevationOfflineEnable      = '1'
                ElevationOfflineEnrollment  = '1'
                ElevationProtectionMode     = '2'
                EnableSmartCards            = '0'
                FailOpen                    = '1'
                OfflineAvailable            = '1'
                OfflineMaxUsers             = '3'
                RdpOnly                     = '0'
                WrapSmartCards              = '0'
            }
            Set-DuoStandaloneRegistrySettings @DuoStandaloneRegistrySettings
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$DuoHost,
        [Parameter(Mandatory = $true)]$SKey,
        [Parameter(Mandatory = $true)]$IKey,
        [Parameter(Mandatory = $true)]$AutoPush,
        [Parameter(Mandatory = $true)]$ElevationOfflineEnable,
        [Parameter(Mandatory = $true)]$ElevationOfflineEnrollment,
        [Parameter(Mandatory = $true)]$ElevationProtectionMode,
        [Parameter(Mandatory = $true)]$EnableSmartCards,
        [Parameter(Mandatory = $true)]$FailOpen,
        [Parameter(Mandatory = $true)]$OfflineAvailable,
        [Parameter(Mandatory = $true)]$OfflineMaxUsers,
        [Parameter(Mandatory = $true)]$RdpOnly,
        [Parameter(Mandatory = $true)]$WrapSmartCards
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'Host' -Value $DuoHost
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'SKey' -Value $SKey
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'IKey' -Value $IKey
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'AutoPush' -Value $AutoPush
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'ElevationOfflineEnable' -value $ElevationOfflineEnable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'ElevationOfflineEnrollment' -value $ElevationOfflineEnrollment
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'ElevationProtectionMode' -value $ElevationProtectionMode
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'EnableSmartCards' -value $EnableSmartCards
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'FailOpen' -value $FailOpen
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'OfflineAvailable' -value $OfflineAvailable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'OfflineMaxUsers' -value $OfflineMaxUsers
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'RdpOnly' -value $RdpOnly
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Duo Security\DuoCredProv" -Name 'WrapSmartCards' -value $WrapSmartCards
    } #PROCESS

    END { 

    } #END

} #FUNCTION