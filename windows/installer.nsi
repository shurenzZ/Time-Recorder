; ============================================================
; Time Recorder Setup - NSIS installer script (ASCII only)
; Wraps PyInstaller output dist\Time Recorder.exe into an
; installer with Start Menu / Desktop shortcuts + uninstaller.
;
; Build (after installing NSIS):
;     makensis installer.nsi
; Output: Time Recorder Setup.exe
; ============================================================
!include "MUI2.nsh"

Name "Time Recorder"
OutFile "Time Recorder Setup.exe"
InstallDir "$LOCALAPPDATA\TimeRecorder"
RequestExecutionLevel user
ManifestSupportedOS "all"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "SimpChinese"

; ---------- Install section ----------
Section "Main" SEC01
  SetOutPath "$INSTDIR"
  File "dist\Time Recorder.exe"

  CreateDirectory "$SMPROGRAMS\Time Recorder"
  CreateShortcut "$SMPROGRAMS\Time Recorder\Time Recorder.lnk" "$INSTDIR\Time Recorder.exe"
  CreateShortcut "$DESKTOP\Time Recorder.lnk" "$INSTDIR\Time Recorder.exe"

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TimeRecorder" "DisplayName" "Time Recorder"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TimeRecorder" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TimeRecorder" "DisplayIcon" "$\"$INSTDIR\Time Recorder.exe$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TimeRecorder" "InstallLocation" "$\"$INSTDIR$\""
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TimeRecorder" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TimeRecorder" "NoRepair" 1
SectionEnd

; ---------- Uninstall section ----------
Section "Uninstall"
  Delete "$INSTDIR\Time Recorder.exe"
  Delete "$INSTDIR\Uninstall.exe"
  Delete "$SMPROGRAMS\Time Recorder\Time Recorder.lnk"
  Delete "$DESKTOP\Time Recorder.lnk"
  RMDir "$SMPROGRAMS\Time Recorder"
  RMDir "$INSTDIR"
  ; Remove per-user app data (staged HTML, WebView cache, localStorage) under %APPDATA%\TimeRecorder
  ; so an uninstall leaves no user data behind. (This only removes files; any session stored in
  ; Windows Credential Manager is not a file and is left for the user to clear manually.)
  RMDir /r "$APPDATA\TimeRecorder"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TimeRecorder"
SectionEnd
