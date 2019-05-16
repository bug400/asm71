;
; Installer defines -- product related
!define PRODUCT_NAME "asm71" ; name of the application as displayed to the user
!define VERSION "${VERSTR}" ; main version of the application (may be 0.1, alpha, beta, etc.)
!define PRODUCT_UUID "{1E8CC6C2-3C5D-4527-8665-86E082414646}" ; do not change this between program versions!
!define PROGEXE "${PRODUCT_NAME}.exe" ; main application filename
!define PROGHTML "${PRODUCT_NAME}.html"; documentation entry point
!define COMMENTS "${PRODUCT_NAME} assembler for the HP-71B" ; stored as comments in the uninstall info of the registry
!define URL_INFO_ABOUT "https://github.com/bug400/${PRODUCT_NAME}" ; stored as the Support Link in the uninstall info of the registry, and when not included, the Help Link as well
!define URL_HELP_LINK "https://github.com/bug400/${PRODUCT_NAME}/blob/master/INSTALL.md" ; stored as the Help Link in the uninstall info of the registry
!define URL_UPDATE_INFO "https://github.com/bug400/${PRODUCT_NAME}/releases" ; stored as the Update Information in the uninstall info of the registry
