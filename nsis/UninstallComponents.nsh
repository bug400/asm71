;
; Uninstall components for asm71
;
        ; Remove path
        ${if} "$PathModified" == "1"
                !insertmacro REMOVE_PATH $INSTDIR $MultiUser.InstallMode
        ${endif}
