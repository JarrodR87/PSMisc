function Invoke-CollectLocalOfficeUpdates {
    <#
          .SYNOPSIS
              Collects Office Updates from the local PC
          .DESCRIPTION
              Collects Office Updates currently applied on the local PC
          .PARAMETER Path
              Path to store the collected Updates
          .EXAMPLE
              Invoke-CollectLocalOfficeUpdates -Path 'C:\Users\USER\Downloads\Updates\'
      #>
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $true)]$Path
    )
    BEGIN {
          
      $Path = $Path.Trimend('\')
      $Path = $Path + '\'
  
      $msi = new-object -comobject windowsinstaller.installer
      $msi.patchesex('', '', 4, 1) | ForEach-Object {
        $pkg = $_.patchproperty('LocalPackage')
        $msp = $msi.opendatabase($pkg, 32)
        if ($msi.summaryinformation($pkg).property(7) -match '000-0000000ff1ce}') {
          try { $view = $msp.openview("SELECT `Property`,`Value` FROM MsiPatchMetadata WHERE `Property`='StdPackageName'") } catch { return }
          $view.execute()
          $record = $view.fetch()
          copy-item $pkg ("{0}\{1}" -f $Path, $record.stringdata(2)) -force
        }
      }
  
    } #BEGIN
