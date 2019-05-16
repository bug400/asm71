;
; Install components sections for asm71
;
Section /o "Modify Path variable" SectionModifyPath
        SectionIn 3

        !insertmacro ADD_PATH $INSTDIR $MultiUser.InstallMode
        StrCpy $PathModified "1"
        !insertmacro DeleteRetryAbort "$SMPROGRAMS\$StartMenuFolder\${PRODUCT_NAME} Prompt.lnk"
SectionEnd


