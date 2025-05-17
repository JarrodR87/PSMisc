function New-HTMLTimestamp {
    <#
        .SYNOPSIS
            Creates a Timestamp to add to an HTML File
        .DESCRIPTION
            Uses the current date to timestamp the HTML Output of ConvertTo-Html
        .EXAMPLE
            ConvertTo-Html -PostContent (New-HTMLTimestamp)
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 
        $Date = (Get-Date)
    } #BEGIN

    PROCESS {
        $TimeStamp = "
<div>
<div>Created On: $Date</div>
</div>
"
        
    } #PROCESS

    END { 
        $TimeStamp
    } #END

} #FUNCTION
