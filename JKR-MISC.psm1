

<#
DESCRIPTION:
Gets list of commands available in a specified PowerShell Snapin
#>
function Get-PSSnapinCommand {
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
            Set-Acl $Path $HomeAcl
        }
    } #PROCESS

    END { 

    } #END

} #FUNCTION