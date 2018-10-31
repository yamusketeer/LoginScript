function vhdxAttachDetach([string]$mntPath) 
{
  #$arrPath=@(get-childitem $mntPath -recurse | where {$_.extension -eq ".vhdx"} | % { $_.FullName })
  $arrPath=@(Try { get-childitem $mntPath -ErrorAction SilentlyContinue  -recurse | where {$_.extension -eq ".vhdx"} | % { $_.FullName } `
                 } Catch [System.Exception] {  write-host "No vhdx found."   }) 

  for ($i=0; $i -lt $arrPath.Length; $i++) 
  {
    if ((Test-Path $arrPath[$i]) -eq $true) 
    {
      if ((Get-DiskImage -ImagePath $arrPath[$i] -StorageType VHDX).Attached -eq $false)
      {
        "Mount... " + $arrPath[$i]
        Mount-DiskImage -PassThru -ImagePath $arrPath[$i] -StorageType VHDX 
      }
      else
      {
        "Dismount... " + $arrPath[$i]
        Dismount-DiskImage -PassThru -ImagePath $arrPath[$i]
      }
    }
    else 
    {
      "Skipped... " + $arrPath[$i]
    }
  }
}


function vhdxUnlock()
{
  $arrMount = @(Get-Partition | Where-object { (((Get-Disk $_.DiskNumber).Model.trim() -like "Virtual Disk") -and 
                                                ($_.NoDefaultDriveLetter -eq $false) -and 
                                                ($_.Type -like "Basic")) } | `
                                %{ New-Object PSObject -Property @{ #'DiskModel' = (Get-Disk $_.DiskNumber).Model; `
                                                                    #'PartitionSize' = $_.Size; `
                                                                    #'IsHidden' = $_.IsHidden; `
                                                                    'DriveLetter' = $_.DriveLetter+":" } })
  #$arrMount
  if ($arrMount.Length -gt 0) 
  {
    #[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
    #$SecureString = ConvertTo-SecureString "abcd1234" -AsPlainText -Force
    $pass = Read-Host 'Please enter password: ' -AsSecureString
  }
  for ($i=0; $i -lt $arrMount.Length; $i++) 
  {
    "Unlock... " + $arrMount[$i].DriveLetter
    Unlock-BitLocker -MountPoint $arrMount[$i].DriveLetter -Password $pass
  }
}

$mntPath = "C:\Share\mount\"
vhdxAttachDetach $mntPath
vhdxUnlock
