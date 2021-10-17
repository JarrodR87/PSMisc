$Functions = Get-ChildItem $PSScriptRoot\Functions -Filter "*.ps1"

foreach ($Function in $Functions) {
    . $Function.FullName
}