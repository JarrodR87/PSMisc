function Set-PrinterLPRPort {
    <#
        .SYNOPSIS
            Sets LPR Port Number on specified Printer Port
        .DESCRIPTION
            Changed LPR Port from the Default used by Windows (515) to one you specify
        .PARAMETER PortName
            Specified Port Name to
        .PARAMETER IPAddress
            Specified IP Address for the Printer Port
        .PARAMETER PortNumber
            Specified Port Number to change the Port to
        .EXAMPLE
            Set-PrinterLPRPort -PortName TestPort -IPAddress 127.0.0.1 -PortNumber 99999
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$PortName,
        [Parameter(Mandatory = $true)][string]$IPAddress,
        [Parameter(Mandatory = $true)][string]$PortNumber
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        cscript.exe /s C:\windows\System32\Printing_Admin_Scripts\en-us\prnport.vbs -a -r $PortName -2e -md -h $IPAddress -q secure -o lpr -n $PortNumber
    } #PROCESS

    END { 

    } #END

} #FUNCTION