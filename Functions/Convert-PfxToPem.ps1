function Convert-PfxToPem {
    <#
        .SYNOPSIS
            Converts a PFX certificate file to PEM format using OpenSSL.

        .DESCRIPTION
            This function uses OpenSSL to convert a `.pfx` (PKCS#12) certificate bundle to `.pem` format.
            The output PEM file includes the private key and certificate chain.

        .PARAMETER PfxPath
            The full path to the input `.pfx` file.

        .PARAMETER PemPath
            The full path where the resulting `.pem` file should be saved.

        .EXAMPLE
            Convert-PfxToPem -PfxPath "C:\certs\mycert.pfx" -PemPath "C:\certs\mycert.pem"
            Converts the PFX file to PEM format with no encryption on the private key.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$PfxPath,

        [Parameter(Mandatory)]
        [string]$PemPath
    )

    BEGIN {
        # Check OpenSSL availability
        $openssl = "openssl"
        if (-not (Get-Command $openssl -ErrorAction SilentlyContinue)) {
            throw "OpenSSL is not available in the system path. Please install OpenSSL or add it to PATH."
        }

        # Validate input file
        if (-not (Test-Path $PfxPath)) {
            throw "The specified PFX file does not exist: $PfxPath"
        }
    }

    PROCESS {
        $args = @("pkcs12", "-in", "`"$PfxPath`"", "-out", "`"$PemPath`"", "-nodes")
        & $openssl @args
    }

    END {
        Write-Verbose "PFX to PEM conversion completed: $PemPath"
    }
}