; Command line arguments:
; makensis -DINPDIR=<input-dir> -DINPDIR64=<input-dir-64-bit> \
;   -DOUTFILE=<output-file> -DVERSTR=<version-string> asm71.nsi
; nsis configuration file for ths ASM71 package
;
; Issues:
; - does not deinstall correctly if deinstall called from "Apps & Features"
; - do not install ASM71 prompt if path variable is modified
;
SetCompressor /SOLID lzma
!include MUI.nsh
; OR
; !include MUI2.nsh
!include UAC.nsh
!include NsisMultiUser.nsh
!include LogicLib.nsh
!include "..\nsis\Utils.nsh"

!ifdef INPDIR
	!define ASM71_SRC "${INPDIR}"
	!define PLATFORM "Win32"
!endif
!ifdef INPDIR64
	!define ASM71_SRC "${INPDIR64}"
	!define PLATFORM "Win64"
!endif

!ifndef OUTFILE
	!ifdef INPDIR
		!define OUTFILE "asm71-win32-setup.exe"
	!endif
	!ifdef INPDIR64
		!define OUTFILE "asm71-win64-setup.exe"
	!endif
!endif


!define PRODUCT_NAME "asm71" ; name of the application as displayed to the user
!define VERSION "${VERSTR}" ; main version of the application (may be 0.1, alpha, beta, etc.)
!define PRODUCT_UUID "{7f4533f5-5e15-43f5-b0ad-10f9ef1f0a55}" ; do not change this between program versions!
!define PROGEXE "asm71.exe" ; main application filename
!define MIN_WIN_VER "XP"
!define SINGLE_INSTANCE_ID "${PRODUCT_UUID}" ; do not change this between program versions!
!define LICENSE_FILE "${ASM71_SRC}/doc/GPL-2" ; license file, optional
!define COMPANY_NAME ""

; NsisMultiUser optional defines
!define MULTIUSER_INSTALLMODE_ALLOW_BOTH_INSTALLATIONS 0
!define MULTIUSER_INSTALLMODE_ALLOW_ELEVATION 1
!define MULTIUSER_INSTALLMODE_ALLOW_ELEVATION_IF_SILENT 0
!define MULTIUSER_INSTALLMODE_DEFAULT_ALLUSERS 0
!define MULTIUSER_INSTALLMODE_DEFAULT_CURRENTUSER 1
!define MULTIUSER_INSTALLMODE_UNINSTALL_REGISTRY_KEY "${PRODUCT_UUID}"
!if ${PLATFORM} == "Win64"
	!define MULTIUSER_INSTALLMODE_64_BIT 1
!endif
!define MULTIUSER_INSTALLMODE_DISPLAYNAME "${PRODUCT_NAME} ${VERSION} ${PLATFORM}"  

Var StartMenuFolder

; Installer Attributes
Name "${PRODUCT_NAME} ${VERSION} ${PLATFORM}"
OutFile ${OUTFILE}
BrandingText "2019 ${COMPANY_NAME}"

AllowSkipFiles off
SetOverwrite on ; (default setting) set to on except for where it is manually switched off
ShowInstDetails show 
;SetCompressor /SOLID lzma

; Pages
!define MUI_ABORTWARNING ; Show a confirmation when cancelling the installation

!define MUI_PAGE_CUSTOMFUNCTION_PRE PageWelcomeLicensePre
!insertmacro MUI_PAGE_WELCOME

!ifdef LICENSE_FILE
	!define MUI_PAGE_CUSTOMFUNCTION_PRE PageWelcomeLicensePre
	!insertmacro MUI_PAGE_LICENSE "${LICENSE_FILE}"
!endif


!define MULTIUSER_INSTALLMODE_CHANGE_MODE_FUNCTION PageInstallModeChangeMode
!insertmacro MULTIUSER_PAGE_INSTALLMODE 

!define MUI_COMPONENTSPAGE_SMALLDESC
;!define MUI_PAGE_CUSTOMFUNCTION_SHOW PageComponentsShow
!insertmacro MUI_PAGE_COMPONENTS

!define MUI_PAGE_CUSTOMFUNCTION_PRE PageDirectoryPre
!define MUI_PAGE_CUSTOMFUNCTION_SHOW PageDirectoryShow
!insertmacro MUI_PAGE_DIRECTORY

!define MUI_STARTMENUPAGE_NODISABLE ; Do not display the checkbox to disable the creation of Start Menu shortcuts
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${PRODUCT_NAME}"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "SHCTX" ; writing to $StartMenuFolder happens in MUI_STARTMENU_WRITE_END, so it's safe to use "SHCTX" here
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_UUID}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "StartMenuFolder"
!define MUI_PAGE_CUSTOMFUNCTION_PRE PageStartMenuPre
!insertmacro MUI_PAGE_STARTMENU "" "$StartMenuFolder"

!insertmacro MUI_PAGE_INSTFILES


!include "..\nsis\Uninstall.nsh"

!insertmacro MUI_LANGUAGE "English" ; Set languages (first is default language) - must be inserted after all pages 

InstType "Typical" 
InstType "Minimal" 
InstType "Full" 

Section "Core Files (required)" SectionCoreFiles
	SectionIn 1 2 3 RO
	
	; if there's an installed version, uninstall it first (I chose not to start the uninstaller silently, so that user sees what failed)
	; if both per-user and per-machine versions are installed, unistall the one that matches $MultiUser.InstallMode
	StrCpy $0 ""
	${if} $HasCurrentModeInstallation == 1
		StrCpy $0 "$MultiUser.InstallMode"
	${else}
		!if	${MULTIUSER_INSTALLMODE_ALLOW_BOTH_INSTALLATIONS} == 0
			${if}	$HasPerMachineInstallation == 1
				StrCpy $0 "AllUsers" ; if there's no per-user installation, but there's per-machine installation, uninstall it 
			${elseif}	$HasPerUserInstallation == 1
				StrCpy $0 "CurrentUser" ; if there's no per-machine installation, but there's per-user installation, uninstall it
			${endif}	
		!endif
	${endif}
		
	${if} "$0" != ""
		${if} $0 == "AllUsers"
			StrCpy $1 "$PerMachineUninstallString"
			StrCpy $3 "$PerMachineInstallationFolder"
		${else}
			StrCpy $1 "$PerUserUninstallString"
			StrCpy $3 "$PerUserInstallationFolder"
		${endif}
		${if} ${silent}
			StrCpy $2 "/S"
		${else}	
			StrCpy $2 ""
		${endif}	
		
		HideWindow
		ClearErrors
		StrCpy $0 0
		ExecWait '$1 /SS $2 _?=$3' $0 ; $1 is quoted in registry; the _? param stops the uninstaller from copying itself to the temporary directory, which is the only way for ExecWait to work
		
		${if} ${errors} ; stay in installer
			SetErrorLevel 2 ; Installation aborted by script
			BringToFront
			Abort "Error executing uninstaller."
		${else}	
			${Switch} $0
				${Case} 0 ; uninstaller completed successfully - continue with installation
					BringToFront 
					${Break}									
				${Case} 1 ; Installation aborted by user (cancel button)
				${Case} 2 ; Installation aborted by script
					SetErrorLevel $0
					Quit ; uninstaller was started, but completed with errors - Quit installer
				${Default} ; all other error codes - uninstaller could not start, elevate, etc. - Abort installer
					SetErrorLevel $0
					BringToFront
					Abort "Error executing uninstaller."
			${EndSwitch}				
		${endif}		
			
		Delete "$2\${UNINSTALL_FILENAME}"	; the uninstaller doesn't delete itself when not copied to the temp directory
		RMDir "$2"  	
	${endif}	
		
	SetOutPath $INSTDIR
	; Write uninstaller and registry uninstall info as the first step,
	; so that the user has the option to run the uninstaller if sth. goes wrong 
	WriteUninstaller "${UNINSTALL_FILENAME}"			
	!insertmacro MULTIUSER_RegistryAddInstallInfo ; add registry keys		
	SetOutPath "$INSTDIR"
	File "${ASM71_SRC}\asm71.exe"

	createDirectory "$INSTDIR\doc"
	SetOutPath "$INSTDIR\doc"
        FILE "${ASM71_SRC}\doc\GPL-2"
        FILE "${ASM71_SRC}\doc\asm71.html"

;
; write file activate.bat
;
        FileOpen $4 "$INSTDIR\activate_asm71.bat" w 
        FileWrite $4 "@PATH=$INSTDIR;%PATH%$\r$\n"
        FileClose $4

SectionEnd

SectionGroup /e "Integration" SectionGroupIntegration

Section "Program Group" SectionProgramGroup
	SectionIn 1	3
	
  !insertmacro MUI_STARTMENU_WRITE_BEGIN ""

	  CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
                 CreateShortCut "$SMPROGRAMS\$StartMenuFolder\ASM71 Prompt.lnk" "%windir%\system32\cmd.exe" "/K $\"$INSTDIR\activate_asm71.bat$\"" "%windir%\system32\cmd.exe" 0 SW_SHOWNORMAL ALT|CONTROL|SHIFT|F5 "ASM71 command prompt"
                 CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Documentation.lnk" "$INSTDIR\doc\asm71.html"

			
		${if} $MultiUser.InstallMode == "AllUsers" 
			CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\${UNINSTALL_FILENAME}" "/allusers"
		${else}
			CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall (current user).lnk" "$INSTDIR\${UNINSTALL_FILENAME}" "/currentuser"
		${endif}
	
  !insertmacro MUI_STARTMENU_WRITE_END	
SectionEnd


Section /o "Modify Path variable" SectionModifyPath
	SectionIn 3

        !insertmacro ASM71_ADD_PATH $INSTDIR $MultiUser.InstallMode
SectionEnd

SectionGroupEnd

; Modern install component descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${SectionCoreFiles} "Core files requred to run ${PRODUCT_NAME}."
	
  !insertmacro MUI_DESCRIPTION_TEXT ${SectionGroupIntegration} "Select how to integrate the program in Windows."
	!insertmacro MUI_DESCRIPTION_TEXT ${SectionProgramGroup} "Create a ${PRODUCT_NAME} program group under Start Menu->Programs."
	!insertmacro MUI_DESCRIPTION_TEXT ${SectionModifyPath} "Modify PATH variable for ${PRODUCT_NAME}."

!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Callbacks 
Function .onInit
	!insertmacro CheckPlatform ${PLATFORM}
	!insertmacro CheckMinWinVer ${MIN_WIN_VER}
	${ifnot} ${UAC_IsInnerInstance}
		!insertmacro CheckSingleInstance "${SINGLE_INSTANCE_ID}"
	${endif}	

	!insertmacro MULTIUSER_INIT	  
FunctionEnd

Function PageWelcomeLicensePre		
	${if} $InstallShowPagesBeforeComponents == 0
		Abort ; don't display the Welcome and License pages for the inner instance 
	${endif}	
FunctionEnd

Function PageInstallModeChangeMode
	!insertmacro MUI_STARTMENU_GETFOLDER "" $StartMenuFolder
FunctionEnd

Function PageDirectoryPre	
	GetDlgItem $0 $HWNDPARENT 1		
	${if} ${SectionIsSelected} ${SectionProgramGroup}		
		SendMessage $0 ${WM_SETTEXT} 0 "STR:$(^NextBtn)" ; this is not the last page before installing
	${else}
		SendMessage $0 ${WM_SETTEXT} 0 "STR:$(^InstallBtn)" ; this is the last page before installing
	${endif}		
FunctionEnd

Function PageDirectoryShow
	${if} $CmdLineDir != ""
		FindWindow $R1 "#32770" "" $HWNDPARENT
		
		GetDlgItem $0 $R1 1019 ; Directory edit
		SendMessage $0 ${EM_SETREADONLY} 1 0 ; read-only is better than disabled, as user can copy contents
		
		GetDlgItem $0 $R1 1001 ; Browse button
		EnableWindow $0 0	
	${endif}			
FunctionEnd

Function PageStartMenuPre
	${ifnot} ${SectionIsSelected} ${SectionProgramGroup}
		Abort ; don't display this dialog if SectionProgramGroup is not selected
	${endif}	
FunctionEnd

Function .onInstFailed
	MessageBox MB_ICONSTOP "${PRODUCT_NAME} ${VERSION} could not be fully installed.$\r$\nPlease, restart Windows and run the setup program again." /SD IDOK
FunctionEnd

