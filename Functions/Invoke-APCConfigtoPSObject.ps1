function Invoke-APCConfigtoPSObject {
    <#
        .SYNOPSIS
            Converts APC Config file into PowerShell Readable Object
        .DESCRIPTION
            Parses Config Files from APC's
        .PARAMETER APCConfigFiles
            Config File or Files to convert to a PS Object
        .EXAMPLE
            Invoke-APCConfigtoPSObject -APCConfigFiles 'File1','File2'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$APCConfigFiles
    ) 
    BEGIN { 
        $APCResults = @()
    } #BEGIN

    PROCESS {
        foreach ($APCConfigFile in $APCConfigFiles) {
            $APCFile = Get-Content -Path $APCConfigFile
            $APCAOSVersion = $APCFile | Select-String "Network Management Card AOS"
            $APCAOSVersion = $APCAOSVersion -replace '; ' , ''
            $APCAppVersion = $APCFile | Select-String "APP v"
            $APCAppVersion = $APCAppVersion -replace '; ' , ''
            $APCHostName = $APCFile | Select-String "HostName"
            $APCHostName = $APCHostName -replace 'HostName=' , ''
            $APCName = $APCFile | Select-String '^Name='
            $APCName = $APCName -replace 'Name=' , ''
            $APCSystemIP = $APCFile | Select-String 'SystemIP'
            $APCSystemIP = $APCSystemIP -replace 'SystemIP=' , ''
            $APCSubnetMask = $APCFile | Select-String 'SubnetMask'
            $APCSubnetMask = $APCSubnetMask -replace 'SubnetMask=' , ''
            $APCDefaultGateway = $APCFile | Select-String '^DefaultGateway'
            $APCDefaultGateway = $APCDefaultGateway -replace 'DefaultGateway=' , ''
            $APCDomainName = $APCFile | Select-String 'DomainName'
            $APCDomainName = $APCDomainName -replace 'DomainName=' , ''
            $APCPrimaryDNSServerIP = $APCFile | Select-String 'PrimaryDNSServerIP'
            $APCPrimaryDNSServerIP = $APCPrimaryDNSServerIP -replace 'PrimaryDNSServerIP=' , ''
            $APCSecondaryDNSServerIP = $APCFile | Select-String 'SecondaryDNSServerIP'
            $APCSecondaryDNSServerIP = $APCSecondaryDNSServerIP -replace 'SecondaryDNSServerIP=' , ''
            $APCEmailServerName = $APCFile | Select-String 'EmailServerName'
            $APCEmailServerName = $APCEmailServerName -replace 'EmailServerName=' , ''
            $APCEmailFromName = $APCFile | Select-String 'EmailFromName'
            $APCEmailFromName = $APCEmailFromName -replace 'EmailFromName=' , ''
            $APCEmailReceiver1Address = $APCFile | Select-String 'EmailReceiver1Address'
            $APCEmailReceiver1Address = $APCEmailReceiver1Address -replace 'EmailReceiver1Address=' , ''
            $APCContact = $APCFile | Select-String 'Contact='
            $APCContact = $APCContact -replace 'Contact=' , ''
            $APCLocation = $APCFile | Select-String '^Location'
            $APCLocation = $APCLocation -replace 'Location=' , ''
            $APCNTPEnable = $APCFile | Select-String 'NTPEnable'
            $APCNTPEnable = $APCNTPEnable -replace 'NTPEnable=' , ''
            $APCNTPPrimaryServer = $APCFile | Select-String 'NTPPrimaryServer'
            $APCNTPPrimaryServer = $APCNTPPrimaryServer -replace 'NTPPrimaryServer=' , ''
            $APCNTPSecondaryServer = $APCFile | Select-String 'NTPSecondaryServer'
            $APCNTPSecondaryServer = $APCNTPSecondaryServer -replace 'NTPSecondaryServer=' , ''
        
            $Row = New-Object PSObject
            $Row | Add-Member -type NoteProperty -Name 'AOS Version' -Value $APCAOSVersion
            $Row | Add-Member -type NoteProperty -Name 'APP Version' -Value $APCAppVersion
            $Row | Add-Member -type NoteProperty -Name 'Hostname' -Value $APCHostName
            $Row | Add-Member -type NoteProperty -Name 'Name' -Value $APCName
            $Row | Add-Member -type NoteProperty -Name 'System IP' -Value $APCSystemIP
            $Row | Add-Member -type NoteProperty -Name 'Subnet Mask' -Value $APCSubnetMask
            $Row | Add-Member -type NoteProperty -Name 'Default Gateway' -Value $APCDefaultGateway
            $Row | Add-Member -type NoteProperty -Name 'Domain Name' -Value $APCDomainName
            $Row | Add-Member -type NoteProperty -Name 'Primary DNS Server' -Value $APCPrimaryDNSServerIP
            $Row | Add-Member -type NoteProperty -Name 'Secondary DNS Server' -Value $APCSecondaryDNSServerIP
            $Row | Add-Member -type NoteProperty -Name 'E-mail Server' -Value $APCEmailServerName
            $Row | Add-Member -type NoteProperty -Name 'E-mail From Address' -Value $APCEmailFromName
            $Row | Add-Member -type NoteProperty -Name 'E-mail To Address 1' -Value $APCEmailReceiver1Address
            $Row | Add-Member -type NoteProperty -Name 'Contact' -Value $APCContact
            $Row | Add-Member -type NoteProperty -Name 'Location' -Value $APCLocation
            $Row | Add-Member -type NoteProperty -Name 'NTP Enabled' -Value $APCNTPEnable
            $Row | Add-Member -type NoteProperty -Name 'NTP Primary Server' -Value $APCNTPPrimaryServer
            $Row | Add-Member -type NoteProperty -Name 'NTP Secondary Server' -Value $APCNTPSecondaryServer

            $APCResults += $Row
        }
    } #PROCESS

    END { 
        $APCResults
    } #END

} #FUNCTION