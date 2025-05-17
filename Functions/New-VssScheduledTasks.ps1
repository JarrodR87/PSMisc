function New-VssScheduledTasks {
    <#
        .SYNOPSIS
            Configures Volume Shadow Copy and creates scheduled tasks to run it daily.

        .DESCRIPTION
            This function enables and configures Volume Shadow Copy for a specified drive letter,
            sets the maximum storage size, and creates two scheduled tasks to generate a shadow copy
            daily at 6:00 AM and 6:00 PM.

        .PARAMETER DriveLetter
            The drive letter to enable shadow copies for (e.g., 'C:').

        .PARAMETER MaxSize
            The maximum size to allocate for shadow storage (e.g., '10GB').

        .EXAMPLE
            New-VssScheduledTasks -DriveLetter "C:" -MaxSize "10GB"
            Enables Volume Shadow Copy on C: drive and sets scheduled tasks at 6 AM and 6 PM.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$DriveLetter,

        [Parameter(Mandatory)]
        [string]$MaxSize
    )

    BEGIN {
        # Ensure drive letter is in proper format
        if ($DriveLetter -notmatch "^[A-Z]:$") {
            throw "DriveLetter must be in the format 'C:'"
        }
    }

    PROCESS {
        # Enable and configure shadow storage
        vssadmin Resize ShadowStorage /For=$DriveLetter /On=$DriveLetter /MaxSize=$MaxSize
        vssadmin Add ShadowStorage /For=$DriveLetter /On=$DriveLetter /MaxSize=$MaxSize

        # Create initial shadow copy
        vssadmin Create Shadow /For=$DriveLetter

        # Set up scheduled task for 6:00 AM
        $ActionAM = New-ScheduledTaskAction -Execute "C:\Windows\System32\vssadmin.exe" -Argument "create shadow /for=$DriveLetter"
        $TriggerAM = New-ScheduledTaskTrigger -Daily -At 6:00AM
        Register-ScheduledTask -TaskName "ShadowCopy${DriveLetter}_AM" -Trigger $TriggerAM -Action $ActionAM -Description "Shadow copy task for drive $DriveLetter at 6:00 AM"

        # Set up scheduled task for 6:00 PM
        $ActionPM = New-ScheduledTaskAction -Execute "C:\Windows\System32\vssadmin.exe" -Argument "create shadow /for=$DriveLetter"
        $TriggerPM = New-ScheduledTaskTrigger -Daily -At 6:00PM
        Register-ScheduledTask -TaskName "ShadowCopy${DriveLetter}_PM" -Trigger $TriggerPM -Action $ActionPM -Description "Shadow copy task for drive $DriveLetter at 6:00 PM"
    }

    END {
        Write-Verbose "Shadow copy and scheduled tasks configured for drive $DriveLetter"
    }
}