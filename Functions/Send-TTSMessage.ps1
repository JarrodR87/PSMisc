function Send-TTSMessage {
    <#
        .SYNOPSIS
            Sends a test message to the specified PC, or the current PC if none is specified
        .DESCRIPTION
            Uses the Speech Synthesizer to send a TTS message to the current or remote PC that the current user has access to
        .PARAMETER Message
            The message you would like to send
        .PARAMETER ComputerName
            Optional - The PC that you would like to send the message to
        .EXAMPLE
            Send-TTSMessage -Message 'TEST' -ComputerName TESTPC01
        .EXAMPLE
            Send-TTSMessage -Message 'TEST'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$Message,
        [Parameter()]$ComputerName
    ) 

    BEGIN { 
        if ($NULL -eq $ComputerName) {
            $ComputerName = $ENV:COMPUTERNAME
        }
    } #BEGIN

    PROCESS {
        foreach ($Computer in $ComputerName) {
            
            If ($Computer -eq $ENV:COMPUTERNAME) {
                Add-Type -AssemblyName System.speech
                $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
                $speak.Speak($Message)
            }
            else {
                Invoke-Command -ScriptBlock {
                    param($Message)
                    Add-Type -AssemblyName System.speech
                    $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
                    $speak.Speak($Message)
                } -ComputerName $Computer -ArgumentList $Message
            }

        }
    
    } #PROCESS

    END { 

    } #END

} #FUNCTION