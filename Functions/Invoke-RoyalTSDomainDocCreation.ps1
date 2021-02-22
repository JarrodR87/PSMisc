function Invoke-RoyalTSDomainDocCreation {
    <#
        .SYNOPSIS
            Creates a RoyalTS Document from a specified Domain with all Domain Servers
        .DESCRIPTION
            Queries a Domain for all Windows Servers, and uses their OU's to create a RoyalTS Document Structure for hthat Domain
        .PARAMETER Domain
            Domain to run the document creation against
        .PARAMETER Path
            Path to save the file to
        .EXAMPLE
            Invoke-RoyalTSDomainDocCreation
        .EXAMPLE
            Invoke-RoyalTSDomainDocCreation -Domain contoso.com -Path C:\Temp\
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]$Domain,
        [Parameter()]$Path
    ) 
    BEGIN { 
        if ($NULL -eq $Domain) {
            $Domain = ((Get-ADDomain).DNSRoot).ToUpper()
        }
        else {
            $Domain = $Domain.ToUpper()
        }
        
        $Path = $Path.Trimend('\')
        $Path = $Path + '\'

        Import-Module  RoyalDocument.PowerShell
        $FileName = $Path + $Domain + '.rtsz'
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