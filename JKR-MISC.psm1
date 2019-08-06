

<#
DESCRIPTION:
Gets list of commands available in a specified PowerShell Snapin
#>
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
        
        Import-Module "${env:ProgramFiles(x86)}\Royal TS V5\RoyalDocument.PowerShell.dll"
        
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