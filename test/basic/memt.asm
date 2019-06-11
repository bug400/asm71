       LEX    'MEM'   
************************************
*                                  *
* MEMORY MANAGEMENT LEX FILE       *
*                                  *
* (c) SIEBOLD 1984                 *
*                                  *
************************************
       ID     #5C
       MSG    0
       POLL   POLHND
*
       ENTRY  ANZ
       CHAR   #F
       ENTRY  DEL
       CHAR   #C
       ENTRY  GET
       CHAR   #C
       ENTRY  MAX
       CHAR   #F
       ENTRY  NEWK
       CHAR   #C
       ENTRY  OUT
       CHAR   #C
       ENTRY  PURK
       CHAR   #C
       ENTRY  PUT 
       CHAR   #C
       ENTRY  UPD 
       CHAR   #C
*
       KEY    'ANZ?'
       TOKEN  1
       KEY    'DEL'
       TOKEN  2
       KEY    'GET'
       TOKEN  3
       KEY    'MAX?'
       TOKEN  4
       KEY    'NEWK'
       TOKEN  5
       KEY    'OUT'
       TOKEN  6
       KEY    'PURK'
       TOKEN  7
       KEY    'PUT'
       TOKEN  8
       KEY    'UPD'
       TOKEN  9
       ENDTXT
*
PARERR EQU    #02F08
MGOSUB EQU    #1AF01
EOLCK  EQU    #02A7E
VARP   EQU    #0350E
NTOKEN EQU    #0493B
DROPDC EQU    #05470
NXTSTM EQU    #08A48
HEXDEC EQU    #0ECAF
DCHXW  EQU    #0ECDC
BSERR  EQU    #0939A
FLGREG EQU    #2F6E9
UPDANN EQU    #13571
A-MULT EQU    #1B349
FILEF  EQU    #09FB0
RJUST  EQU    #12AE2
FLOAT  EQU    #1B322
ADDRSS EQU    #0F527
OBCOLL EQU    #01435
RESPTR EQU    #03172
PRGFMF EQU    #0A146
FLTDH  EQU    #1B223
OUTEL1 EQU    #05300
FIXDC  EQU    #05493
FIXP   EQU    #02A6E
EXPEX- EQU    #0F178
D1MSTK EQU    #1954E
POP1R  EQU    #0E8FD
EXPR   EQU    #0F23C
CRETF+ EQU    #084C4
HDFLT  EQU    #1B31B
HXDCW  EQU    #0ECB4
*
VNRa   EQU    #2F881 STORE IN STATEMENT SCRATCH
VRa    EQU    #2F886
VHa    EQU    #2F88B
*
* POLLHANDLER
*
POLHND ?B=0   B
       GOYES  POLANF
       GONC   POLEND
POLANF C=R3
       D1=C
       A=R2
       D1=D1- (VER$en)-(VER$st)-2
       CD1EX
       ?A>C   A
       GOYES  POLEND 
       D1=C
       R3=C
VER$st LCASC  ' MEM:1A'
VER$en DAT1=C (VER$en)-(VER$st)-2
POLEND RTNSXM
*
*  MEM PARSE ROUTINES
*
GETp
PUTp
OUTp
UPDp   GOSUB  PVAR
       GONC   ERR1
       GOSUB  PVAR
       GONC   ERR1
DELp   GOSBVL VARP
       GOC    JMP51
       LC(4)  #0053
       GOTO   ERR1
JMP51  GOSBVL EOLCK
       GOC    JMP52
       LC(4)  #004B
       GOTO   ERR1
JMP52  GOVLNG RESPTR
*
*
PVAR   GOSBVL VARP
       GONC   ILLPAR
       GOSBVL NTOKEN
       P=     0
       LCHEX  #F1
       ?A=C   B
       GOYES  END1
       LC(4)  #004B
       RTNCC
ILLPAR LC(4)  #0053
       RTNCC
END1   RTNSC
*
ERR1   ST=1   4
       CD0EX
       D0=D0- 1
       GOVLNG PARERR
*
*  MEM DECOMPILE ROUTINES
*
GETd
PUTd
DELd
OUTd
UPDd   GOVLNG DROPDC
*
*
* FILE PARSE ROUTINES
*
NEWKp  GOVLNG FIXP
PURKp  GOSBVL EOLCK
       GOVLNG RESPTR
*
* FILE DECOMPILE ROUTINES
*
NEWKd  GOVLNG FIXDC
PURKd  GOVLNG OUTEL1
*
*
*
* INIT: EXECUTE PARAMETER LIST
*
INITD  SETHEX
       GOSBVL OBCOLL
       P=     0
       D1=(5) VNRa
       GOTO   INIT1
*
INIT   SETHEX
       GOSBVL OBCOLL
       P=     0
       D1=(5) VNRa
       GOSUB  GETADR
       RTNNC
       D1=(5) VRa
       GOSUB  GETADR
       RTNNC
       D1=(5) VHa
INIT1
       GOSUB  GETADR
       RTNNC
*
* CLEAR ERROR FLAG (0)
*
       P=     0
       D1=(5) FLGREG
       A=DAT1 P
       LCHEX  #E
       A=A&C  P
       DAT1=A P
       GOSBVL UPDANN
*
* LOOK FOR KOORD FILE
*
       LCASC  'zzzzzzzz'
       A=C    W
       GOSBVL FILEF
       GONC   JMP53
       RTNCC
JMP53  AD1EX
       C=0    A
       LCHEX  #25
       SETHEX
       A=A+C  A
       R3=A
       RTNSC
*
* LOOK FOR N IN FILE
*
FIND   D0=(5) VNRa
       A=DAT0 A
       AD0EX
       A=DAT0 W
       GOSUB  NFD
       R4=A   
       C=R3
       CD0EX
       C=DAT0 A
       D=C    A
       D0=D0+ 10
LOOP   ?D=0   A
       GOYES  ENDF
       D=D-1  A
       P=     7
       C=DAT0 WP
       ?A=C   WP
       GOYES  FOUND
       D0=D0+ 16
       D0=D0+ 10
       GOTO   LOOP
*
ENDF   A=0    A
       RTN
FOUND  AD0EX
       D0=A
       RTN
*
*
GETADR GOSBVL ADDRSS
       GOC    ILLVAR
       AD0EX
       DAT1=A A
       AD1EX
       P=     0
       A=DAT1 P
       LCHEX  #A
       ?A<C   P
       GOYES  JMP54
ILLVAR LC(4)  #000B
       RTNCC
JMP54  RTNSC
*
* CONVERSION ROUTINES
*
FFD    ST=0   2
       SETDEC
       A=A+1  X
       A=A+1  X
       A=A+1  X
       GOTO   JMP20
NFD    ST=1   2
JMP20  SETHEX
       ST=0   1
       ?A=0   S
       GOYES  JMP21
       ST=1   1
       A=0    S
JMP21  GOSBVL RJUST
       C=A    W
       GOSBVL DCHXW
       ?ST=0  1
       GOYES  JMP23
       P=     8
       ?ST=0  2
       GOYES  JMP22
       P=     7
JMP22  LCHEX  #8
       A=A!C  P
JMP23  P=     0
       ST=0   2
       ST=0   1
       SETHEX
       RTN
*
FDF    ST=0   2
       P=     8
       GOTO   JMP25
NDF    ST=1   2
       P=     7
JMP25  LCHEX  #8
       C=C&A  P
       ST=0   1
       ?C=0   P
       GOYES  JMP26
       LCHEX  #7
       A=A&C  P
       ST=1   1
JMP26  P=     0
       C=A    W
       GOSBVL HXDCW
       GOSBVL FLOAT
       ?ST=0  1
       GOYES  JMP27
       P=     15
       LCHEX  #9
       P=     0
       A=C    S
       ST=0   1
JMP27  ?ST=1  2
       GOYES  JMP28
       A=A-1  X
       A=A-1  X
       A=A-1  X
JMP28  ST=0   2
       P=     0
       SETHEX
       RTN
*
* STORE R,H INTO FILE
*
INRH   D1=(5) VRa
       GOSUB  PUTF
       D0=D0+ 9
       D1=(5) VHa
       GOSUB  PUTF
       P=     0
       RTN
PUTF   A=DAT1 A
       AD1EX
       A=DAT1 W
       GOSUB  FFD
       P=     8
       DAT0=A WP
       RTN
*
* GET R,H FROM FILE
*
OUTRH  D1=(5) VRa
       GOSUB  GETF
       D0=D0+ 9
       D1=(5) VHa
       GOSUB  GETF
       P=     0
       RTN
GETF   P=     8
       A=0    W
       A=DAT0 WP
       P=     0
       GOSUB  FDF
       C=DAT1 A
       CD1EX
       DAT1=A W
       RTN
*
* FULCHK: CHECK FILE OVERFLOW
*
FULCHK SETHEX
       C=R3
       CD1EX
       A=DAT1 A
       D1=D1+ 5
       C=DAT1 A
       ?A#C   A
       GOYES  INCNP
       ST=1   1
       RTN
INCNP  A=A+1  A
       D1=D1- 5
       DAT1=A A
       RTN
*
* ENDADR: COMP ADDR OF LAST ELEMENT
*
ENDADR C=R3
       CD1EX
       A=DAT1 A
*
* ADR: COMPUTE ELEMENT ADR
*
ADR    SETHEX
       A=A-1  A
       P=     0
       LCHEX  #0001A
       GOSBVL A-MULT
       C=R3
       A=A+C  A
       AD0EX
       D0=D0+ 10
       RTN
*
ERR2   GOTO   bserr
*
* GET
*
       REL(5) GETd
       REL(5) GETp
GET    GOSUB  INIT
       GONC   ERR2
       GOSUB  FIND
       ?A#0   A
       GOYES  JMP1
       GOTO   NOEX
JMP1   D0=D0+ 8
       GOSUB  OUTRH
       GOTO   EXIT
*
* DEL
*
       REL(5) DELd
       REL(5) DELp
DEL    GOSUB  INITD
       GONC   ERR2
       GOSUB  FIND
       ?A#0   A
       GOYES  JMP2
       GOTO   NOEX
JMP2   R0=A
       GOSUB  ENDADR
       A=R0
       AD1EX
       A=DAT0 W
       DAT1=A W
       P=     9 
       D0=D0+ 16
       D1=D1+ 16
       A=DAT0 WP
       DAT1=A WP
       P=     0
       C=R3
       CD1EX
       SETHEX
       C=DAT1 A
       C=C-1  A
       DAT1=C A
       GOTO   EXIT
*
* PUT
*
       REL(5) PUTd
       REL(5) PUTp
PUT    GOSUB  INIT
       GONC   ERR4
       GOSUB  FIND
       ?A=0   A
       GOYES  JMP3
       GOTO   DUP
JMP3   ST=0   1
       GOSUB  FULCHK
       ?ST=0  1
       GOYES  JMP5
       GOTO   FULL
JMP5   GOSUB  ENDADR
       C=R4
       P=     7
       DAT0=C WP
       D0=D0+ 8
       GOSUB  INRH
       GOTO   EXIT
*
ERR4   GOTO   bserr
*
* OUT
*
       REL(5) OUTd
       REL(5) OUTp
OUT    GOSUB  INIT
       GONC   ERR4
       D1=(5) VNRa
       A=DAT1 A
       AD1EX
       A=DAT1 W
       GOSBVL RJUST
       C=A    W
       GOSBVL DCHXW
       C=R3
       CD1EX
       C=DAT1 A
       ?A>C   A
       GOYES  OFR
       ?A=0   A
       GOYES  OFR
       GOSUB  ADR
       P=     7
       A=0    W
       A=DAT0 WP
       P=     0
       GOSUB  NDF
       D1=(5) VNRa
       C=DAT1 A
       CD1EX
       DAT1=A W
       D0=D0+ 8
       GOSUB  OUTRH
       GOTO   EXIT
OFR    GOTO   NOEX
*
* UPD
*
       REL(5) UPDd
       REL(5) UPDp
UPD    GOSUB  INIT
       GONC   ERR3
       GOSUB  FIND
       ?A#0   A
       GOYES  JMP4
       GOTO   NOEX
JMP4   D0=D0+ 8
       GOSUB  INRH
       GOTO   EXIT
*
INVARG LC(4)  #000B
ERR3   GOTO   bserr
*
* NEWK  CREATE NEW KOORDFILE
*
       REL(5) NEWKd
       REL(5) NEWKp
NEWK   GOSBVL OBCOLL
       GOSBVL MGOSUB
       CON(5) EXPEX-
       GOSBVL D1MSTK
       GOSBVL POP1R
       GOSBVL FLTDH
       GONC   INVARG
       P=     0
       LCHEX  #00001
       ?A<C   A
       GOYES  INVARG
       R2=A
NEWK1  GOSUB  FINDF
       ?ST=1  1
       GOYES  NOPURG
       GOSBVL MGOSUB
       CON(5) PRGFMF
       GONC   NEWK1
       GOTO   PRGERR
*
NOPURG A=R2
       P=     0
       LCHEX  #0001A
       GOSBVL A-MULT
       LCHEX  #00037
       C=C+A  A
       D=0    S
       GOSBVL MGOSUB
       CON(5) CRETF+
       GONC   JMP12
       GOTO   CRTERR
JMP12  C=R1
       CD0EX
       LCASC  'zzzzzzzz'
       DAT0=C W
       D0=D0+ 16
       P=     0
       LCHEX  #10E0F0
       P=     5
       DAT0=C WP
       P=     0
       D0=D0+ 16
       D0=D0+ 5
       C=0    A
       DAT0=C A
       D0=D0+ 5
       C=R2
       DAT0=C A
       GOTO   EXIT
*
* PURK PURGE KOORD FILE
*
       REL(5) PURKd
       REL(5) PURKp
PURK   GOSBVL OBCOLL
       GOSUB  FINDF
       ?ST#1  1
       GOYES  JMP13
       GOTO   FNDERR
JMP13  GOSBVL MGOSUB
       CON(5) PRGFMF
       GONC   JMP14
       GOTO   PRGERR
JMP14  GOTO   EXIT
*
* ANZ? GET NO OF KOORDS STORED
*
       NIBHEX 00
ANZ    CD1EX
       RSTK=C
       GOSUB  FINDF
       ?ST#1  1
       GOYES  JMP15
       GOTO   FNDERR
JMP15  D1=D1+ 16
       D1=D1+ 16
       D1=D1+ 5
       A=DAT1 A
       GOTO   RETURN
*
* MAX? GET MAX NO OF KOORDS
*
       NIBHEX 00
MAX    CD1EX
       RSTK=C
       GOSUB  FINDF
       ?ST#1  1
       GOYES  JMP16
       A=0    A
       GOTO   RETURN
JMP16  D1=D1+ 16
       D1=D1+ 16
       D1=D1+ 10
       A=DAT1 A
*
RETURN GOSBVL HDFLT
       C=RSTK
       CD1EX
       D1=D1- 16
       DAT1=A W
       GOVLNG EXPR  
*
FINDF  ST=0   1
       LCASC  'zzzzzzzz'
       A=C    W
       P=     0
       GOSBVL FILEF
       RTNNC
       ST=1   1
       RTN
*
FNDERR
PRGERR
CRTERR P=     0
bserr  GOVLNG BSERR
*
*
*
*
* ERROR HANDLER
*
NOEX 
FULL  
DUP    SETHEX
       P=     0
       D1=(5) FLGREG
       A=DAT1 P
       LCHEX  #01
       A=A!C  P
       DAT1=A P
       GOSBVL UPDANN
*
* FINITO
*
EXIT
       GOSBVL OBCOLL
       GOVLNG NXTSTM
       END
