function Get-DaysinMonth {
    <#
        .SYNOPSIS
            Gets days per month for specified year
        .DESCRIPTION
            Gets dats per month for the year entered, and outputs a hashtable
        .PARAMETER Year
            Year to get days of the month
        .EXAMPLE
            Get-DaysinMonth -Year 2021
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$Year
    ) 
    BEGIN { 
        $January = [DateTime]::DaysInMonth($Year, 1)
        $February = [DateTime]::DaysInMonth($Year, 2)
        $March = [DateTime]::DaysInMonth($Year, 3)
        $April = [DateTime]::DaysInMonth($Year, 4)
        $May = [DateTime]::DaysInMonth($Year, 5)
        $June = [DateTime]::DaysInMonth($Year, 6)
        $July = [DateTime]::DaysInMonth($Year, 7)
        $August = [DateTime]::DaysInMonth($Year, 8)
        $September = [DateTime]::DaysInMonth($Year, 9)
        $October = [DateTime]::DaysInMonth($Year, 10)
        $November = [DateTime]::DaysInMonth($Year, 11)
        $December = [DateTime]::DaysInMonth($Year, 12)
        $JanuaryDays = @()
        $FebruaryDays = @()
        $MarchDays = @()
        $AprilDays = @()
        $MayDays = @()
        $JuneDays = @()
        $JulyDays = @()
        $AugustDays = @()
        $SeptemberDays = @()
        $OctoberDays = @()
        $NovemberDays = @()
        $DecemberDays = @()
        1..$January | ForEach-Object { $JanuaryDays += $_.ToString("00") }
        1..$February | ForEach-Object { $FebruaryDays += $_.ToString("00") }
        1..$March | ForEach-Object { $MarchDays += $_.ToString("00") }
        1..$April | ForEach-Object { $AprilDays += $_.ToString("00") }
        1..$May | ForEach-Object { $MayDays += $_.ToString("00") }
        1..$June | ForEach-Object { $JuneDays += $_.ToString("00") }
        1..$July | ForEach-Object { $JulyDays += $_.ToString("00") }
        1..$August | ForEach-Object { $AugustDays += $_.ToString("00") }
        1..$September | ForEach-Object { $SeptemberDays += $_.ToString("00") }
        1..$October | ForEach-Object { $OctoberDays += $_.ToString("00") }
        1..$November | ForEach-Object { $NovemberDays += $_.ToString("00") }
        1..$December | ForEach-Object { $DecemberDays += $_.ToString("00") }
    } #BEGIN

    PROCESS {
        $DaysinMonth = @{
            January   = $JanuaryDays
            February  = $FebruaryDays
            March     = $MarchDays
            April     = $AprilDays
            May       = $MayDays
            June      = $JuneDays
            July      = $JulyDays
            August    = $AugustDays
            September = $SeptemberDays
            October   = $OctoberDays
            November  = $NovemberDays
            December  = $DecemberDays
        }
    } #PROCESS

    END { 
        $DaysinMonth
    } #END

} #FUNCTION
