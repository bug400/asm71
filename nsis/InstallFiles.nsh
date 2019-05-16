;
; install files
;
	SetOutPath "$INSTDIR"
        File "${SRC}\${PROGEXE}"

        createDirectory "$INSTDIR\doc"
        SetOutPath "$INSTDIR\doc"
        FILE "${SRC}\doc\GPL-2"
        FILE "${SRC}\doc\${PROGHTML}"

;
; write file activate.bat
;
        FileOpen $4 "$INSTDIR\activate_${PRODUCT_NAME}.bat" w
        FileWrite $4 "@PATH=$INSTDIR;%PATH%$\r$\n"
        FileClose $4

