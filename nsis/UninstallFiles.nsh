;
; Try to delete the EXE as the first step - if it's in use, don't remove anything else
        !insertmacro DeleteRetryAbort "$INSTDIR\${PROGEXE}"

        !insertmacro DeleteRetryAbort "$INSTDIR\doc\${PROGHTML}"
        !insertmacro DeleteRetryAbort "$INSTDIR\doc\GPL-2"

	RMdir "$INSTDIR\doc"
;
; remove file activate.bat
;
        !insertmacro DeleteRetryAbort "$INSTDIR\activate_${PRODUCT_NAME}.bat" 

