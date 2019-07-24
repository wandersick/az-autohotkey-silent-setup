
$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileLocation = Join-Path $toolsDir 'Setup.exe'
$url        = 'https://github.com/wandersick/aerozoom/releases/download/4.0.2/AeroZoom_v4.0.0.7_beta_2_silent_installer.exe'

$packageArgs = @{
  packageName   = 'AeroZoom'
  unzipLocation = $toolsDir
  fileType      = 'exe'
  url           = $url
  file          = $fileLocation

  softwareName  = 'AeroZoom*'

  checksum      = 'a587d1d5d934b34ef5cafdb58e22256d'
  checksumType  = 'md5'

  silentArgs    = "/programfiles /unattendaz=1"
  validExitCodes= @(0)
}

Install-ChocolateyPackage @packageArgs










    








