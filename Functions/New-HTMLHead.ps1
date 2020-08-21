function New-HTMLHead {
    <#
        .SYNOPSIS
            Creates a Header for HTML Files to be used with ConvertTo-Html
        .DESCRIPTION
            Creates a header with some default information to make Tables exported to HTML show some formatting
        .EXAMPLE
            ConvertTo-Html -Head (New-HTMLHead)
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        $HtmlHead = '<style>
    body {
        background-color: white;
        font-family:      "Calibri";
    }

    table {
        border-width:     1px;
        border-style:     solid;
        border-color:     black;
        border-collapse:  collapse;
        width:            100%;
    }

    th {
        border-width:     1px;
        padding:          5px;
        border-style:     solid;
        border-color:     black;
        background-color: #98C6F3;
    }

    td {
        border-width:     1px;
        padding:          5px;
        border-style:     solid;
        border-color:     black;
        background-color: White;
    }

    tr {
        text-align:       left;
    }
</style>'
    } #PROCESS

    END { 
        $HtmlHead
    } #END

} #FUNCTION