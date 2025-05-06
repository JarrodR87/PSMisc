function Get-FolderInformation {
    <#
        .SYNOPSIS
            Gets folder size in MB and Count of Files
        .DESCRIPTION
            Rercurses from a top level folder, or folders, and returns the folder size, Count, and root path
        .PARAMETER Path
            Path, or Paths to the folders to check Size and Count
        .EXAMPLE
            Get-FolderInformation 'c:\Temp'
        .EXAMPLE
            Get-FolderInformation 'c:\Temp', 'C:\Temp2'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$Path
    ) 
    BEGIN { 
        $FolderInformation = @()
    } #BEGIN

    PROCESS {
        Foreach ($Folder in $Path) {
            $FolderData = Get-ChildItem -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum | Select-Object @{Name = "Size(MB)"; Expression = { ("{0:N2}" -f ($_.Sum / 1mb)) } }, Count

            $Row = New-Object PSObject
            $Row | Add-Member -MemberType noteproperty -Name "FolderRootPath" -Value $Folder
            $Row | Add-Member -MemberType noteproperty -Name "Count" -Value $FolderData.Count
            $Row | Add-Member -MemberType noteproperty -Name "Size(MB)" -Value $FolderData.'Size(MB)'

            $FolderInformation += $Row

            $FolderData = $Null
        }
    } #PROCESS

    END { 
        $FolderInformation
    } #END

} #FUNCTION
