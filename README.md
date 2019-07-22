# How-to: Create a Silent Installer with AutoHotkey and Publish it on Chocolatey

Supposed there is a portable Windows application without an installer and uninstaller, how to create them back? In today's post, we will explore one way to build a `Setup.exe` using AutoHotkey (AHK), with additional compression of 7-Zip applied to the `Setup.exe` and remaining files of the portable application for maximum compression, and then wrap it with an outer unattended installer, which is suitable for certain deployments.

The application example, i.e. the application for which a setup is created is [AeroZoom](https://gallery.technet.microsoft.com/AeroZoom-The-smooth-wheel-e0cdf778). While some terminologies are specific to AeroZoom, the general concepts should apply to other software.

- `AeroZoom_Unattended_Installer.exe` will be the outer unattended installer we will create which contains 7-Zip SFX `AeroZoom_7-Zip_SFX.exe` and is responsible for extraction as well as calling an inner `Setup.exe` to install AeroZoom for all users silently

```c
AeroZoom_Unattended_Installer.exe // ⭐1️⃣ to be built (goal - outer unattended installer written in AHK)
    │
    └───AeroZoom_7-Zip_SFX.exe  // 2️⃣ to be built (self-extracting archive created by 7-Zip with ultra compression)
          │
          ├───AeroZoom // portable application example
          |      AeroZoom.exe
          │      Setup.exe // ⭐3️⃣ to be built (goal - inner setup written in AHK)
          │
          └───Data
```

After creating `AeroZoom_Unattended_Installer.exe`, we will take a detour to briefly go through how to push this unattended installer to the community repository of [Chocolatey](https://chocolatey.org), the package manager for Windows, before going back to detailing how to create the inner `Setup.exe`.

Let's go and create all those exe files above!

## Some Trivia of AeroZoom (before We Begin)

> Scripted in AHK, [AeroZoom](https://gallery.technet.microsoft.com/AeroZoom-The-smooth-wheel-e0cdf778) enhances upon Windows Magnifier and optionally Sysinternals ZoomIt to enable screen magnification by mouse-wheeling, as well as turning any mouse into a Home-Theater PC/presentation mouse, where zooming and positioning becomes a breeze without a keyboard

Originally, AeroZoom was built as a portable application. Its `Setup.exe` was introduced in a later version, `v2.0`, and the unattended setup `AeroZoom_Unattended_Installer.exe` was first built for `v4.0`, available for [download here](https://github.com/wandersick/aerozoom-doc/releases).

## Step-by-Step Instructions

1. Download or `git clone` [this repository](https://github.com/wandersick/az-autohotkey-silent-setup) to a desired directory e.g. `c:\az-autohotkey-silent-setup`

   ```c
   C:\az-autohotkey-silent-setup
   │   AeroZoom_Unattended_Installer.ahk      // AutoHotkey source code of the outer unattended installer to be customized
   │   AeroZoom_Unattended_Installer.ahk.ini  // optional: for use with an alternative compiler, Compile_AHK II, discussed later
   │   ...
   ```

2. Download [AeroZoom](https://gallery.technet.microsoft.com/AeroZoom-The-smooth-wheel-e0cdf778) and extract it to a desired directory, e.g. `C:\AeroZoom`

   ```c
   C:\AeroZoom
   │   AeroZoom.exe
   │   Readme.txt
   │
   └───Data
   ```

3. Build an inner `Setup.exe` using AutoHotkey following [these instructions in the same article](#Building-and-Obtaining-Inner-Setupexe-using-AutoHotkey) or acquire it by extracting it from the [downloaded AeroZoom SFX file](https://gallery.technet.microsoft.com/AeroZoom-The-smooth-wheel-e0cdf778)

4. Place the `Setup.exe` next to AeroZoom

   ```c
   C:\AeroZoom
   │   AeroZoom.exe
   │   Readme.txt
   │   Setup.exe   // place the Setup.exe built here (replace existing one, if any)
   │
   └───Data
   ```

5. Package (compress) the above `C:\AeroZoom` application in a [7-Zip SFX (self-extracting archive)](https://www.wikihow.com/Use-7Zip-to-Create-Self-Extracting-excutables)

   - If you acquired AeroZoom via official means, this step can be skipped as it already comes with an SFX `AeroZoom_v4.0.0.7_beta_2.exe` after extraction. Simply rename it as `AeroZoom_7-Zip_SFX.exe`

6. Put the SFX file there and rename it as `AeroZoom_7-Zip_SFX.exe`

   ```c
   C:\az-autohotkey-silent-setup
   |   AeroZoom_7-Zip_SFX.exe                  // place SFX (containing C:\AeroZoom) built using 7-Zip here
   │   AeroZoom_Unattended_Installer.ahk
   │   AeroZoom_Unattended_Installer.ahk.ini
   │   README.md
   |   ...
   ```

7. Place an icon named `AeroZoom_Setup.ico` there (optional)

   ```c
   C:\az-autohotkey-silent-setup
   |   AeroZoom_7-Zip_SFX.exe
   │   AeroZoom_Setup.ico                      // icon is optional
   │   AeroZoom_Unattended_Installer.ahk
   │   AeroZoom_Unattended_Installer.ahk.ini
   │   README.md
   |   ...
   ```

8. Edit `AeroZoom_Unattended_Installer.ahk` and change below `C:\az-autohotkey-silent-setup\AeroZoom_7-Zip_SFX.exe` to a desired location (no change if directory is the same as the example)

   ```ahk
   ; Package an application (e.g. AeroZoom) in 7-Zip SFX, self-extracting archive (FYI: the AeroZoom download already comes with an SFX)
   ; Place it in the location specified below, e.g. C:\az-autohotkey-silent-setup\AeroZoom_7-Zip_SFX.exe
   FileInstall, C:\az-autohotkey-silent-setup\AeroZoom_7-Zip_SFX.exe, %A_ScriptDir%\AeroZoom_7-Zip_SFX.exe, 1

   ; Silently extract AeroZoom from the SFX file into the current directory
   RunWait, %A_ScriptDir%\AeroZoom_7-Zip_SFX.exe -o"%A_ScriptDir%" -y

   ; Run silent setup command: Setup.exe /programfiles /unattendaz=1
   ; For AeroZoom, this command will install AeroZoom to All Users (/programfiles) and silently (/unattendedaz=1)
   ; as well as uninstalling in case an AeroZoom copy is found in the target location (built into the logic of Setup.exe of AeroZoom)
   RunWait, %A_ScriptDir%\AeroZoom\Setup.exe /programfiles /unattendaz=1
   ```

9. [Download and install AutoHotKey](https://autohotkey.com)

10. While under repository directory (e.g. `C:\az-autohotkey-silent-setup`), compile `AeroZoom_Unattended_Installer.ahk` using the bundled AHk2Exe utility, usually located under `C:\Program Files\AutoHotkey\Compiler` as so:

    - `"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "AeroZoom_Unattended_Installer.ahk" /icon "AeroZoom_Setup.ico"`
      - Icon parameter is optional: `/icon "AeroZoom_Setup.ico"`
    - Alternatively, to compile with the alternative compiler, download and install [Compile_AHK II](https://www.autohotkey.com/board/topic/21189-compile-ahk-ii-for-those-who-compile/), then right-click `AeroZoom_Unattended_Installer.ahk` and select _Compile with Options_ which would parse parameters from `AeroZoom_Unattended_Installer.ahk.ini`
      - While Compile_AHK II comes with compression feature, this post uses 7-Zip as 7-Zip reduces the file size much better (from 32MB to 2MB) in the case of AeroZoom which contains multiple similar executables

11. Done. Now executing `AeroZoom_Unattended_Installer.exe` would silently trigger an extraction of 7-Zip SFX `AeroZoom_7-Zip_SFX.exe` and calls inner AeroZoom `Setup.exe` to install AeroZoom for all users with its unattended parameter `/programfiles /unattendAZ=1`

### About False-Positive Notices from Anti-virus Software

Like certain AutoHotkey applications, some anti-virus vendors may falsely identify the unattended installer created as undesirable. It is understandable considering the nature of this application is to perform installation and uninstallation in a silent way, which involves seemingly risky tasks such as modifying uninstallation keys in the registry. On the other hand, I found that compiling using Compile_AHK II and/or an icon helps lower the detection rates a little bit (from [12](https://www.virustotal.com/gui/file/e8cf2094a562a5b7010edecb8bdcb11f15ea95ab21bf3ce27e7e58426c3bcf6a/detection) down to [<10](https://www.virustotal.com/gui/file/015da23376e29da9e7501eaaf9c501fbfd3fce87e5604cd09fbe4cd191537c27/detection) out of 65 anti-virus applications on VirusTotal). Still, this false-positive detection issue may not be completely eliminated and can be safely ignored. It is recommended to [report your file to your anti-virus vendor as clean if possible](https://www.techsupportalert.com/content/how-report-malware-or-false-positives-multiple-antivirus-vendors.htm).

## Pushing Unattended Setup to Chocolatey

Thanks to this [Chocolatey how-to article by Coffmans](https://medium.com/@coffmans/my-own-chocolatey-package-for-dessert-f7721b7fe234), I was able to figure out how to push the outer unattended installer to the [Chocolatey community repository here](https://chocolatey.org/packages/aerozoom). For details, please refer to that article.

The Chocolatey-related files customized for AeroZoom have been included in the [git repository](https://github.com/wandersick/az-autohotkey-silent-setup) downloaded in step #1, in case they are of any interest:

```powershell
C:\az-autohotkey-silent-setup\Chocolatey\AeroZoom
│   aerozoom.nuspec                 # package metadata
│   ReadMe.md
│   _TODO.txt
│
└───tools
        chocolateybeforemodify.ps1  # tasks added to run before [un]installation scripts below
        chocolateyinstall.ps1       # edited Chocolatey installation script (for use with 'choco install')
        chocolateyuninstall.ps1     # edited Chocolatey uninstallation script (for use with: 'choco uninstall')
```

In addition, below are the commands used in case they are of any interest:

```powershell
choco pack                            # create .nupkg (aerozoom.4.0.0.7.nupkg)

choco install aerozoom.4.0.0.7.nupkg  # install aerozoom.4.0.0.7.nupkg by running
                                      # - chocolateybeforemodify.ps1
                                      # - chocolateyinstall.ps1

choco uninstall aerozoom              # uninstall aerozoom by running
                                      # - chocolateybeforemodify.ps1
                                      # - chocolateyuninstall.ps1

choco push aerozoom.4.0.0.7.nupkg     # push to community repo (--api-key required)
```

One AeroZoom-specific side-note:

- Due to the way `Setup.exe` of AeroZoom works, for `chocolateyuninstall.ps1`, I have added `Substring` (from PowerShell) to remove `/programfiles /unattendAZ=2` from `UninstallString` (in Windows registry), replacing it with `/programfiles /unattendAZ=1` from `$silentArgs` (in `chocolateyuninstall.ps1`). Otherwise, uninstallation would not be performed in an unattended way.

  ```powershell
  $packageArgs['file'] = "$($_.UninstallString)".Substring(0, $_.UninstallString.IndexOf(' /'))`
  ```

## Building and Obtaining Inner Setup.exe using AutoHotkey

Note: This section is about the inner `Setup.exe` acquired after 7-Zip extraction, instead of the outer unattended installer `AeroZoom_Unattended_Installer.exe`

```c
C:\AeroZoom
│   AeroZoom.exe
│   Readme.txt
│   Setup.exe // place the Setup.exe built using below method here (replace existing one, if any)
│
└───Data
```

- If not already done, the files above can be [downloaded here](https://gallery.technet.microsoft.com/AeroZoom-The-smooth-wheel-e0cdf778) and extracted to a desired directory, e.g. `C:\AeroZoom`

The remaining steps for building the Setup.exe would be:

(Some of the steps can be skipped if already performed)

1. Acquire the source code of `Setup.exe`, i.e. `Setup.ahk`:

   - Download or `git clone` [this repository](https://github.com/wandersick/az-autohotkey-silent-setup) to a desired directory e.g. `c:\az-autohotkey-silent-setup`

   ```c
   C:\az-autohotkey-silent-setup
   │   Setup.ahk // source code of Setup.exe of AeroZoom
   |   ...
   ```

2. [Download and install AutoHotKey](https://autohotkey.com)

3. While under repository directory (e.g. `C:\az-autohotkey-silent-setup`), compile `Setup.ahk` using the bundled AHk2Exe utility, usually located under `C:\Program Files\AutoHotkey\Compiler` as follows:

   - `"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "Setup.ahk" /icon "AeroZoom_Setup.ico"`
     - Icon parameter is optional: `/icon "AeroZoom_Setup.ico"`
   - Alternatively, to compile with the alternative compiler, download and install [Compile_AHK II](https://www.autohotkey.com/board/topic/21189-compile-ahk-ii-for-those-who-compile/), then right-click `Setup.ahk` and select _Compile with Options_, which would parse parameters from `Setup.ahk.ini`
     - While Compile_AHK II comes with compression feature, this post uses 7-Zip as 7-Zip reduces the file size much better (from 32MB to 2MB) in the case of AeroZoom which contains multiple similar executables

### How It Works

Instead of using a popular approach such as Windows Installer, AeroZoom implements the installer `Setup.exe` from the ground up, which has its own parameters:

- `/programfiles` for installing into `C:\Program Files (x86)` (or `C:\Program Files` for 32-bit OS) instead of current user profile, i.e. `%localappdata%`, usually `C:\Users\{username}\AppData\Local`
- `/unattendAZ=1` for an unattended installation

If it detects AeroZoom is already installed, the setup will perform an uninstallation instead

- If `/unattendAZ=2` or any other values, an uninstallation dialog box will also be prompted

```ahk
targetDir=%localappdata%
If %1% {
  Loop, %0%  ; For each parameter:
  {
    param := %A_Index%  ; Fetch the contents of the variable whose name is contained in A_Index.
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
```

During installation or uninstallation, `Setup.exe` would first check a few prerequisites, such as whether files it depends on exist or not, as well as terminiating any executables that could be running.

Once it is OK to proceed with installation, `Setup.exe` would create shortcuts:

```ahk
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
```

Next, `Setup.exe` would write uninstallation information such as `UninstallString` to the Windows Registry:

```ahk
If setupAllUsers ; if AeroZoom was installed for all users
  RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, UninstallString, %targetDir%\wandersick\AeroZoom\Setup.exe /unattendAZ=2 /programfiles
Else
  RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, UninstallString, %targetDir%\wandersick\AeroZoom\Setup.exe /unattendAZ=2
```

Other information it writes there are:

- Publisher
- DisplayVersion
- InstallLocation
- URLInfoAbout
- HelpLink
- InstallDate
- DisplayName
- DisplayIcon
- EstimatedSize

Regarding uninstallation, it is simply the above process in reverse, i.e. deleting shortcuts and removing the registry entries.

One thing worth mentioning is previous version of AeroZoom installer (`v4.0` and before) would leave `Setup.exe` under the installation directory. Since `v5.0`, this has been solved by calling a minimized `cmd.exe /c` to `ping localhost` followed by the self-destruction, in order for `Setup.exe` to delete itself.

```ahk
; Remove directory content including Setup.exe that is currently running after 3 seconds using ping in a minimized Command Prompt
Run, cmd /c start /min ping 127.0.0.1 -n 3 >nul & rd /s /q "%targetDir%\wandersick"
```

That's it.

For simplicity, only the essential parts of `Setup.exe` are described above. Things that are specific to AeroZoom (e.g. removing scheduled tasks that AeroZoom may have created if specified by user) are not mentioned. For the rest, please refer to the comments in the [source code file](https://github.com/wandersick/az-autohotkey-silent-setup/blob/master/Setup.ahk) `Setup.ahk` and the comments inside.

Feel free to [leave a comment](https://wandersick.blogspot.com/2019/07/how-to-create-silent-installer-with.html) if there are any questions, or if you have any suggestions as well. Have a nice day!
