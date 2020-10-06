function New-CertReq {
    <#
        .SYNOPSIS
            Gneerates a CSR using the specified information
        .DESCRIPTION
            Generates an INF/CSR with the Specified Certificate Information
        .PARAMETER CertFQDN
            FQDN of the Certificate needed
        .PARAMETER CustomerInfo
            Customer Information formatted as follows - "O = <COMPANYNAME>, STREET = <STREETADDRESS>, L = <CITY>, S = <STATE>, PostalCode = <ZIPCODE>, C = <COUNTRY>"
        .PARAMETER WorkingDir
            Directory to store the CSR/INF Files
        .PARAMETER SAN
            Subject Alternate Names to add to the Certificate (Optional)
        .EXAMPLE
            New-CertReq -CertFQDN Test.TestCompany.com -CustomerInfo "O = COMPANY, STREET = 123 Road, L = FakeTown, S = Texas, PostalCode = 12345, C = US" -WorkingDir 'c:\Temp'
        .EXAMPLE
            New-CertReq -CertFQDN Test.TestCompany.com -SAN 'test2.testcompany.com','testcompany.com' -CustomerInfo "O = COMPANY, STREET = 123 Road, L = FakeTown, S = Texas, PostalCode = 12345, C = US" -WorkingDir 'c:\Temp'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$CertFQDN,
        [Parameter(Mandatory = $true)]$CustomerInfo,
        [Parameter(Mandatory = $true)]$WorkingDir,
        [Parameter()]$SAN
    ) 
    BEGIN { 
        if ($NULL -eq $SAN) {
            $SANINFEntry = "dns=$CertFQDN"
        }
        
        else {
            $SANArray = @()

            foreach ($SANEntry in $SAN) {
                $SANArray += "&dns=$SANEntry"
            }

            $SANINFEntry = "dns=$CertFQDN" + (($SANArray -join ',') -replace ',', '')
        }
        

        $WorkingDir = $WorkingDir.Trimend('\')
        $WorkingDir = $WorkingDir + '\'

        $CSRPath = $WorkingDir + "$($CertFQDN)_.csr"
        $INFPath = $WorkingDir + "$($CertFQDN)_.inf"

        $Signature = '$Windows NT$' 


        $INF =
        @"
[Version]
Signature= "$Signature" 

[NewRequest]
Subject = "CN=$CertFQDN, $CustomerInfo"
KeySpec = 1
KeyLength = 4096
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0

[Strings]
szOID_SUBJECT_ALT_NAME2 = "2.5.29.17"
szOID_ENHANCED_KEY_USAGE = "2.5.29.37"
szOID_PKIX_KP_SERVER_AUTH = "1.3.6.1.5.5.7.3.1"
szOID_PKIX_KP_CLIENT_AUTH = "1.3.6.1.5.5.7.3.2"

[Extensions]
%szOID_SUBJECT_ALT_NAME2% = "{text}$SANINFEntry"
%szOID_ENHANCED_KEY_USAGE% = "{text}%szOID_PKIX_KP_SERVER_AUTH%,%szOID_PKIX_KP_CLIENT_AUTH%"

[EnhancedKeyUsageExtension]

OID=1.3.6.1.5.5.7.3.1 
"@
    } #BEGIN

    PROCESS {
        $INF | Out-File -filepath $INFPath -force
        certreq -new $INFPath $CSRPath
    } #PROCESS

    END { 

    } #END

} #FUNCTION