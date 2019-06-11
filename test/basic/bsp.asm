       LEX    'TEST'  assemble LEX-file 'TEST'
*
*
*      Name:  PROMPT$
*
*      Purpose:
*      This Function puts the CPU into a low power consumption
*      state. The machine wakes up if a key is pressed and returns
*      the keycode (see KEY$ function).
*      Note: the < > cursor keys may be used to scroll a displayed
*      string while the machine is inactive.
*
*
*      Name:  REV$
*
*      Purpose:
*      Reverses a string
*
*
*
       ID     #5C     ID of LEX File
       MSG    0       No message table
       POLL   0       No poll handler
*
       ENTRY  PROMPT  First keyword is coded at the label PROMPT
       CHAR   #F      First keyword is a BASIC Function
       ENTRY  REV     Second keyword is coded at the label REV
       CHAR   #F      Second keyword is a BASIC Function
*
       KEY    'PROMPT$' First keyword is called 'PROMPT$'
       TOKEN  1         First keyword has token 1
       KEY    'REV$'    Second keyword is called 'REV$'
       TOKEN  2         Second keyword has token 2
       ENDTXT
*
*      PROMPT$ BASIC function execute
*
       NIBHEX 00
PROMPT CD0EX
       R1=C           save PC
       CD1EX
       R2=C           save SP
       GOSBVL =SCRLLR halt and process scrolling
       C=R1
       CD0EX          restore PC
       C=R2
       CD1EX          restore SP
       GOVLNG =KEY$   return keycode
*
*      REV$ BASIC function execute
*
       NIBHEX 411
REV    GOSBVL =REV$   reverse string on stack
       GOVLNG =EXPR   return string
       END