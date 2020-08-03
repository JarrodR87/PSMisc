function Get-PSSnapinCommand {
    <#
        .SYNOPSIS
            Gets Commands for a PSSnapin
        .DESCRIPTION
            Checks loaded modules for the specified PSSnapin and pulls all commands within that module
        .PARAMETER SnapinName
            The PSSnapin you are looking for commands from
        .EXAMPLE
            Get-PSSnapinCommand -SnapinName SnapinTest
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$SnapinName
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        Add-PSSnapin $SnapinName
        Get-Command | Where-Object { $_.PSSnapin.Name -eq $SnapinName }
    } #PROCESS

    END { 

    } #END

} #FUNCTION


function Invoke-RoyalTSDomainDocCreation {
    <#
        .SYNOPSIS
            Creates a RoyalTS Document from a specified Domain with all Domain Servers
        .DESCRIPTION
            Queries a Domain for all Windows Servers, and uses their OU's to create a RoyalTS Document Structure for hthat Domain
        .PARAMETER Domain
            Domain to run the document creation against
        .EXAMPLE
            Invoke-RoyalTSDomainDocCreation -Domain contoso.com
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]$Domain
    ) 
    BEGIN { 
        if ($NULL -eq $Domain) {
            $Domain = ((Get-ADDomain).DNSRoot).ToUpper()
        }
        else {
            $Domain = $Domain.ToUpper()
        }
        
        Import-Module  RoyalDocument.PowerShell
        $FileName = $Domain + '.rtsz'
        $RoyalTSItems = @()


        function CreateRoyalFolderHierarchy() {
            param(
                [string]$folderStructure,
                [string]$splitter,
                $Folder
            )
            $currentFolder = $Folder

            $folderStructure -split $splitter | ForEach-Object {
                $folder = $_
                $existingFolder = Get-RoyalObject -Folder $currentFolder -Name $folder -Type RoyalFolder
                if ($existingFolder) {
                    Write-Verbose "Folder $folder already exists - using it"
                    $currentFolder = $existingFolder
                }
                else {
                    Write-Verbose "Folder $folder does not exist - creating it"
                    $newFolder = New-RoyalObject -Folder $currentFolder -Name $folder -Type RoyalFolder
                    $newFolder.CredentialFromParent = $true
                    $currentFolder = $newFolder
                }
            }
            return $currentFolder
        }
    } #BEGIN

    PROCESS {
        $ADServers = Get-ADComputer -Filter { (OperatingSystem -like "*windows*server*") -and (Enabled -eq "True") } -Properties * -Server $Domain


        foreach ($ADServer in $ADServers) {
            $FolderFix = $ADServer.CanonicalName -replace '/[^/]*$', ''

            $Row = New-Object PSObject
            $Row | Add-Member -type NoteProperty -Name 'Folder' -Value $FolderFix
            $Row | Add-Member -type NoteProperty -Name 'Name' -Value $ADServer.Name
            $Row | Add-Member -type NoteProperty -Name 'URI' -Value $ADServer.DNSHostName
            $RoyalTSItems += $Row
        }


        $RoyalStore = New-RoyalStore -UserName "PowerShellUser"
        $RoyalDoc = New-RoyalDocument -Store $RoyalStore -Name $Domain -FileName $FileName

        foreach ($RoyalTSItem in $RoyalTSItems) {
            $server = $RoyalTSItem
            Write-Host "Importing $($server.Name)"

            $lastFolder = CreateRoyalFolderHierarchy -folderStructure $server.Folder -Splitter  "\/" -Folder $RoyalDoc

            $newConnection = New-RoyalObject -Folder $lastFolder -Type RoyalRDSConnection -Name $server.Name
            $newConnection.URI = $server.URI
            $newConnection.CredentialFromParent = $true
            $newConnection.SmartReconnect = $true
        }

        Get-RoyalObject -Type RoyalFolder -Store $RoyalStore | Where-Object { $_.name -eq 'Connections' } | Remove-RoyalObject -force
        Get-RoyalObject -Type RoyalFolder -Store $RoyalStore | Where-Object { $_.name -eq 'Credentials' } | Remove-RoyalObject -force
        Get-RoyalObject -Type RoyalFolder -Store $RoyalStore | Where-Object { $_.name -eq 'Tasks' } | Remove-RoyalObject -force

        Set-RoyalSortOrder -Criteria1 Name -SortDirection1 Ascending -Folder $RoyalDoc -Recurse 1
        
    } #PROCESS

    END { 
        Out-RoyalDocument -Document $RoyalDoc -FileName $FileName
    } #END

} #FUNCTION


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


function New-UserHomeDirectory {
    <#
        .SYNOPSIS
            Creates User Home Directories and assigns permissions
        .DESCRIPTION
            Creates User Home Directories in the specified location and sets the User to have Full Control Permissions to it
        .PARAMETER Identity
            User or Users to create Directories for
        .PARAMETER Path
            Path to the Directory where the User Directory should be created
        .PARAMETER Domain
            Optional - Will use current domain if none entered
        .EXAMPLE
            New-UserHomeDirectory -Identity TestUser -Path \\Server\UserDirectory\
        .EXAMPLE
            New-UserHomeDirectory -Identity TestUser,TestUser2 -Path \\Server\UserDirectory\
        .EXAMPLE
            New-UserHomeDirectory -Identity TestUser,TestUser2 -Domain TestDomain.com -Path \\Server\UserDirectory\
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$Identity,
        [Parameter(Mandatory = $true)]$Path,
        [Parameter()]$Domain
    ) 
    BEGIN { 
        if ($NULL -eq $Domain) {
            $Domain = (Get-ADDomain).DNSRoot
        }

        $Path = $Path.Trimend('\')
        $Path = $Path + '\'
    } #BEGIN

    PROCESS {
        foreach ($User in $Identity) {
            $Username = (Get-ADUser $User -Server $Domain).SamAccountName
            $HomePath = $Path + $User
            if (-Not (Test-Path -PathType Container -Path $HomePath)) {
                New-Item -Path $Path -ItemType Directory -Name $Username
            }
            $HomeAcl = Get-Acl $HomePath
            $HomeAr = New-Object System.Security.AccessControl.FileSystemAccessRule("$Username", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $HomeAcl.SetAccessRule($HomeAr)
            Set-Acl $HomePath $HomeAcl
        }
    } #PROCESS

    END { 

    } #END

} #FUNCTION


function New-TestFiles {
    <#
        .SYNOPSIS
            Creates Files with created/modified dates for the specified Year. Useful for testing file retention and date-based scripts
        .DESCRIPTION
            Creates Files and directories for the current year or specified year with directories for each month and files in the directory for each day of that month for that year
        .PARAMETER Year
            Specified year for creating the test files for
        .PARAMETER Path
            File Path to the location to create the Test Files
        .EXAMPLE
            New-TestFiles -Year 2016 -Path \\Server\TestLocation
        .EXAMPLE
            New-TestFiles -Year 2020 -Path \\Server\TestLocation
        .EXAMPLE
            New-TestFiles -Path \\Server\TestLocation
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]$Year,
        [Parameter(Mandatory = $true)]$Path
    ) 
    BEGIN { 

        if ($NULL -eq $Year) {
            $Year = (get-date).year
        }

        # Gets Number of Days for all Months in $TestYear and saves them as their own variables
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
    } #BEGIN

    PROCESS {
        # Creates Month Folders at $Path
        New-item -ItemType Directory -Name "01-January" -Path $Path
        (Get-Item -Path "$Path\01-January").CreationTime = "01/01/$Year 12:30AM"
        (Get-Item -Path "$Path\01-January").LastWriteTime = "01/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "02-February" -Path $Path
        (Get-Item -Path "$Path\02-February").CreationTime = "02/01/$Year 12:30AM"
        (Get-Item -Path "$Path\02-February").LastWriteTime = "02/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "03-March" -Path $Path
        (Get-Item -Path "$Path\03-March").CreationTime = "03/01/$Year 12:30AM"
        (Get-Item -Path "$Path\03-March").LastWriteTime = "03/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "04-April" -Path $Path
        (Get-Item -Path "$Path\04-April").CreationTime = "04/01/$Year 12:30AM"
        (Get-Item -Path "$Path\04-April").LastWriteTime = "04/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "05-May" -Path $Path
        (Get-Item -Path "$Path\05-May").CreationTime = "05/01/$Year 12:30AM"
        (Get-Item -Path "$Path\05-May").LastWriteTime = "05/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "06-June" -Path $Path
        (Get-Item -Path "$Path\06-June").CreationTime = "06/01/$Year 12:30AM"
        (Get-Item -Path "$Path\06-June").LastWriteTime = "06/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "07-July" -Path $Path
        (Get-Item -Path "$Path\07-July").CreationTime = "07/01/$Year 12:30AM"
        (Get-Item -Path "$Path\07-July").LastWriteTime = "07/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "08-August" -Path $Path
        (Get-Item -Path "$Path\08-August").CreationTime = "08/01/$Year 12:30AM"
        (Get-Item -Path "$Path\08-August").LastWriteTime = "08/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "09-September" -Path $Path
        (Get-Item -Path "$Path\09-September").CreationTime = "09/01/$Year 12:30AM"
        (Get-Item -Path "$Path\09-September").LastWriteTime = "09/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "10-October" -Path $Path
        (Get-Item -Path "$Path\10-October").CreationTime = "10/01/$Year 12:30AM"
        (Get-Item -Path "$Path\10-October").LastWriteTime = "10/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "11-November" -Path $Path
        (Get-Item -Path "$Path\11-November").CreationTime = "11/01/$Year 12:30AM"
        (Get-Item -Path "$Path\11-November").LastWriteTime = "11/01/$Year 12:30AM"
        New-item -ItemType Directory -Name "12-December" -Path $Path
        (Get-Item -Path "$Path\12-December").CreationTime = "12/01/$Year 12:30AM"
        (Get-Item -Path "$Path\12-December").LastWriteTime = "12/01/$Year 12:30AM"

        # Expands Count of Days Variable to an array and sets it to two decimal places, then creates files and sets creation/modification dates for each dat of the month for each month
        #January
        $JanuaryDays = @()
        1..$January | ForEach-Object { $JanuaryDays += $_.ToString("00") }

        foreach ($JanuaryDay in $JanuaryDays) {
            New-item -ItemType File -Path "$Path\01-January\" -Name "$JanuaryDay.txt"
            (Get-ChildItem "$Path\01-January\$JanuaryDay.txt").CreationTime = "01/$JanuaryDay/$Year 12:30AM"
            (Get-ChildItem "$Path\01-January\$JanuaryDay.txt").LastWriteTime = "01/$JanuaryDay/$Year 12:30AM"
        }

        #February
        $FebruaryDays = @()
        1..$February | ForEach-Object { $FebruaryDays += $_.ToString("00") }

        foreach ($FebruaryDay in $FebruaryDays) {
            New-item -ItemType File -Path "$Path\02-February\" -Name "$FebruaryDay.txt"
            (Get-ChildItem "$Path\02-February\$FebruaryDay.txt").CreationTime = "02/$FebruaryDay/$Year 12:30AM"
            (Get-ChildItem "$Path\02-February\$FebruaryDay.txt").LastWriteTime = "02/$FebruaryDay/$Year 12:30AM"
        }

        #March
        $MarchDays = @()
        1..$March | ForEach-Object { $MarchDays += $_.ToString("00") }

        foreach ($MarchDay in $MarchDays) {
            New-item -ItemType File -Path "$Path\03-March\" -Name "$MarchDay.txt"
            (Get-ChildItem "$Path\03-March\$MarchDay.txt").CreationTime = "03/$MarchDay/$Year 12:30AM"
            (Get-ChildItem "$Path\03-March\$MarchDay.txt").LastWriteTime = "03/$MarchDay/$Year 12:30AM"
        }

        #April
        $AprilDays = @()
        1..$April | ForEach-Object { $AprilDays += $_.ToString("00") }

        foreach ($AprilDay in $AprilDays) {
            New-item -ItemType File -Path "$Path\04-April\" -Name "$AprilDay.txt"
            (Get-ChildItem "$Path\04-April\$AprilDay.txt").CreationTime = "04/$AprilDay/$Year 12:30AM"
            (Get-ChildItem "$Path\04-April\$AprilDay.txt").LastWriteTime = "04/$AprilDay/$Year 12:30AM"
        }

        #May
        $MayDays = @()
        1..$May | ForEach-Object { $MayDays += $_.ToString("00") }

        foreach ($MayDay in $MayDays) {
            New-item -ItemType File -Path "$Path\05-May\" -Name "$MayDay.txt"
            (Get-ChildItem "$Path\05-May\$MayDay.txt").CreationTime = "05/$MayDay/$Year 12:30AM"
            (Get-ChildItem "$Path\05-May\$MayDay.txt").LastWriteTime = "05/$MayDay/$Year 12:30AM"
        }

        #June
        $JuneDays = @()
        1..$June | ForEach-Object { $JuneDays += $_.ToString("00") }

        foreach ($JuneDay in $JuneDays) {
            New-item -ItemType File -Path "$Path\06-June\" -Name "$JuneDay.txt"
            (Get-ChildItem "$Path\06-June\$JuneDay.txt").CreationTime = "06/$JuneDay/$Year 12:30AM"
            (Get-ChildItem "$Path\06-June\$JuneDay.txt").LastWriteTime = "06/$JuneDay/$Year 12:30AM"
        }

        #July
        $JulyDays = @()
        1..$July | ForEach-Object { $JulyDays += $_.ToString("00") }

        foreach ($JulyDay in $JulyDays) {
            New-item -ItemType File -Path "$Path\07-July\" -Name "$JulyDay.txt"
            (Get-ChildItem "$Path\07-July\$JulyDay.txt").CreationTime = "07/$JulyDay/$Year 12:30AM"
            (Get-ChildItem "$Path\07-July\$JulyDay.txt").LastWriteTime = "07/$JulyDay/$Year 12:30AM"
        }

        #August
        $AugustDays = @()
        1..$August | ForEach-Object { $AugustDays += $_.ToString("00") }

        foreach ($AugustDay in $AugustDays) {
            New-item -ItemType File -Path "$Path\08-August\" -Name "$AugustDay.txt"
            (Get-ChildItem "$Path\08-August\$AugustDay.txt").CreationTime = "08/$AugustDay/$Year 12:30AM"
            (Get-ChildItem "$Path\08-August\$AugustDay.txt").LastWriteTime = "08/$AugustDay/$Year 12:30AM"
        }

        #September
        $SeptemberDays = @()
        1..$September | ForEach-Object { $SeptemberDays += $_.ToString("00") }

        foreach ($SeptemberDay in $SeptemberDays) {
            New-item -ItemType File -Path "$Path\09-September\" -Name "$SeptemberDay.txt"
            (Get-ChildItem "$Path\09-September\$SeptemberDay.txt").CreationTime = "09/$SeptemberDay/$Year 12:30AM"
            (Get-ChildItem "$Path\09-September\$SeptemberDay.txt").LastWriteTime = "09/$SeptemberDay/$Year 12:30AM"
        }

        #October
        $OctoberDays = @()
        1..$October | ForEach-Object { $OctoberDays += $_.ToString("00") }

        foreach ($OctoberDay in $OctoberDays) {
            New-item -ItemType File -Path "$Path\10-October\" -Name "$OctoberDay.txt"
            (Get-ChildItem "$Path\10-October\$OctoberDay.txt").CreationTime = "10/$OctoberDay/$Year 12:30AM"
            (Get-ChildItem "$Path\10-October\$OctoberDay.txt").LastWriteTime = "10/$OctoberDay/$Year 12:30AM"
        }

        #November
        $NovemberDays = @()
        1..$November | ForEach-Object { $NovemberDays += $_.ToString("00") }

        foreach ($NovemberDay in $NovemberDays) {
            New-item -ItemType File -Path "$Path\11-November\" -Name "$NovemberDay.txt"
            (Get-ChildItem "$Path\11-November\$NovemberDay.txt").CreationTime = "11/$NovemberDay/$Year 12:30AM"
            (Get-ChildItem "$Path\11-November\$NovemberDay.txt").LastWriteTime = "11/$NovemberDay/$Year 12:30AM"
        }

        #December
        $DecemberDays = @()
        1..$December | ForEach-Object { $DecemberDays += $_.ToString("00") }

        foreach ($DecemberDay in $DecemberDays) {
            New-item -ItemType File -Path "$Path\12-December\" -Name "$DecemberDay.txt"
            (Get-ChildItem "$Path\12-December\$DecemberDay.txt").CreationTime = "12/$DecemberDay/$Year 12:30AM"
            (Get-ChildItem "$Path\12-December\$DecemberDay.txt").LastWriteTime = "12/$DecemberDay/$Year 12:30AM"
        }
    } #PROCESS

    END { 

    } #END

} #FUNCTION


function Get-IISLogDirectory {
    <#
        .SYNOPSIS
            Gets Primary IIS Log Location for the Servers specified
        .DESCRIPTION
            Gets Primary Log Location for the Servers Specified, but the Site Level could be different
        .PARAMETER ComputerName
            Specified Computers to check Default IIS Log Location on
        .EXAMPLE
            Get-IISLogDirectory IISServer01
        .EXAMPLE
            Get-IISLogDirectory IISServer01,IISServer02
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$ComputerName
    ) 
    BEGIN { 
        $IISResults = @()
    } #BEGIN

    PROCESS {
        foreach ($IISServer in $ComputerName) {
            $IISLogs = Invoke-Command -ComputerName $IISServer -ScriptBlock { (Get-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults' -Name 'logfile') }
        
            $Row = New-Object PSObject
            $Row | Add-Member -MemberType noteproperty -Name "ComputerName" -Value ($IISLogs.PSComputerName | out-string)
            $Row | Add-Member -MemberType noteproperty -Name "directory" -Value ($IISLogs.directory | out-string)

            $IISResults += $Row
    
        }

        $IISResults

    } #PROCESS

    END { 
        
    } #END

} #FUNCTION


function New-AdminPowerShellPrompt {
    <#
        .SYNOPSIS
            Launches a PowerShell Session on the current PC as the specified Admin User
        .DESCRIPTION
            Uses PowerShell to start a new PowerShell Session as an Admin on the specified Domain or the current domain if none specified
        .PARAMETER AdminUser
            Admin User Name without Domain
        .PARAMETER Domain
            Optional Domain name. Will use the current domain if none specified
        .EXAMPLE
            New-AdminPowerShellPrompt -Domain TestDomain.com -AdminUser TestAdmin
        .EXAMPLE
            New-AdminPowerShellPrompt -AdminUser TestAdmin
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$AdminUser,
        [Parameter()]$Domain
    ) 
    BEGIN { 
        if ($NULL -eq $Domain) {
            $Domain = (Get-ADDomain).DNSRoot
        }
    } #BEGIN

    PROCESS {
        Start-Process powershell.exe -Credential $Domain\$AdminUser -NoNewWindow -ArgumentList "Start-Process powershell.exe -Verb runAs"
    } #PROCESS

    END { 

    } #END

} #FUNCTION


function New-RemoteDomainProgram {
    <#
        .SYNOPSIS
            Runs a Program or command as a user from a different domain
        .DESCRIPTION
            Runs a program using remote domain and remote username to execute it as if you were on that domain. May still show you locally as the user logged onto the machine, but will work correctly for access to remote domain resources.
        .PARAMETER User
            The Remote Domain User who has access to execute the command
        .PARAMETER Domain
            The Remote Domain you want to execute the command against
        .PARAMETER Command
            The Command to execute with the remote credentials
        .EXAMPLE
            New-RemoteDomainProgram -User TestUser -Domain TestDomain.com -Command PowerShell.exe
        .EXAMPLE
            New-RemoteDomainProgram -User TestUser -Domain TestDomain.com -Command mmc.exe
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$User,
        [Parameter(Mandatory = $true)]$Command,
        [Parameter()]$Domain
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        runas /netonly /user:$Domain\$User $Command
    } #PROCESS

    END { 

    } #END

} #FUNCTION


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


function Get-ExchangeConnectionCounts {
    <#
        .SYNOPSIS
            Gets Exchange Connection Counts
        .DESCRIPTION
            Gets Connection Counts for OWA, RPC, and EAS
        .PARAMETER ComputerName
            Exchange Server, or Servers to check
        .EXAMPLE
            Get-ExchangeConnectionCounts -Computername TESTPC1
        .EXAMPLE
            Get-ExchangeConnectionCounts -Computername TESTPC1, TESTPC2     
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$ComputerName
    ) 
    BEGIN { 
        $ExchangeConnections = @()
    } #BEGIN

    PROCESS {
        Foreach ($Computer in $Computername) {
            $RPC = (Get-Counter "\MSExchange RpcClientAccess\User Count" -ComputerName $Computer).CounterSamples[0].Cookedvalue 
            $OWA = (Get-Counter "\MSExchange OWA\Current Unique Users"   -ComputerName $Computer).CounterSamples[0].Cookedvalue
            $EAS = [math]::Truncate((Get-Counter "\MSExchange ActiveSync\Requests/sec" -ComputerName $Computer).CounterSamples[0].Cookedvalue)


            $Row = New-Object PSObject
            $Row | Add-Member -MemberType noteproperty -Name "Computername" -Value $Computer
            $Row | Add-Member -MemberType noteproperty -Name "RPC" -Value $RPC
            $Row | Add-Member -MemberType noteproperty -Name "OWA" -Value $OWA
            $Row | Add-Member -MemberType noteproperty -Name "EAS" -Value $EAS

            $ExchangeConnections += $Row
        }
    } #PROCESS

    END { 
        $ExchangeConnections
    } #END

} #FUNCTION


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


function New-SCCMSession {
    <#
        .SYNOPSIS
            Starts a PowerShell Session to SCCM and connects to the Site
        .DESCRIPTION
            Imports the PowerShell Module for SCCM, and then changes location to that Site Code
        .EXAMPLE
            New-SCCMSession
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 
      
        if (-Not (Test-Path -Path 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1')) {
            Write-Host 'SCCM Console is not Installed, or Module not found'
        }
        else {
            Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'

            $SCCMSiteCode = (Get-PSDrive | Where-Object { $_.Provider.Name -eq 'CMSite' }).Name
            $Location = $SCCMSiteCode + ':'
        }


    } #BEGIN

    PROCESS {
        if (Test-Path -Path 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1') {
            Set-Location $Location
        }

    } #PROCESS

    END { 

    } #END

} #FUNCTION

function Invoke-AsSystem {
    <#
        .SYNOPSIS
            Runs a Program as NT Authority System
        .DESCRIPTION
            Uses a copy of PSExec to launch the specified Program as System
        .PARAMETER PSExecPath
            Path to psexec/psexec64
        .PARAMETER Program
            Program to run as System
        .EXAMPLE
            Invoke-AsSystem -PSExecPath "\\FILESERVER\PsExec64.exe" -Program powershell.exe
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$PSExecPath,
        [Parameter(Mandatory = $true)][string]$Program
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        Start-Process -FilePath cmd.exe -Verb Runas -ArgumentList "/k $PSExecPath -i -s $Program"
    } #PROCESS

    END { 

    } #END

} #FUNCTION

function Invoke-APCConfigBackup {
    <#
        .SYNOPSIS
            Backs up APC config files with the corresponding APC Name
        .DESCRIPTION
            Downloads Config file from APC/APC's specified
        .PARAMETER APCS
            APC's to Backup the Config from
        .PARAMETER Username
            APC Username to login via FTP
        .PARAMETER Password
            APC Password to login via FTP
        .PARAMETER BackupDir
            Backup Directory where the Configs will be stored
        .EXAMPLE
            Invoke-APCConfig -APCS '<APC IP's/NAME's>' -Username 'APC Username' -Password 'APC Password' -BackupDir 'Directory to store INI Files'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$APCS,
        [Parameter(Mandatory = $true)]$Username,
        [Parameter(Mandatory = $true)]$Password,
        [Parameter(Mandatory = $true)]$BackupDir
    ) 
    BEGIN { 
        $PWDir = Get-Location

        Set-Location $BackupDir

        $DownloadConfig = @"
$Username
$Password
get config.ini
bye
"@
    } #BEGIN

    PROCESS {
        $DownloadConfig | out-file FTPCommand.txt

        foreach ($APC in $APCS) {
            ftp -s:FTPCommand.txt $APC
            Rename-Item config.ini "$APC.ini"
            Move-Item "$APC.ini" -Destination $BackupDir
        }

        Remove-Item FTPCommand.txt

        Set-Location $PWDir
    } #PROCESS

    END { 

    } #END

} #FUNCTION

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

function Set-APCConfig {
    <#
        .SYNOPSIS
            Applies a Config to an APC or group of APC's
        .DESCRIPTION
            Applies either a Config or CSF File to multiple or singular APC's
        .PARAMETER APCS
            APC's to apply to
        .PARAMETER Username
            APC Username to login via FTP
        .PARAMETER Password
            APC Password to login via FTP
        .PARAMETER SettingsFile
            INI/CSF File to Apply
        .EXAMPLE
            Set-APCConfig -APCS '<APC IP's/NAME's>' -Username 'APC Username' -Password 'APC Password' -SettingsFile 'Path to INI/CSF File'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$APCS,
        [Parameter(Mandatory = $true)]$Username,
        [Parameter(Mandatory = $true)]$Password,
        [Parameter(Mandatory = $true)]$SettingsFile
    ) 
    BEGIN { 
        $PWDir = Get-Location

        Set-Location c:\temp

        $UploadConfig = @"
$Username
$Password
put $SettingsFile
bye
"@

    } #BEGIN

    PROCESS {
        $UploadConfig | out-file FTPCommand.txt

        foreach ($APC in $APCS) {
            ftp -s:FTPCommand.txt $APC
        }

        Remove-Item FTPCommand.txt

        Set-Location $PWDir

    } #PROCESS

    END { 

    } #END

} #FUNCTION

function New-CertReq {
    <#
        .SYNOPSIS
            Gneerates a CSR using the specified information
        .DESCRIPTION
            Generates an INF/CSR with the Specified Certificate Information
        .PARAMETER CertFQDN
            FQDN of the Certificate needed
        .PARAMETER CustomerInfo
            Customer Information formatted as follows - "O = <COMPANYNAME>, STREET = <STREETADDRESS>, L = <CITY>, S = <STATE>, PostalCode = <ZIPCODE>, C = <COUNTRY>"
        .PARAMETER WorkingDir
            Directory to store the CSR/INF Files
        .EXAMPLE
            New-CertReq -CertFQDN Test.TestCompany.com -CustomerInfo "O = COMPANY, STREET = 123 Road, L = FakeTown, S = Texas, PostalCode = 12345, C = US" -WorkingDir 'c:\Temp'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$CertFQDN,
        [Parameter(Mandatory = $true)]$CustomerInfo,
        [Parameter(Mandatory = $true)]$WorkingDir
    ) 
    BEGIN { 

        $WorkingDir = $WorkingDir.Trimend('\')
        $WorkingDir = $WorkingDir + '\'

        $CSRPath = $WorkingDir + "$($CertFQDN)_.csr"
        $INFPath = $WorkingDir + "$($CertFQDN)_.inf"

        $Signature = '$Windows NT$' 


        $INF =
        @"
[Version]
Signature= "$Signature" 

[NewRequest]
Subject = "CN=$CertFQDN, $CustomerInfo"
KeySpec = 1
KeyLength = 4096
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0

[Strings]
szOID_SUBJECT_ALT_NAME2 = "2.5.29.17"
szOID_ENHANCED_KEY_USAGE = "2.5.29.37"
szOID_PKIX_KP_SERVER_AUTH = "1.3.6.1.5.5.7.3.1"
szOID_PKIX_KP_CLIENT_AUTH = "1.3.6.1.5.5.7.3.2"

[Extensions]
%szOID_SUBJECT_ALT_NAME2% = "{text}dns=$CertFQDN"
%szOID_ENHANCED_KEY_USAGE% = "{text}%szOID_PKIX_KP_SERVER_AUTH%,%szOID_PKIX_KP_CLIENT_AUTH%"

[EnhancedKeyUsageExtension]

OID=1.3.6.1.5.5.7.3.1 
"@
    } #BEGIN

    PROCESS {
        $INF | Out-File -filepath $INFPath -force
        certreq -new $INFPath $CSRPath
    } #PROCESS

    END { 

    } #END

} #FUNCTION


function Get-RSATInstallStatus {
    <#
        .SYNOPSIS
            Gets RSAT Installation Status for current PC
        .DESCRIPTION
            Checks Windows Capabilities and lists RSAT Install Status
        .EXAMPLE
            Get-RSATInstallStatus
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        $RSATStatus = Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State
    } #PROCESS

    END { 
        $RSATStatus
    } #END

} #FUNCTION

function Invoke-RSATInstallation {
    <#
        .SYNOPSIS
            Installs all RSAT Tools on Current PC
        .DESCRIPTION
            Queries all RSAT Tools available and Installs them. Requires internet Access
        .EXAMPLE
            Invoke-RSATInstallation
    #>
    [CmdletBinding()]
    Param(
        
    ) 
    BEGIN { 

    } #BEGIN

    PROCESS {
        Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
    } #PROCESS

    END { 

    } #END

} #FUNCTION

function Invoke-FedExURSAUpdate {
    #Requires -Modules PSFTP
    <#
        .SYNOPSIS
            Downloads FedEx Ursav Update and places it in specified location
        .DESCRIPTION
            Uses the PSFTP Module to download the Fedex Ursa Update
        .PARAMETER P1
            C
        .EXAMPLE
            Invoke-FedExURSAUpdate -UrsaLocalLocation C:\Temp
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$UrsaLocalLocation
    ) 
    BEGIN { 
        Import-Module PSFTP
        $FedExFTPCredential = [System.Management.Automation.PSCredential]::new("anonymous", [System.Security.SecureString]::new())
    } #BEGIN

    PROCESS {
        Set-FTPConnection -Server ftp://ftp.fedex.com -Session FedExUrsa -UsePassive -Credentials $FedExFTPCredential
        $Session = Get-FTPConnection -Session FedExUrsa 
        $URSAVFile = Get-FTPChildItem -Session $Session -Path /pub/ursa/URSAV5/ | Where-Object -FilterScript { $_.name -like 'ursav' }
        $URSAVFile | Get-FTPItem -Session $Session -LocalPath $UrsaLocalLocation
    } #PROCESS

    END { 

    } #END

} #FUNCTION

function Invoke-WSUSServerSynchronization {
    <#
        .SYNOPSIS
            Starts a WSUS Synchronization for Updates
        .DESCRIPTION
            Gets the WSUS Server and initiates a Synchronization against it
        .PARAMETER WSUSServer
            Server Name or FQDN Depending on how you have it configured
        .PARAMETER WSUSServerPort
            Optional - Only needed if Ports are not default
        .PARAMETER SSL
            True or False, Not needed, but will default to non SSL if not specified
        .EXAMPLE
            Invoke-WSUSServerSynchronization -WSUSServer WSUS01 -WSUSServerPort 8538 -SSL 'True'
        .EXAMPLE
            Invoke-WSUSServerSynchronization -WSUSServer WSUS01
        .EXAMPLE
            Invoke-WSUSServerSynchronization -WSUSServer WSUS01 -SSL 'True'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$WSUSServer,
        [Parameter()]$WSUSServerPort,
        [Parameter()]$SSL
    ) 
    BEGIN { 
        if ($SSL -eq 'True') {
            if ($NULL -eq $WSUSServerPort) {
                $WSUSServerPort = 8531
            }
            
            $WSUSServer = (Get-WsusServer -Name $WSUSServer -UseSsl -PortNumber $WSUSServerPort)
        }
        else {
            if ($NULL -eq $WSUSServerPort) {
                $WSUSServerPort = 8530
            }
            $WSUSServer = (Get-WsusServer -Name $WSUSServer -PortNumber $WSUSServerPort)
        }

    } #BEGIN

    PROCESS {
        $WSUSServer.GetSubscription().StartSynchronization()
    } #PROCESS

    END { 

    } #END

} #FUNCTION

function Get-WSUSServerSynchronization {
    <#
        .SYNOPSIS
            Gets last Synchronization
        .DESCRIPTION
            Queries WSUS Server for last Synchronization
        .PARAMETER WSUSServer
            Server Name or FQDN Depending on how you have it configured
        .PARAMETER WSUSServerPort
            Optional - Only needed if Ports are not default
        .PARAMETER SSL
            True or False, Not needed, but will default to non SSL if not specified
        .EXAMPLE
            Get-WSUSServerSynchronization -WSUSServer WSUS01 -WSUSServerPort 8538 -SSL 'True'
        .EXAMPLE
            Get-WSUSServerSynchronization -WSUSServer WSUS01
        .EXAMPLE
            Get-WSUSServerSynchronization -WSUSServer WSUS01 -SSL 'True'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$WSUSServer,
        [Parameter()]$WSUSServerPort,
        [Parameter()]$SSL
    ) 
    BEGIN { 
        if ($SSL -eq 'True') {
            if ($NULL -eq $WSUSServerPort) {
                $WSUSServerPort = 8531
            }
            
            $WSUSServer = (Get-WsusServer -Name $WSUSServer -UseSsl -PortNumber $WSUSServerPort)
        }
        else {
            if ($NULL -eq $WSUSServerPort) {
                $WSUSServerPort = 8530
            }
            $WSUSServer = (Get-WsusServer -Name $WSUSServer -PortNumber $WSUSServerPort)
        }
    } #BEGIN

    PROCESS {
        $WSUSServer.GetSubscription().GetLastSynchronizationInfo()
    } #PROCESS

    END { 

    } #END

} #FUNCTION