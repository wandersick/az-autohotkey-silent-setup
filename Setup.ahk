; (c) Copyright 2009-2019 AeroZoom by wandersick | https://tech.wandersick.com

; Return Codes:
;
; 0: Successful [un]installation
; 1: User cancelled
; 2: Installation failed
; 3: AeroZoom is running and cannot be terminated. Uninstallation cancelled
; 4: Component check failed
; 5: Show help message

; Parameters:
;
; /programfiles
;     for installing into `C:\Program Files (x86)` (or `C:\Program Files` for 32-bit OS) instead of current user profile
;
; /unattendAZ=1
;     for an unattended installation
;     If it detects AeroZoom is already installed, the setup will perform an uninstallation instead
;
; /unattendAZ=2 or any other values
;     an uninstallation dialog box will also be prompted

#SingleInstance Force
#NoTrayIcon

verAZ = 5.0
	
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Missing component check
IfNotExist, %A_WorkingDir%\Data
{
	Msgbox, 262192, AeroZoom, Missing essential components.`n`nPlease download the legitimate version from tech.wandersick.com.
	ExitApp, 4
}

targetDir=%localappdata%
If %1% {
	Loop, %0%  ; For each parameter
	{
		param := %A_Index%  ; Retrieve A_Index variable contents
		If (param="/unattendAZ=1")
			unattendAZ=1
		Else if (param="/unattendAZ=2")
			unattendAZ=2
		Else if (param="/programfiles")
		{
			targetDir=%programfiles%
			setupAllUsers=1
		}
		Else
		{
			Msgbox, 262192, AeroZoom Setup, Supported parameters:`n`n - Unattended setup : /unattendAZ=1`n - Install for all users : /programfiles`n`nFor example: Setup.exe /programfiles /unattendaz=1`n`nNote:`n - If setup finds a copy in the target location, uninstallation will be carried out instead.`n - If you install into Program Files folder, be sure you're running it with administrator rights.
			ExitApp, 5
		}
	}
}

; Check path to AeroZoom_Task.bat
IfExist, %A_WorkingDir%\AeroZoom_Task.bat
	TaskPath=%A_WorkingDir%
IfExist, %A_WorkingDir%\Data\AeroZoom_Task.bat
	TaskPath=%A_WorkingDir%\Data

; Install / Uninstall
regKey=SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AeroZoom
IfNotExist, %targetDir%\wandersick\AeroZoom\AeroZoom.exe
{
	IfNotEqual, unattendAZ, 1
	{
		MsgBox, 262180, AeroZoom Installer , Install AeroZoom in the following location?`n`n%targetDir%\wandersick\AeroZoom`n`nNote:`n - For portable use, just run AeroZoom.exe. Setup is unneeded.`n - To install silently or to all users, run Setup.exe /? to see how.`n - To remove a copy that was installed to all users, run Setup.exe /programfiles
		IfMsgBox No
		{
			ExitApp, 1
		}
	}
	; Terminate running AeroZoom executables
	Gosub, KillProcess
	; Remove existing directory
	FileRemoveDir, %targetDir%\wandersick\AeroZoom\Data, 1
	FileRemoveDir, %targetDir%\wandersick\AeroZoom, 1
	; Copy AeroZoom to %targetDir%
	FileCreateDir, %targetDir%\wandersick\AeroZoom
	FileCopyDir, %A_WorkingDir%, %targetDir%\wandersick\AeroZoom, 1
	; For running 'AeroZoom' in Run prompt
	if A_IsAdmin ; unnecessary
	{
		; Limitation: Run prompt does not have a current-user way, so both types of installation (current-user/all-users) would write to the same registry area
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\AeroZoom.exe,, %targetDir%\wandersick\AeroZoom\AeroZoom.exe
	}

	; For setting system-wide PATH environmental variable so that 'AeroZoom' can be run in Command Prompt or PowerShell
	if setupAllUsers
	{
		; EnvGet, envVarPath, Path
		RegRead, envVarPath, HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment, Path
		envVarPathNew = %envVarPath%;%targetDir%\wandersick\AeroZoom\
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment, Path, %envVarPathNew%
		Sleep, 1000
		; Broadcast WM_SETTINGCHANGE message for the updated PATH to take effect
		EnvUpdate
	} else {
		; EnvGet, envVarPath, Path
		RegRead, envVarPath, HKEY_CURRENT_USER\Environment, Path
		envVarPathNew = %envVarPath%;%targetDir%\wandersick\AeroZoom\
		RegWrite, REG_SZ, HKEY_CURRENT_USER\Environment, Path, %envVarPathNew%
		Sleep, 1000
		; Broadcast WM_SETTINGCHANGE message for the updated PATH to take effect
		EnvUpdate
	}

	IfExist, %targetDir%\wandersick\AeroZoom\AeroZoom.exe
	{
		; Create shortcut to Start Menu (All Users)
		If setupAllUsers
		{
			FileCreateShortcut, %targetDir%\wandersick\AeroZoom\AeroZoom.exe, %A_ProgramsCommon%\AeroZoom.lnk, %targetDir%\wandersick\AeroZoom\,, AeroZoom`, the smooth wheel-zooming and snipping mouse-enhancing panel,,
			FileCreateShortcut, %targetDir%\wandersick\AeroZoom\AeroZoom.exe, %A_DesktopCommon%\AeroZoom.lnk, %targetDir%\wandersick\AeroZoom\,, AeroZoom`, the smooth wheel-zooming and snipping mouse-enhancing panel,,
		}
		; Create shortcut to Start Menu (Current User)
		Else
		{
			FileCreateShortcut, %targetDir%\wandersick\AeroZoom\AeroZoom.exe, %A_Programs%\AeroZoom.lnk, %targetDir%\wandersick\AeroZoom\,, AeroZoom`, the smooth wheel-zooming and snipping mouse-enhancing panel,,
			FileCreateShortcut, %targetDir%\wandersick\AeroZoom\AeroZoom.exe, %A_Desktop%\AeroZoom.lnk, %targetDir%\wandersick\AeroZoom\,, AeroZoom`, the smooth wheel-zooming and snipping mouse-enhancing panel,,
		}
	}
	; if a shortcut is in startup, re-create it to ensure its not linked to the portable version's path
	IfExist, %A_Startup%\*AeroZoom*.*
	{
		FileSetAttrib, -R, %A_Startup%\*AeroZoom*.*
		FileDelete, %A_Startup%\*AeroZoom*.*
	}
	if A_IsAdmin
	{
		IfExist, %A_StartupCommon%\*AeroZoom*.* ; this is unnecessary as AeroZoom wont put shortcuts in all users startup but it will be checked too 
		{
			FileSetAttrib, -R, %A_StartupCommon%\*AeroZoom*.*
			FileDelete, %A_StartupCommon%\*AeroZoom*.*
		}
	}
	if A_IsAdmin
	{
		RunWait, "%TaskPath%\AeroZoom_Task.bat" /check,"%A_WorkingDir%\",min
		if (errorlevel=4) { ; if task exists, recreate it to ensure it links to the correct aerozoom.exe
			if setupAllUsers
			{
				RunWait, "%TaskPath%\AeroZoom_Task.bat" /cretask /programfiles,"%A_WorkingDir%\",min
			} else {
				RunWait, "%TaskPath%\AeroZoom_Task.bat" /cretask /localappdata,"%A_WorkingDir%\",min
			}
			if (errorlevel=3) {
				RegWrite, REG_SZ, HKCU, Software\wandersick\AeroZoom, RunOnStartup, 1
			}
		}
	}
	; Write uninstallation entries to registry 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayIcon, %targetDir%\wandersick\AeroZoom\AeroZoom.exe,0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayName, AeroZoom %verAZ%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, InstallDate, %A_YYYY%%A_MM%%A_DD%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, HelpLink, https://tech.wandersick.com
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, URLInfoAbout, https://tech.wandersick.com
	
	; ******************************************************************************************
	
	If setupAllUsers ; if AeroZoom was installed for all users
		RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, UninstallString, %targetDir%\wandersick\AeroZoom\setup.exe /unattendAZ=2 /programfiles
	Else ; if AeroZoom was installed for current user
		RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, UninstallString, %targetDir%\wandersick\AeroZoom\setup.exe /unattendAZ=2
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, InstallLocation, %targetDir%\wandersick\AeroZoom
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayVersion, %verAZ%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, Publisher, a wandersick
	
	; Calculate folder size
	EstimatedSize = 0
	Loop, %targetDir%\wandersick\AeroZoom\*.*, , 1
	EstimatedSize += %A_LoopFileSize%
	EstimatedSize /= 1024
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, %regKey%, EstimatedSize, %EstimatedSize%
	IfExist, %targetDir%\wandersick\AeroZoom\AeroZoom.exe
	{
		IfEqual, unattendAZ, 1
		{
			ExitApp, 0
		}	
		Msgbox, 262144, AeroZoom, Successfully installed.`n`nAccess the uninstaller in 'Control Panel\Programs and Features' or run Setup.exe again. ; 262144 = Always on top
	} else {
		IfEqual, unattendAZ, 1
		{
			ExitApp, 2
		}
		Msgbox, 262192, AeroZoom, Installation failed.`n`nPlease ensure this folder is accessible:`n`n%targetDir%\wandersick\AeroZoom
	}
} else {
	; if unattend switch is on, skip the check since user must be running the uninstaller from control panel
	; not from AeroZoom program
	IfNotEqual, unattendAZ, 1
	{
		MsgBox, 262180, AeroZoom Uninstaller , Uninstall AeroZoom and delete its perferences from the following location?`n`n%targetDir%\wandersick\AeroZoom
		IfMsgBox No
		{
			ExitApp, 1
		}
	}
	; Terminate running AeroZoom executables
	Gosub, KillProcess
	Process, Exist, AeroZoom_Alt.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_Alt_x64.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_Ctrl.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_Ctrl_x64.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseL.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseL_x64.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseM.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseM_x64.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseR.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseR_x64.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseX1.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseX1_x64.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseX2.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_MouseX2_x64.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_Shift.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_Shift_x64.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_Win.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	Process, Exist, AeroZoom_Win_x64.exe ; Check if a copy is running
	if errorlevel
		ExistAZ=1
	If (ExistAZ=1)
	{
		IfNotEqual, unattendAZ, 1
		{
			Msgbox, 262208, AeroZoom is currently running, Please exit AeroZoom before uninstall
		}
		ExitApp, 3
	}
	; Begin uninstalling
	; Remove startup shortcuts
	IfExist, %A_Startup%\*AeroZoom*.*
	{
		FileSetAttrib, -R, %A_Startup%\*AeroZoom*.*
		FileDelete, %A_Startup%\*AeroZoom*.*
	}
	if A_IsAdmin ; Unnecessary as stated above
	{
		IfExist, %A_StartupCommon%\*AeroZoom*.*
		{
			FileSetAttrib, -R, %A_StartupCommon%\*AeroZoom*.*
			FileDelete, %A_StartupCommon%\*AeroZoom*.*
		}
	}
	; Remove task
	if A_IsAdmin
	{
		RunWait, "%TaskPath%\AeroZoom_Task.bat" /deltask,"%A_WorkingDir%\",min
		RunWait, "%TaskPath%\AeroZoom_Task.bat" /check,"%A_WorkingDir%\",min
		if (errorlevel=5) {
			RegWrite, REG_SZ, HKCU, Software\wandersick\AeroZoom, RunOnStartup, 0
		}
	}

	; Remove registry keys
	RegDelete, HKEY_CURRENT_USER, %regKey%
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom

	; For removing the ability to run 'AeroZoom' in Run prompt
	if A_IsAdmin
	{
		RegDelete, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\AeroZoom.exe
	}

	; For removing 'AeroZoom' from environmental variable including a semicolon
	if setupAllUsers
	{
		targetDirToRemove1=;%targetDir%\wandersick\AeroZoom\
		targetDirToRemove2=;%targetDir%\wandersick\AeroZoom
		; In case this is at the top of the PATH list
		targetDirToRemove3=%targetDir%\wandersick\AeroZoom\;
		targetDirToRemove4=%targetDir%\wandersick\AeroZoom;
		; EnvGet, envVarPath, Path
		RegRead, envVarPath, HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment, Path
		envVarPathNewTemp1 := StrReplace(envVarPath, targetDirToRemove1)
		envVarPathNewTemp2 := StrReplace(envVarPathNewTemp1, targetDirToRemove2)
		envVarPathNewTemp3 := StrReplace(envVarPathNewTemp2, targetDirToRemove3)
		envVarPathNew := StrReplace(envVarPathNewTemp3, targetDirToRemove4)
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment, Path, %envVarPathNew%
		Sleep, 1000
		; Broadcast WM_SETTINGCHANGE message for the updated PATH to take effect
		EnvUpdate
	} else {
		targetDirToRemove1=;%targetDir%\wandersick\AeroZoom\
		targetDirToRemove2=;%targetDir%\wandersick\AeroZoom
		; In case this is at the top of the PATH list
		targetDirToRemove3=%targetDir%\wandersick\AeroZoom\;
		targetDirToRemove4=%targetDir%\wandersick\AeroZoom;
		; EnvGet, envVarPath, Path
		RegRead, envVarPath, HKEY_CURRENT_USER\Environment, Path
		envVarPathNewTemp1 := StrReplace(envVarPath, targetDirToRemove1)
		envVarPathNewTemp2 := StrReplace(envVarPathNewTemp1, targetDirToRemove2)
		envVarPathNewTemp3 := StrReplace(envVarPathNewTemp2, targetDirToRemove3)
		envVarPathNew := StrReplace(envVarPathNewTemp3, targetDirToRemove4)
		RegWrite, REG_SZ, HKEY_CURRENT_USER\Environment, Path, %envVarPathNew%
		Sleep, 1000
		; Broadcast WM_SETTINGCHANGE message for the updated PATH to take effect
		EnvUpdate
	}

	;FileMove, %targetDir%\wandersick\AeroZoom\Data\uninstall.bat, %temp%, 1 ; prevent deletion of this as it will be used
	FileSetAttrib, -R, %A_Programs%\AeroZoom.lnk 
	FileDelete, %A_Programs%\AeroZoom.lnk ; normally this is the only shortcut that has to be deleted
	FileSetAttrib, -R, %A_ProgramsCommon%\AeroZoom.lnk
	FileDelete, %A_ProgramsCommon%\AeroZoom.lnk
	FileSetAttrib, -R, %A_Desktop%\AeroZoom.lnk
	FileDelete, %A_Desktop%\AeroZoom.lnk
	FileSetAttrib, -R, %A_DesktopCommon%\AeroZoom.lnk
	FileDelete, %A_DesktopCommon%\AeroZoom.lnk
	FileSetAttrib, -R, %targetDir%\wandersick\AeroZoom\*.*
	FileRemoveDir, %targetDir%\wandersick\AeroZoom\Data, 1
	FileRemoveDir, %targetDir%\wandersick\AeroZoom, 1

	IfNotEqual, unattendAZ, 1
	{
		Msgbox, 262144, AeroZoom, Successfully uninstalled`n`nSetup will now delete itself in 3 seconds,3
	}
	; Remove directory content including Setup.exe that is currently running after 3 seconds using ping in a minimized Command Prompt
	Run, cmd /c start /min ping 127.0.0.1 -n 3 >nul & rd /s /q "%targetDir%\wandersick"
}

ExitApp, 0
return

KillProcess: ; may not work for RunAsInvoker for Administrators accounts with UAC on. RunAsHighest will solve that, while letting Standard user accounts install to the correct profile.
Process, Close, magnify.exe
Process, Close, zoomit.exe
Process, Close, zoomit64.exe
Process, Close, wget.exe
Process, Close, AeroZoom.exe
Process, Close, AeroZoom_Alt.exe
Process, Close, AeroZoom_Ctrl.exe
Process, Close, AeroZoom_MouseL.exe
Process, Close, AeroZoom_MouseM.exe
Process, Close, AeroZoom_MouseR.exe
Process, Close, AeroZoom_MouseX1.exe
Process, Close, AeroZoom_MouseX2.exe
Process, Close, AeroZoom_Shift.exe
Process, Close, AeroZoom_Win.exe
Process, Close, AeroZoom_Alt_x64.exe
Process, Close, AeroZoom_Ctrl_x64.exe
Process, Close, AeroZoom_MouseL_x64.exe
Process, Close, AeroZoom_MouseM_x64.exe
Process, Close, AeroZoom_MouseR_x64.exe
Process, Close, AeroZoom_MouseX1_x64.exe
Process, Close, AeroZoom_MouseX2_x64.exe
Process, Close, AeroZoom_Shift_x64.exe
Process, Close, AeroZoom_Win_x64.exe
Process, Close, ZoomPad.exe
Process, Close, SmartClickDisabler_MouseL.exe
Process, Close, SmartClickDisabler_MouseR.exe
Process, Close, SmartClickDisabler_MouseX1.exe
Process, Close, SmartClickDisabler_MouseX2.exe
return

