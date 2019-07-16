; Package an application (e.g. AeroZoom) in 7-Zip SFX, self-extracting archive (FYI: the AeroZoom download already comes with an SFX)
; Place it in the location specified below, e.g. C:\az-autohotkey-silent-setup\AeroZoom_7-Zip_SFX.exe
FileInstall, C:\az-autohotkey-silent-setup\AeroZoom_7-Zip_SFX.exe, %A_ScriptDir%\AeroZoom_7-Zip_SFX.exe, 1

; Silently extract AeroZoom from the SFX file into the current directory
RunWait, %A_ScriptDir%\AeroZoom_7-Zip_SFX.exe -o"%A_ScriptDir%" -y

; Run silent setup command: Setup.exe /programfiles /unattendaz=1
; For AeroZoom, this command will install AeroZoom to All Users (/programfiles) and silently (/unattendedaz=1)
; as well as uninstalling in case an AeroZoom copy is found in the target location (built into the logic of Setup.exe of AeroZoom)
RunWait, %A_ScriptDir%\AeroZoom\Setup.exe /programfiles /unattendaz=1
