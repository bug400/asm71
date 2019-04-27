Var SemiSilentMode ; installer started uninstaller in semi-silent mode using /SS parameter
Var RunningFromInstaller ; installer started uninstaller using /uninstall parameter

; Installer Attributes
ShowUninstDetails show 

; Pages
!define MUI_UNABORTWARNING ; Show a confirmation when cancelling the installation

!define MULTIUSER_INSTALLMODE_CHANGE_MODE_UNFUNCTION un.PageInstallModeChangeMode
!insertmacro MULTIUSER_UNPAGE_INSTALLMODE

!define MUI_PAGE_CUSTOMFUNCTION_PRE un.PageComponentsPre
!define MUI_PAGE_CUSTOMFUNCTION_SHOW un.PageComponentsShow

!insertmacro MUI_UNPAGE_INSTFILES

Section "un.Program Files" SectionUninstallProgram
	SectionIn RO

	; Try to delete the EXE as the first step - if it's in use, don't remove anything else
	!insertmacro un.DeleteRetryAbort "$INSTDIR\barprt.exe"


        !insertmacro un.DeleteRetryAbort "$INSTDIR\doc\asm71.html"
        !insertmacro un.DeleteRetryAbort "$INSTDIR\doc\GPL-2"
	RMdir "$INSTDIR\doc"
	
  ; Clean up "Program Group entries" we check that we created Start menu folder
	${if} "$StartMenuFolder" != ""
                !insertmacro un.DeleteRetryAbort "$SMPROGRAMS\$StartMenuFolder\ASM71 Prompt.lnk"
                !insertmacro un.DeleteRetryAbort "$SMPROGRAMS\$StartMenuFolder\Documentation.lnk"
		RMDir "$SMPROGRAMS\$StartMenuFolder"
	${endif}	

  ; Remove path
	!insertmacro ASM71_REMOVE_PATH $INSTDIR $MultiUser.InstallMode

SectionEnd

Section "-Uninstall" ; hidden section, must always be the last one!
	; Remove the uninstaller from registry as the very last step - if sth. goes wrong, let the user run it again
	!insertmacro MULTIUSER_RegistryRemoveInstallInfo ; Remove registry keys
		
  Delete "$INSTDIR\${UNINSTALL_FILENAME}"	
  ; remove the directory only if it is empty - the user might have saved some files in it		
	RMDir "$INSTDIR"  		
SectionEnd

; Callbacks
Function un.onInit	
	${GetParameters} $R0
		
	${GetOptions} $R0 "/uninstall" $R1
	${ifnot} ${errors}	
		StrCpy $RunningFromInstaller 1		
	${else}
		StrCpy $RunningFromInstaller 0
	${endif}
	
	${GetOptions} $R0 "/SS" $R1
	${ifnot} ${errors}		
		StrCpy $SemiSilentMode 1
		SetAutoClose true ; auto close (if no errors) if we are called from the installer; if there are errors, will be automatically set to false
	${else}
		StrCpy $SemiSilentMode 0
	${endif}		
	
	${ifnot} ${UAC_IsInnerInstance}
		${andif} $RunningFromInstaller$SemiSilentMode == "00"
		!insertmacro CheckSingleInstance "${SINGLE_INSTANCE_ID}"
	${endif}		
		
	!insertmacro MULTIUSER_UNINIT		
FunctionEnd

Function un.PageInstallModeChangeMode
	!insertmacro MUI_STARTMENU_GETFOLDER "" $StartMenuFolder
FunctionEnd

Function un.PageComponentsPre
	${if} $SemiSilentMode == 1
		Abort ; if user is installing, no use to remove program settings anyway (should be compatible with all versions)
	${endif}
FunctionEnd

Function un.PageComponentsShow
	; Show/hide the Back button 
	GetDlgItem $0 $HWNDPARENT 3 
	ShowWindow $0 $UninstallShowBackButton
FunctionEnd

Function un.onUninstFailed
	${if} $SemiSilentMode == 0
		MessageBox MB_ICONSTOP "${PRODUCT_NAME} ${VERSION} could not be fully uninstalled.$\r$\nPlease, restart Windows and run the uninstaller again." /SD IDOK	
	${else}
		MessageBox MB_ICONSTOP "${PRODUCT_NAME} could not be fully installed.$\r$\nPlease, restart Windows and run the setup program again." /SD IDOK	
	${endif}
FunctionEnd
