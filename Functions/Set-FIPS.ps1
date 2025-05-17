function Set-FIPS {
    <#
        .SYNOPSIS
            Enables or disables the FIPS algorithm policy on Windows.
        .DESCRIPTION
            Sets the registry value for FIPS compliance mode under the LSA policy path. Requires administrator privileges.
        .PARAMETER Enable
            Switch to enable FIPS mode.
        .PARAMETER Disable
            Switch to disable FIPS mode.
        .EXAMPLE
            Set-FIPS -Enable
        .EXAMPLE
            Set-FIPS -Disable
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, ParameterSetName = 'Enable')]
        [switch]$Enable,

        [Parameter(Mandatory = $false, ParameterSetName = 'Disable')]
        [switch]$Disable
    ) 
    BEGIN {
        $RegistryPath = 'HKLM:\System\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy'
        $Name = 'Enabled'
        if (-not (Test-Path $RegistryPath)) {
            Write-Verbose "Creating registry path: $RegistryPath"
            New-Item -Path $RegistryPath -Force | Out-Null
        }
    } #BEGIN

    PROCESS {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'Enable' {
                    Write-Verbose "Enabling FIPS mode"
                    Set-ItemProperty -Path $RegistryPath -Name $Name -Value 1 -Type DWord -Force
                }
                'Disable' {
                    Write-Verbose "Disabling FIPS mode"
                    Set-ItemProperty -Path $RegistryPath -Name $Name -Value 0 -Type DWord -Force
                }
                default {
                    Write-Warning "You must specify either -Enable or -Disable."
                }
            }
        }
        catch {
            Write-Error "Failed to modify FIPS registry setting: $_"
        }
    } #PROCESS

    END {
        Write-Verbose "FIPS configuration complete."
    } #END

} #FUNCTION