function Copy-WindowsFeature {
    <#
        .SYNOPSIS
            Copies Installed Windows Features from one Computer to another
        .DESCRIPTION
            Collects Installed Windows Features from one Computer and pipes that into a command to install them on another Computer
        .PARAMETER SourceComputerName
            Computer to collect list of Installed Windows Features From
        .PARAMETER DestinationComputerName
            Computer to Install Features
        .EXAMPLE
            Copy-WindowsFeature -SourceComputerName 'TESTPC1' -DestinationComputerName 'TestPC2'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$SourceComputerName,
        [Parameter(Mandatory = $true)]$DestinationComputerName
    ) 
    BEGIN { 
        $WindowsFeatures = Invoke-Command -ComputerName $SourceComputerName -ScriptBlock { (Get-WindowsFeature | where-object { $_.Installed -like 'TRUE' }) }
    } #BEGIN

    PROCESS {
        Install-WindowsFeature $WindowsFeatures
    } #PROCESS

    END { 

    } #END

} #FUNCTION
