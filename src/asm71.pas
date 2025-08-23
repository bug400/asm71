program ASM71(input,output);

{

HP-71 cross assembler
Copyright  Joachim Siebold   1986,2020
Developped under Turbo Pascal Version 3.0 1986
Converted to Turbo Pascal Version 5.0 12/1988
Converted to FPC Version 0.99 2/1998 (Linux)
Converted to FPC Version 2.00 9/2005 (Linux)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


Changelog:
Date        Issue
----------------------------------------
15.03.2015  Fixed errors from the HP71B ROM bug list:
            Fixed bad opcode D1=AS (replace 138 by 139)
            B=B+B A opcode had a bad class, flags corrected
04.05.2015  HP-71 and HP-IL entry points of the areuh
            assembler implemented.
27.04.2019  Fixed compile issues on Windows 64bit
09.05.2019  Regression test mode implemented
10.04.2020  Labels starting with "=" now allowed in label field
            Added the strict mode option
            Labels longer than 7 characters are truncated and raise an 
            error only if strict mode was enabled.
            Fixed truncated decimal values in the symbol reference listing

}

uses sysutils;

const  NULENT = 8; (* Null entry in opcode table *)
       MAXOPCIND = 42;  (* length of opcode index table *)
       VERSION = 'Vers 2.1.1'; (* assembler version *)
{$ifdef Win32}
       SYS = '(Windows 32bit)';
       {$define SYS_DEFINED}
{$endif}
{$ifdef Win64}
       SYS = '(Windows 64bit)';
       {$define SYS_DEFINED}
{$endif}
{$ifdef Unix}
       SYS = '(Unix)';
       {$define SYS_DEFINED}
{$endif}
{$ifndef SYS_DEFINED}
       SYS = '      ';
{$endif}

       VERS_DATE= 'April 2020  ';
       COPYRIGHT= '(C) Copyright J. Siebold 1985-2020';
       MAXNUM  = 1048575;


type   SYTTYP= (LABL,EQUATE,EQUPAS2,EXTERN,NOTFOUND);
       FILTYP= (NONE,LEX,BIN);
       NIB= 0..15;
       NIB5= array[1..5] of NIB;
       STRING6   = string[6];

       OPTYP = record
               OPCLS    : byte;
               TXT      : string6;
               FLGS     : byte;
               OPCLEN   : byte;
               OPC      : nib5;
               VARA     : byte;
               VARB     : byte;
               LFT      : integer;
               RGT      : integer;
               LEAF     : byte;
               end;


type   mottyp= array[1..367] of optyp;
const  mot:mottyp= (
     (opcls:5;txt:'CSLC  ';flgs:1;
     opclen:3;opc:(8,1,2,0,0);
     vara:0;varb:0;lft:2;rgt:3;leaf:0),
     (opcls:3;txt:'C=C!B ';flgs:1;
     opclen:4;opc:(0,14,0,13,0);
     vara:0;varb:0;lft:4;rgt:5;leaf:0),
     (opcls:10;txt:'P=C   ';flgs:33;
     opclen:4;opc:(8,0,13,0,0);
     vara:0;varb:0;lft:6;rgt:7;leaf:0),
     (opcls:1;txt:'?A>B  ';flgs:3;
     opclen:3;opc:(8,0,0,0,0);
     vara:2;varb:0;lft:8;rgt:9;leaf:0),
     (opcls:5;txt:'CR1EX ';flgs:5;
     opclen:3;opc:(1,2,9,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'D1=CS ';flgs:5;
     opclen:3;opc:(1,3,13,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'SETDEC';flgs:5;
     opclen:2;opc:(0,5,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:5;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'AR0EX ';flgs:5;
     opclen:3;opc:(1,2,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:13;txt:'DAT0=A';flgs:32;
     opclen:4;opc:(1,5,0,0,0);
     vara:0;varb:0;lft:11;rgt:12;leaf:0),
     (opcls:1;txt:'?C>A  ';flgs:3;
     opclen:3;opc:(8,0,2,0,0);
     vara:2;varb:0;lft:13;rgt:14;leaf:0),
     (opcls:4;txt:'GOYES ';flgs:41;
     opclen:2;opc:(0,0,0,0,0);
     vara:1;varb:2;lft:15;rgt:16;leaf:0),
     (opcls:1;txt:'?A>=C ';flgs:3;
     opclen:3;opc:(8,0,14,0,0);
     vara:2;varb:0;lft:17;rgt:18;leaf:0),
     (opcls:33;txt:'CHAR  ';flgs:33;
     opclen:1;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:19;rgt:20;leaf:0),
     (opcls:4;txt:'GONC  ';flgs:33;
     opclen:3;opc:(5,0,0,0,0);
     vara:2;varb:2;lft:21;rgt:22;leaf:0),
     (opcls:5;txt:'RTI   ';flgs:1;
     opclen:2;opc:(0,15,0,0,0);
     vara:0;varb:0;lft:23;rgt:24;leaf:0),
     (opcls:1;txt:'?A<=B ';flgs:7;
     opclen:3;opc:(8,0,12,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?B#C  ';flgs:7;
     opclen:3;opc:(8,0,5,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'B=B+B ';flgs:4;
     opclen:3;opc:(0,0,5,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'D1=AS ';flgs:5;
     opclen:3;opc:(1,3,9,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:22;txt:'EQU   ';flgs:36;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'GOSBVL';flgs:53;
     opclen:7;opc:(8,15,0,0,0);
     vara:3;varb:5;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'NOP4  ';flgs:5;
     opclen:4;opc:(6,3,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'RTNC  ';flgs:5;
     opclen:3;opc:(4,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=D   ';flgs:0;
     opclen:3;opc:(0,0,11,0,0);
     vara:2;varb:0;lft:26;rgt:27;leaf:0),
     (opcls:2;txt:'A=A-B ';flgs:0;
     opclen:3;opc:(0,0,0,0,0);
     vara:3;varb:0;lft:28;rgt:29;leaf:0),
     (opcls:5;txt:'RTNNC ';flgs:1;
     opclen:3;opc:(5,0,0,0,0);
     vara:0;varb:0;lft:30;rgt:31;leaf:0),
     (opcls:6;txt:'?MP=0 ';flgs:3;
     opclen:3;opc:(8,3,8,0,0);
     vara:0;varb:0;lft:32;rgt:33;leaf:0),
     (opcls:2;txt:'A=C   ';flgs:4;
     opclen:3;opc:(0,0,10,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'DSLC  ';flgs:5;
     opclen:3;opc:(8,1,3,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:7;txt:'RTNYES';flgs:13;
     opclen:2;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?B#A  ';flgs:7;
     opclen:3;opc:(8,0,4,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:8;txt:'?P#   ';flgs:39;
     opclen:3;opc:(8,8,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:13;txt:'DAT0=C';flgs:32;
     opclen:4;opc:(1,5,4,0,0);
     vara:0;varb:0;lft:35;rgt:36;leaf:0),
     (opcls:2;txt:'A=A+B ';flgs:0;
     opclen:3;opc:(0,0,0,0,0);
     vara:1;varb:0;lft:37;rgt:38;leaf:0),
     (opcls:27;txt:'WORDI ';flgs:32;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:39;rgt:40;leaf:0),
     (opcls:1;txt:'?D#0  ';flgs:7;
     opclen:3;opc:(8,0,15,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=D+C ';flgs:4;
     opclen:3;opc:(0,0,11,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:29;txt:'ID    ';flgs:36;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'C=D!C ';flgs:1;
     opclen:4;opc:(0,14,0,15,0);
     vara:0;varb:0;lft:42;rgt:43;leaf:0),
     (opcls:5;txt:'A=R4  ';flgs:1;
     opclen:3;opc:(1,1,4,0,0);
     vara:0;varb:0;lft:44;rgt:45;leaf:0),
     (opcls:4;txt:'LC(4) ';flgs:177;
     opclen:6;opc:(3,3,0,0,0);
     vara:3;varb:4;lft:46;rgt:47;leaf:0),
     (opcls:1;txt:'?B<=A ';flgs:3;
     opclen:3;opc:(8,0,8,0,0);
     vara:2;varb:0;lft:48;rgt:49;leaf:0),
     (opcls:5;txt:'ASRC  ';flgs:1;
     opclen:3;opc:(8,1,4,0,0);
     vara:0;varb:0;lft:50;rgt:51;leaf:0),
     (opcls:5;txt:'CR0EX ';flgs:1;
     opclen:3;opc:(1,2,8,0,0);
     vara:0;varb:0;lft:52;rgt:53;leaf:0),
     (opcls:5;txt:'R0=C  ';flgs:5;
     opclen:3;opc:(1,0,8,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?A=B  ';flgs:7;
     opclen:3;opc:(8,0,0,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'A=A!B ';flgs:5;
     opclen:4;opc:(0,14,0,8,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'ABEX  ';flgs:4;
     opclen:3;opc:(0,0,12,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'B=C   ';flgs:4;
     opclen:3;opc:(0,0,5,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'C=ST  ';flgs:5;
     opclen:2;opc:(0,9,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'D=D-C ';flgs:4;
     opclen:3;opc:(0,0,3,0,0);
     vara:3;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'LC(2) ';flgs:177;
     opclen:4;opc:(3,1,0,0,0);
     vara:3;varb:2;lft:55;rgt:56;leaf:0),
     (opcls:2;txt:'B=A+B ';flgs:0;
     opclen:3;opc:(0,0,8,0,0);
     vara:1;varb:0;lft:57;rgt:58;leaf:0),
     (opcls:5;txt:'R0=A  ';flgs:1;
     opclen:3;opc:(1,0,0,0,0);
     vara:0;varb:0;lft:59;rgt:60;leaf:0),
     (opcls:1;txt:'?C=A  ';flgs:3;
     opclen:3;opc:(8,0,2,0,0);
     vara:1;varb:0;lft:61;rgt:62;leaf:0),
     (opcls:4;txt:'D0=(2)';flgs:177;
     opclen:4;opc:(1,9,0,0,0);
     vara:3;varb:2;lft:63;rgt:64;leaf:0),
     (opcls:23;txt:'LIST  ';flgs:5;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'R4=C  ';flgs:5;
     opclen:3;opc:(1,0,12,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?A=0  ';flgs:7;
     opclen:3;opc:(8,0,8,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'A=R2  ';flgs:5;
     opclen:3;opc:(1,1,2,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'BUSCC ';flgs:5;
     opclen:3;opc:(8,0,11,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'D=D+C ';flgs:4;
     opclen:3;opc:(0,0,3,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'CON(4)';flgs:49;
     opclen:4;opc:(0,0,0,0,0);
     vara:1;varb:4;lft:66;rgt:67;leaf:0),
     (opcls:3;txt:'B=A!B ';flgs:1;
     opclen:4;opc:(0,14,0,12,0);
     vara:0;varb:0;lft:68;rgt:69;leaf:0),
     (opcls:5;txt:'R4=A  ';flgs:1;
     opclen:3;opc:(1,0,4,0,0);
     vara:0;varb:0;lft:70;rgt:71;leaf:0),
     (opcls:5;txt:'A=R0  ';flgs:1;
     opclen:3;opc:(1,1,0,0,0);
     vara:0;varb:0;lft:72;rgt:73;leaf:0),
     (opcls:5;txt:'BSRC  ';flgs:5;
     opclen:3;opc:(8,1,5,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'D=D!C ';flgs:5;
     opclen:4;opc:(0,14,0,11,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'RTNSXM';flgs:5;
     opclen:2;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'A=B   ';flgs:4;
     opclen:3;opc:(0,0,4,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'A=IN  ';flgs:1;
     opclen:3;opc:(8,0,2,0,0);
     vara:0;varb:0;lft:75;rgt:76;leaf:0),
     (opcls:9;txt:'?ST=0 ';flgs:35;
     opclen:3;opc:(8,6,0,0,0);
     vara:0;varb:0;lft:77;rgt:78;leaf:0),
     (opcls:4;txt:'GOTO  ';flgs:33;
     opclen:4;opc:(6,0,0,0,0);
     vara:2;varb:3;lft:79;rgt:80;leaf:0),
     (opcls:1;txt:'?C>=A ';flgs:7;
     opclen:3;opc:(8,0,10,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'A=C&A ';flgs:5;
     opclen:4;opc:(0,14,0,6,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=C+C ';flgs:4;
     opclen:3;opc:(0,0,6,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'ST=C  ';flgs:5;
     opclen:2;opc:(0,10,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CSRC  ';flgs:1;
     opclen:3;opc:(8,1,6,0,0);
     vara:0;varb:0;lft:82;rgt:83;leaf:0),
     (opcls:2;txt:'B=B-C ';flgs:0;
     opclen:3;opc:(0,0,1,0,0);
     vara:3;varb:0;lft:84;rgt:85;leaf:0),
     (opcls:5;txt:'SB=0  ';flgs:1;
     opclen:3;opc:(8,2,2,0,0);
     vara:0;varb:0;lft:86;rgt:87;leaf:0),
     (opcls:9;txt:'?ST#0 ';flgs:35;
     opclen:3;opc:(8,7,0,0,0);
     vara:0;varb:0;lft:88;rgt:89;leaf:0),
     (opcls:2;txt:'CBEX  ';flgs:0;
     opclen:3;opc:(0,0,13,0,0);
     vara:2;varb:0;lft:90;rgt:91;leaf:0),
     (opcls:12;txt:'D1=D1+';flgs:33;
     opclen:3;opc:(1,7,0,0,0);
     vara:0;varb:0;lft:92;rgt:93;leaf:0),
     (opcls:11;txt:'ST=1  ';flgs:33;
     opclen:3;opc:(8,5,0,0,0);
     vara:0;varb:0;lft:94;rgt:95;leaf:0),
     (opcls:1;txt:'?A<B  ';flgs:7;
     opclen:3;opc:(8,0,4,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:13;txt:'A=DAT0';flgs:36;
     opclen:4;opc:(1,5,2,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'C=R4  ';flgs:5;
     opclen:3;opc:(1,1,12,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CLRST ';flgs:5;
     opclen:2;opc:(0,8,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'D0=C  ';flgs:5;
     opclen:3;opc:(1,3,4,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'D=C   ';flgs:4;
     opclen:3;opc:(0,0,7,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'SR=0  ';flgs:5;
     opclen:3;opc:(8,2,4,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'B=B+C ';flgs:0;
     opclen:3;opc:(0,0,1,0,0);
     vara:1;varb:0;lft:97;rgt:98;leaf:0),
     (opcls:1;txt:'?C<A  ';flgs:3;
     opclen:3;opc:(8,0,6,0,0);
     vara:2;varb:0;lft:99;rgt:100;leaf:0),
     (opcls:5;txt:'D0=A  ';flgs:1;
     opclen:3;opc:(1,3,0,0,0);
     vara:0;varb:0;lft:101;rgt:102;leaf:0),
     (opcls:1;txt:'?A<=C ';flgs:7;
     opclen:3;opc:(8,0,10,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:13;txt:'A=DAT1';flgs:36;
     opclen:4;opc:(1,5,3,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'C=R2  ';flgs:5;
     opclen:3;opc:(1,1,10,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'REL(1)';flgs:37;
     opclen:1;opc:(0,0,0,0,0);
     vara:1;varb:1;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'C=R0  ';flgs:1;
     opclen:3;opc:(1,1,8,0,0);
     vara:0;varb:0;lft:104;rgt:105;leaf:0),
     (opcls:3;txt:'B=B!C ';flgs:1;
     opclen:4;opc:(0,14,0,9,0);
     vara:0;varb:0;lft:106;rgt:107;leaf:0),
     (opcls:5;txt:'DSRC  ';flgs:1;
     opclen:3;opc:(8,1,7,0,0);
     vara:0;varb:0;lft:108;rgt:109;leaf:0),
     (opcls:2;txt:'A=A-C ';flgs:4;
     opclen:3;opc:(0,0,10,0,0);
     vara:3;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=B   ';flgs:4;
     opclen:3;opc:(0,0,9,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:12;txt:'D1=D1-';flgs:37;
     opclen:3;opc:(1,12,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'OUT=C ';flgs:5;
     opclen:3;opc:(8,0,1,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=B+C ';flgs:0;
     opclen:3;opc:(0,0,9,0,0);
     vara:1;varb:0;lft:111;rgt:112;leaf:0),
     (opcls:2;txt:'A=A+C ';flgs:0;
     opclen:3;opc:(0,0,10,0,0);
     vara:1;varb:0;lft:113;rgt:114;leaf:0),
     (opcls:5;txt:'C=IN  ';flgs:1;
     opclen:3;opc:(8,0,3,0,0);
     vara:0;varb:0;lft:115;rgt:116;leaf:0),
     (opcls:1;txt:'?D>C  ';flgs:7;
     opclen:3;opc:(8,0,3,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'A=B&A ';flgs:5;
     opclen:4;opc:(0,14,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'C=C&A ';flgs:5;
     opclen:4;opc:(0,14,0,2,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:35;txt:'TOKEN ';flgs:36;
     opclen:2;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'C=ID  ';flgs:1;
     opclen:3;opc:(8,0,6,0,0);
     vara:0;varb:0;lft:118;rgt:119;leaf:0),
     (opcls:2;txt:'B=A   ';flgs:0;
     opclen:3;opc:(0,0,8,0,0);
     vara:2;varb:0;lft:120;rgt:121;leaf:0),
     (opcls:10;txt:'P=    ';flgs:33;
     opclen:2;opc:(2,0,0,0,0);
     vara:0;varb:0;lft:122;rgt:123;leaf:0),
     (opcls:1;txt:'?B>=C ';flgs:3;
     opclen:3;opc:(8,0,9,0,0);
     vara:2;varb:0;lft:124;rgt:125;leaf:0),
     (opcls:13;txt:'C=DAT0';flgs:32;
     opclen:4;opc:(1,5,6,0,0);
     vara:0;varb:0;lft:126;rgt:127;leaf:0),
     (opcls:14;txt:'NIBHEX';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:1;varb:14;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'RESET ';flgs:5;
     opclen:3;opc:(8,0,10,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?A#B  ';flgs:7;
     opclen:3;opc:(8,0,4,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'A=A!C ';flgs:5;
     opclen:4;opc:(0,14,0,14,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'C=B!C ';flgs:5;
     opclen:4;opc:(0,14,0,13,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'B=B&A ';flgs:1;
     opclen:4;opc:(0,14,0,4,0);
     vara:0;varb:0;lft:129;rgt:130;leaf:0),
     (opcls:6;txt:'?XM=0 ';flgs:3;
     opclen:3;opc:(8,3,1,0,0);
     vara:0;varb:0;lft:131;rgt:132;leaf:0),
     (opcls:2;txt:'D=D+D ';flgs:0;
     opclen:3;opc:(0,0,7,0,0);
     vara:1;varb:0;lft:133;rgt:134;leaf:0),
     (opcls:1;txt:'?C#A  ';flgs:3;
     opclen:3;opc:(8,0,6,0,0);
     vara:1;varb:0;lft:135;rgt:136;leaf:0),
     (opcls:2;txt:'A=-A-1';flgs:4;
     opclen:3;opc:(0,0,12,0,0);
     vara:4;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:13;txt:'C=DAT1';flgs:36;
     opclen:4;opc:(1,5,7,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'OUT=CS';flgs:5;
     opclen:3;opc:(8,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?A#0  ';flgs:7;
     opclen:3;opc:(8,0,12,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=C-D ';flgs:0;
     opclen:3;opc:(0,0,11,0,0);
     vara:3;varb:0;lft:138;rgt:139;leaf:0),
     (opcls:2;txt:'C=A   ';flgs:0;
     opclen:3;opc:(0,0,6,0,0);
     vara:2;varb:0;lft:140;rgt:141;leaf:0),
     (opcls:34;txt:'KEY   ';flgs:32;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:142;rgt:143;leaf:0),
     (opcls:2;txt:'A=0   ';flgs:4;
     opclen:3;opc:(0,0,0,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=A-C ';flgs:4;
     opclen:3;opc:(0,0,14,0,0);
     vara:3;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'CON(5)';flgs:53;
     opclen:5;opc:(0,0,0,0,0);
     vara:1;varb:5;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'ACEX  ';flgs:0;
     opclen:3;opc:(0,0,14,0,0);
     vara:2;varb:0;lft:145;rgt:146;leaf:0),
     (opcls:6;txt:'?SB=0 ';flgs:3;
     opclen:3;opc:(8,3,2,0,0);
     vara:0;varb:0;lft:147;rgt:148;leaf:0),
     (opcls:30;txt:'MSG   ';flgs:33;
     opclen:4;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:149;rgt:150;leaf:0),
     (opcls:1;txt:'?C>=B ';flgs:3;
     opclen:3;opc:(8,0,13,0,0);
     vara:2;varb:0;lft:151;rgt:152;leaf:0),
     (opcls:9;txt:'?ST=1 ';flgs:35;
     opclen:3;opc:(8,7,0,0,0);
     vara:0;varb:0;lft:153;rgt:154;leaf:0),
     (opcls:2;txt:'C=C+D ';flgs:0;
     opclen:3;opc:(0,0,11,0,0);
     vara:1;varb:0;lft:155;rgt:156;leaf:0),
     (opcls:5;txt:'R1=C  ';flgs:5;
     opclen:3;opc:(1,0,9,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?C<=A ';flgs:7;
     opclen:3;opc:(8,0,14,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?D=C  ';flgs:7;
     opclen:3;opc:(8,0,3,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:6;txt:'?SR=0 ';flgs:7;
     opclen:3;opc:(8,3,4,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'A=-A  ';flgs:4;
     opclen:3;opc:(0,0,8,0,0);
     vara:4;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=A+C ';flgs:4;
     opclen:3;opc:(0,0,2,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'D1=(2)';flgs:177;
     opclen:4;opc:(1,13,0,0,0);
     vara:3;varb:2;lft:158;rgt:159;leaf:0),
     (opcls:2;txt:'C=-C-1';flgs:0;
     opclen:3;opc:(0,0,14,0,0);
     vara:4;varb:0;lft:160;rgt:161;leaf:0),
     (opcls:31;txt:'POLL  ';flgs:33;
     opclen:5;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:162;rgt:163;leaf:0),
     (opcls:9;txt:'?ST#1 ';flgs:35;
     opclen:3;opc:(8,6,0,0,0);
     vara:0;varb:0;lft:164;rgt:165;leaf:0),
     (opcls:3;txt:'C=C!D ';flgs:1;
     opclen:4;opc:(0,14,0,15,0);
     vara:0;varb:0;lft:166;rgt:167;leaf:0),
     (opcls:2;txt:'D=C-D ';flgs:4;
     opclen:3;opc:(0,0,15,0,0);
     vara:3;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'R1=A  ';flgs:5;
     opclen:3;opc:(1,0,1,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?B=0  ';flgs:7;
     opclen:3;opc:(8,0,9,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'B=0   ';flgs:4;
     opclen:3;opc:(0,0,1,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'C=A!C ';flgs:5;
     opclen:4;opc:(0,14,0,10,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:21;txt:'END   ';flgs:0;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:169;rgt:170;leaf:0),
     (opcls:2;txt:'BCEX  ';flgs:0;
     opclen:3;opc:(0,0,13,0,0);
     vara:2;varb:0;lft:171;rgt:172;leaf:0),
     (opcls:4;txt:'REL(2)';flgs:33;
     opclen:2;opc:(0,0,0,0,0);
     vara:1;varb:2;lft:173;rgt:174;leaf:0),
     (opcls:3;txt:'B=C&B ';flgs:5;
     opclen:4;opc:(0,14,0,1,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'D=C+D ';flgs:4;
     opclen:3;opc:(0,0,3,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:15;txt:'LCHEX ';flgs:4;
     opclen:2;opc:(3,0,0,0,0);
     vara:3;varb:2;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:10;txt:'C=P   ';flgs:33;
     opclen:4;opc:(8,0,12,0,0);
     vara:0;varb:0;lft:176;rgt:177;leaf:0),
     (opcls:2;txt:'C=-C  ';flgs:0;
     opclen:3;opc:(0,0,10,0,0);
     vara:4;varb:0;lft:178;rgt:179;leaf:0),
     (opcls:3;txt:'D=C!D ';flgs:5;
     opclen:4;opc:(0,14,0,11,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'AD1EX ';flgs:5;
     opclen:3;opc:(1,3,3,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=0   ';flgs:4;
     opclen:3;opc:(0,0,2,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'D1=C  ';flgs:1;
     opclen:3;opc:(1,3,5,0,0);
     vara:0;varb:0;lft:181;rgt:182;leaf:0),
     (opcls:2;txt:'ASL   ';flgs:0;
     opclen:3;opc:(0,0,0,0,0);
     vara:4;varb:0;lft:183;rgt:184;leaf:0),
     (opcls:4;txt:'GOLONG';flgs:33;
     opclen:6;opc:(8,12,0,0,0);
     vara:3;varb:4;lft:185;rgt:186;leaf:0),
     (opcls:1;txt:'?D<C  ';flgs:7;
     opclen:3;opc:(8,0,7,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'C=C&B ';flgs:5;
     opclen:4;opc:(0,14,0,5,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:39;txt:'ENDTXT';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:28;txt:'LEX   ';flgs:32;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:188;rgt:189;leaf:0),
     (opcls:5;txt:'D1=A  ';flgs:1;
     opclen:3;opc:(1,3,1,0,0);
     vara:0;varb:0;lft:190;rgt:191;leaf:0),
     (opcls:17;txt:'NIBASC';flgs:36;
     opclen:0;opc:(0,0,0,0,0);
     vara:1;varb:14;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?B<=C ';flgs:7;
     opclen:3;opc:(8,0,13,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'D=0   ';flgs:4;
     opclen:3;opc:(0,0,3,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'D0=(4)';flgs:177;
     opclen:6;opc:(1,10,0,0,0);
     vara:3;varb:4;lft:193;rgt:194;leaf:0),
     (opcls:1;txt:'?C>D  ';flgs:3;
     opclen:3;opc:(8,0,7,0,0);
     vara:2;varb:0;lft:195;rgt:196;leaf:0),
     (opcls:20;txt:'EJECT ';flgs:1;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:197;rgt:198;leaf:0),
     (opcls:1;txt:'?A>C  ';flgs:7;
     opclen:3;opc:(8,0,6,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'BSL   ';flgs:4;
     opclen:3;opc:(0,0,1,0,0);
     vara:4;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'DCEX  ';flgs:4;
     opclen:3;opc:(0,0,15,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CD1EX ';flgs:1;
     opclen:3;opc:(1,3,7,0,0);
     vara:0;varb:0;lft:200;rgt:201;leaf:0),
     (opcls:5;txt:'AD0EX ';flgs:1;
     opclen:3;opc:(1,3,2,0,0);
     vara:0;varb:0;lft:202;rgt:203;leaf:0),
     (opcls:5;txt:'NOP5  ';flgs:1;
     opclen:5;opc:(6,4,0,0,0);
     vara:0;varb:0;lft:204;rgt:205;leaf:0),
     (opcls:1;txt:'?C>B  ';flgs:7;
     opclen:3;opc:(8,0,5,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'C=RSTK';flgs:5;
     opclen:2;opc:(0,7,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:13;txt:'DAT1=A';flgs:36;
     opclen:4;opc:(1,5,1,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'SHUTDN';flgs:5;
     opclen:3;opc:(8,0,7,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'AD1XS ';flgs:1;
     opclen:3;opc:(1,3,11,0,0);
     vara:0;varb:0;lft:207;rgt:208;leaf:0),
     (opcls:1;txt:'?D#C  ';flgs:3;
     opclen:3;opc:(8,0,7,0,0);
     vara:1;varb:0;lft:209;rgt:210;leaf:0),
     (opcls:2;txt:'CSL   ';flgs:0;
     opclen:3;opc:(0,0,2,0,0);
     vara:4;varb:0;lft:211;rgt:212;leaf:0),
     (opcls:1;txt:'?C<=B ';flgs:7;
     opclen:3;opc:(8,0,9,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'A=A&B ';flgs:5;
     opclen:4;opc:(0,14,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'C=D&C ';flgs:5;
     opclen:4;opc:(0,14,0,7,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'NOP3  ';flgs:5;
     opclen:3;opc:(4,2,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:32;txt:'ENTRY ';flgs:33;
     opclen:8;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:214;rgt:215;leaf:0),
     (opcls:5;txt:'C+P+1 ';flgs:1;
     opclen:3;opc:(8,0,9,0,0);
     vara:0;varb:0;lft:216;rgt:217;leaf:0),
     (opcls:5;txt:'RTN   ';flgs:5;
     opclen:2;opc:(0,1,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?B#0  ';flgs:7;
     opclen:3;opc:(8,0,13,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:13;txt:'DAT1=C';flgs:36;
     opclen:4;opc:(1,5,5,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'LC(5) ';flgs:177;
     opclen:7;opc:(3,4,0,0,0);
     vara:3;varb:5;lft:219;rgt:220;leaf:0),
     (opcls:19;txt:'BSS   ';flgs:32;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:221;rgt:222;leaf:0),
     (opcls:5;txt:'RTNCC ';flgs:1;
     opclen:2;opc:(0,3,0,0,0);
     vara:0;varb:0;lft:223;rgt:224;leaf:0),
     (opcls:1;txt:'?C=D  ';flgs:3;
     opclen:3;opc:(8,0,3,0,0);
     vara:1;varb:0;lft:225;rgt:226;leaf:0),
     (opcls:3;txt:'D=D&C ';flgs:1;
     opclen:4;opc:(0,14,0,3,0);
     vara:0;varb:0;lft:227;rgt:228;leaf:0),
     (opcls:4;txt:'REL(3)';flgs:37;
     opclen:3;opc:(0,0,0,0,0);
     vara:1;varb:3;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'RTNSC ';flgs:5;
     opclen:2;opc:(0,2,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?A=C  ';flgs:7;
     opclen:3;opc:(8,0,2,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'B=A&B ';flgs:5;
     opclen:4;opc:(0,14,0,4,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'CON(1)';flgs:53;
     opclen:1;opc:(0,0,0,0,0);
     vara:1;varb:1;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'DSL   ';flgs:4;
     opclen:3;opc:(0,0,3,0,0);
     vara:4;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CD0EX ';flgs:1;
     opclen:3;opc:(1,3,6,0,0);
     vara:0;varb:0;lft:230;rgt:231;leaf:0),
     (opcls:5;txt:'A=R3  ';flgs:1;
     opclen:3;opc:(1,1,3,0,0);
     vara:0;varb:0;lft:232;rgt:233;leaf:0),
     (opcls:5;txt:'R2=C  ';flgs:1;
     opclen:3;opc:(1,0,10,0,0);
     vara:0;varb:0;lft:234;rgt:235;leaf:0),
     (opcls:1;txt:'?C=B  ';flgs:7;
     opclen:3;opc:(8,0,1,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'ASRB  ';flgs:5;
     opclen:3;opc:(8,1,12,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'LC(3) ';flgs:181;
     opclen:5;opc:(3,2,0,0,0);
     vara:3;varb:3;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CD1XS ';flgs:1;
     opclen:3;opc:(1,3,15,0,0);
     vara:0;varb:0;lft:237;rgt:238;leaf:0),
     (opcls:5;txt:'AR4EX ';flgs:1;
     opclen:3;opc:(1,2,4,0,0);
     vara:0;varb:0;lft:239;rgt:240;leaf:0),
     (opcls:4;txt:'LC(1) ';flgs:177;
     opclen:3;opc:(3,0,0,0,0);
     vara:3;varb:1;lft:241;rgt:242;leaf:0),
     (opcls:5;txt:'A=R1  ';flgs:1;
     opclen:3;opc:(1,1,1,0,0);
     vara:0;varb:0;lft:243;rgt:244;leaf:0),
     (opcls:2;txt:'ASR   ';flgs:4;
     opclen:3;opc:(0,0,4,0,0);
     vara:4;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CLRHST';flgs:5;
     opclen:3;opc:(8,2,15,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'R2=A  ';flgs:5;
     opclen:3;opc:(1,0,2,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?C=0  ';flgs:7;
     opclen:3;opc:(8,0,10,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'AD0XS ';flgs:5;
     opclen:3;opc:(1,3,10,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:16;txt:'D0=HEX';flgs:1;
     opclen:4;opc:(1,9,0,0,0);
     vara:3;varb:2;lft:246;rgt:247;leaf:0),
     (opcls:38;txt:'CHAIN ';flgs:33;
     opclen:12;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:248;rgt:249;leaf:0),
     (opcls:4;txt:'GOSUB ';flgs:101;
     opclen:4;opc:(7,0,0,0,0);
     vara:2;varb:3;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'BSRB  ';flgs:5;
     opclen:3;opc:(8,1,13,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CONFIG';flgs:5;
     opclen:3;opc:(8,0,5,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'BSR   ';flgs:0;
     opclen:3;opc:(0,0,5,0,0);
     vara:4;varb:0;lft:251;rgt:252;leaf:0),
     (opcls:1;txt:'?C<D  ';flgs:3;
     opclen:3;opc:(8,0,3,0,0);
     vara:2;varb:0;lft:253;rgt:254;leaf:0),
     (opcls:4;txt:'D0=(5)';flgs:177;
     opclen:7;opc:(1,11,0,0,0);
     vara:3;varb:5;lft:255;rgt:256;leaf:0),
     (opcls:1;txt:'?A<C  ';flgs:7;
     opclen:3;opc:(8,0,2,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'B=B&C ';flgs:5;
     opclen:4;opc:(0,14,0,1,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:10;txt:'CPEX  ';flgs:37;
     opclen:4;opc:(8,0,15,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'CDEX  ';flgs:0;
     opclen:3;opc:(0,0,15,0,0);
     vara:2;varb:0;lft:258;rgt:259;leaf:0),
     (opcls:2;txt:'A=C+A ';flgs:0;
     opclen:3;opc:(0,0,10,0,0);
     vara:1;varb:0;lft:260;rgt:261;leaf:0),
     (opcls:11;txt:'ST=0  ';flgs:33;
     opclen:3;opc:(8,4,0,0,0);
     vara:0;varb:0;lft:262;rgt:263;leaf:0),
     (opcls:1;txt:'?C<B  ';flgs:7;
     opclen:3;opc:(8,0,1,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'C=R3  ';flgs:5;
     opclen:3;opc:(1,1,11,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CSRB  ';flgs:5;
     opclen:3;opc:(8,1,14,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'UNCNFG';flgs:5;
     opclen:3;opc:(8,0,4,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CD0XS ';flgs:1;
     opclen:3;opc:(1,3,14,0,0);
     vara:0;varb:0;lft:265;rgt:266;leaf:0),
     (opcls:5;txt:'AR3EX ';flgs:1;
     opclen:3;opc:(1,2,3,0,0);
     vara:0;varb:0;lft:267;rgt:268;leaf:0),
     (opcls:2;txt:'CSR   ';flgs:0;
     opclen:3;opc:(0,0,6,0,0);
     vara:4;varb:0;lft:269;rgt:270;leaf:0),
     (opcls:3;txt:'A=A&C ';flgs:1;
     opclen:4;opc:(0,14,0,6,0);
     vara:0;varb:0;lft:271;rgt:272;leaf:0),
     (opcls:5;txt:'C=R1  ';flgs:1;
     opclen:3;opc:(1,1,9,0,0);
     vara:0;varb:0;lft:273;rgt:274;leaf:0),
     (opcls:5;txt:'CR4EX ';flgs:5;
     opclen:3;opc:(1,2,12,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'D=D-1 ';flgs:4;
     opclen:3;opc:(0,0,15,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?C>=D ';flgs:7;
     opclen:3;opc:(8,0,15,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'A=C!A ';flgs:5;
     opclen:4;opc:(0,14,0,14,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'C=B&C ';flgs:5;
     opclen:4;opc:(0,14,0,5,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'D=D+1 ';flgs:0;
     opclen:3;opc:(0,0,7,0,0);
     vara:3;varb:0;lft:276;rgt:277;leaf:0),
     (opcls:12;txt:'D0=D0+';flgs:33;
     opclen:3;opc:(1,6,0,0,0);
     vara:0;varb:0;lft:278;rgt:279;leaf:0),
     (opcls:4;txt:'GOSUBL';flgs:97;
     opclen:6;opc:(8,14,0,0,0);
     vara:3;varb:4;lft:280;rgt:281;leaf:0),
     (opcls:5;txt:'D0=CS ';flgs:1;
     opclen:3;opc:(1,3,12,0,0);
     vara:0;varb:0;lft:282;rgt:283;leaf:0),
     (opcls:4;txt:'D1=(4)';flgs:181;
     opclen:6;opc:(1,14,0,0,0);
     vara:3;varb:4;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'DSRB  ';flgs:5;
     opclen:3;opc:(8,1,15,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'INTON ';flgs:5;
     opclen:4;opc:(8,0,8,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?B>C  ';flgs:7;
     opclen:3;opc:(8,0,1,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'D0=AS ';flgs:1;
     opclen:3;opc:(1,3,8,0,0);
     vara:0;varb:0;lft:285;rgt:286;leaf:0),
     (opcls:2;txt:'A=B-A ';flgs:0;
     opclen:3;opc:(0,0,12,0,0);
     vara:3;varb:0;lft:287;rgt:288;leaf:0),
     (opcls:5;txt:'MP=0  ';flgs:1;
     opclen:3;opc:(8,2,8,0,0);
     vara:0;varb:0;lft:289;rgt:290;leaf:0),
     (opcls:1;txt:'?B>A  ';flgs:3;
     opclen:3;opc:(8,0,4,0,0);
     vara:2;varb:0;lft:291;rgt:292;leaf:0),
     (opcls:2;txt:'C=C-A ';flgs:0;
     opclen:3;opc:(0,0,2,0,0);
     vara:3;varb:0;lft:293;rgt:294;leaf:0),
     (opcls:2;txt:'DSR   ';flgs:4;
     opclen:3;opc:(0,0,7,0,0);
     vara:4;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'REL(4)';flgs:37;
     opclen:4;opc:(0,0,0,0,0);
     vara:1;varb:4;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?A#C  ';flgs:7;
     opclen:3;opc:(8,0,6,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?C#D  ';flgs:7;
     opclen:3;opc:(8,0,7,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=C-1 ';flgs:4;
     opclen:3;opc:(0,0,14,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'CON(2)';flgs:53;
     opclen:2;opc:(0,0,0,0,0);
     vara:1;varb:2;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=C+1 ';flgs:0;
     opclen:3;opc:(0,0,6,0,0);
     vara:3;varb:0;lft:296;rgt:297;leaf:0),
     (opcls:2;txt:'A=B+A ';flgs:0;
     opclen:3;opc:(0,0,0,0,0);
     vara:1;varb:0;lft:298;rgt:299;leaf:0),
     (opcls:12;txt:'D0=D0-';flgs:33;
     opclen:3;opc:(1,8,0,0,0);
     vara:0;varb:0;lft:300;rgt:301;leaf:0),
     (opcls:1;txt:'?D>=C ';flgs:3;
     opclen:3;opc:(8,0,11,0,0);
     vara:2;varb:0;lft:302;rgt:303;leaf:0),
     (opcls:36;txt:'BIN   ';flgs:36;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'C=C+A ';flgs:4;
     opclen:3;opc:(0,0,2,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'GOVLNG';flgs:53;
     opclen:7;opc:(8,13,0,0,0);
     vara:3;varb:5;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?C#B  ';flgs:7;
     opclen:3;opc:(8,0,5,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'C=C!A ';flgs:1;
     opclen:4;opc:(0,14,0,10,0);
     vara:0;varb:0;lft:305;rgt:306;leaf:0),
     (opcls:2;txt:'B=B-1 ';flgs:0;
     opclen:3;opc:(0,0,13,0,0);
     vara:1;varb:0;lft:307;rgt:308;leaf:0),
     (opcls:5;txt:'CR3EX ';flgs:1;
     opclen:3;opc:(1,2,11,0,0);
     vara:0;varb:0;lft:309;rgt:310;leaf:0),
     (opcls:3;txt:'A=B!A ';flgs:1;
     opclen:4;opc:(0,14,0,8,0);
     vara:0;varb:0;lft:311;rgt:312;leaf:0),
     (opcls:3;txt:'C=A&C ';flgs:1;
     opclen:4;opc:(0,14,0,2,0);
     vara:0;varb:0;lft:313;rgt:314;leaf:0),
     (opcls:3;txt:'C=C&D ';flgs:5;
     opclen:4;opc:(0,14,0,7,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'XM=0  ';flgs:5;
     opclen:3;opc:(8,2,1,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?C#0  ';flgs:7;
     opclen:3;opc:(8,0,14,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'AR2EX ';flgs:5;
     opclen:3;opc:(1,2,2,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'B=B-A ';flgs:4;
     opclen:3;opc:(0,0,8,0,0);
     vara:3;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'B=B+1 ';flgs:0;
     opclen:3;opc:(0,0,5,0,0);
     vara:3;varb:0;lft:316;rgt:317;leaf:0),
     (opcls:1;txt:'?B=C  ';flgs:3;
     opclen:3;opc:(8,0,1,0,0);
     vara:1;varb:0;lft:318;rgt:319;leaf:0),
     (opcls:37;txt:'FORTH ';flgs:0;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:320;rgt:321;leaf:0),
     (opcls:1;txt:'?A>=B ';flgs:7;
     opclen:3;opc:(8,0,8,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'B=-B-1';flgs:4;
     opclen:3;opc:(0,0,13,0,0);
     vara:4;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'B=B+A ';flgs:4;
     opclen:3;opc:(0,0,8,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'GOC   ';flgs:37;
     opclen:3;opc:(4,0,0,0,0);
     vara:2;varb:2;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'B=B!A ';flgs:1;
     opclen:4;opc:(0,14,0,12,0);
     vara:0;varb:0;lft:323;rgt:324;leaf:0),
     (opcls:8;txt:'?P=   ';flgs:35;
     opclen:3;opc:(8,9,0,0,0);
     vara:0;varb:0;lft:325;rgt:326;leaf:0),
     (opcls:5;txt:'R3=C  ';flgs:1;
     opclen:3;opc:(1,0,11,0,0);
     vara:0;varb:0;lft:327;rgt:328;leaf:0),
     (opcls:1;txt:'?B=A  ';flgs:7;
     opclen:3;opc:(8,0,0,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'A=A-1 ';flgs:4;
     opclen:3;opc:(0,0,12,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:3;txt:'D=C&D ';flgs:5;
     opclen:4;opc:(0,14,0,3,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:18;txt:'LCASC ';flgs:32;
     opclen:2;opc:(3,0,0,0,0);
     vara:3;varb:2;lft:330;rgt:331;leaf:0),
     (opcls:2;txt:'B=-B  ';flgs:0;
     opclen:3;opc:(0,0,9,0,0);
     vara:4;varb:0;lft:332;rgt:333;leaf:0),
     (opcls:25;txt:'STITLE';flgs:1;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:334;rgt:335;leaf:0),
     (opcls:2;txt:'A=A+1 ';flgs:0;
     opclen:3;opc:(0,0,4,0,0);
     vara:3;varb:0;lft:336;rgt:337;leaf:0),
     (opcls:5;txt:'INTOFF';flgs:1;
     opclen:4;opc:(8,0,8,15,0);
     vara:0;varb:0;lft:338;rgt:339;leaf:0),
     (opcls:5;txt:'R3=A  ';flgs:5;
     opclen:3;opc:(1,0,3,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:26;txt:'WORD  ';flgs:36;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?D=0  ';flgs:7;
     opclen:3;opc:(8,0,11,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'A=A+A ';flgs:4;
     opclen:3;opc:(0,0,4,0,0);
     vara:1;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'BAEX  ';flgs:4;
     opclen:3;opc:(0,0,12,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:0;txt:'      ';flgs:4;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CR2EX ';flgs:1;
     opclen:3;opc:(1,2,10,0,0);
     vara:0;varb:0;lft:341;rgt:342;leaf:0),
     (opcls:5;txt:'ASLC  ';flgs:1;
     opclen:3;opc:(8,1,0,0,0);
     vara:0;varb:0;lft:343;rgt:344;leaf:0),
     (opcls:2;txt:'D=-D-1';flgs:0;
     opclen:3;opc:(0,0,15,0,0);
     vara:4;varb:0;lft:345;rgt:346;leaf:0),
     (opcls:1;txt:'?C<=D ';flgs:3;
     opclen:3;opc:(8,0,11,0,0);
     vara:2;varb:0;lft:347;rgt:348;leaf:0),
     (opcls:2;txt:'B=C-B ';flgs:4;
     opclen:3;opc:(0,0,13,0,0);
     vara:3;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:16;txt:'D1=HEX';flgs:5;
     opclen:4;opc:(1,13,0,0,0);
     vara:3;varb:2;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'P=P-1 ';flgs:5;
     opclen:2;opc:(0,13,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?B>=A ';flgs:7;
     opclen:3;opc:(8,0,12,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'AR1EX ';flgs:5;
     opclen:3;opc:(1,2,1,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'D1=(5)';flgs:177;
     opclen:7;opc:(1,15,0,0,0);
     vara:3;varb:5;lft:350;rgt:351;leaf:0),
     (opcls:2;txt:'B=C+B ';flgs:0;
     opclen:3;opc:(0,0,1,0,0);
     vara:1;varb:0;lft:352;rgt:353;leaf:0),
     (opcls:5;txt:'P=P+1 ';flgs:5;
     opclen:2;opc:(0,12,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?B<C  ';flgs:7;
     opclen:3;opc:(8,0,5,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'CAEX  ';flgs:4;
     opclen:3;opc:(0,0,14,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:2;txt:'D=-D  ';flgs:0;
     opclen:3;opc:(0,0,11,0,0);
     vara:4;varb:0;lft:355;rgt:356;leaf:0),
     (opcls:2;txt:'C=C-B ';flgs:0;
     opclen:3;opc:(0,0,9,0,0);
     vara:3;varb:0;lft:357;rgt:358;leaf:0),
     (opcls:5;txt:'RSTK=C';flgs:1;
     opclen:2;opc:(0,6,0,0,0);
     vara:0;varb:0;lft:359;rgt:360;leaf:0),
     (opcls:3;txt:'B=C!B ';flgs:1;
     opclen:4;opc:(0,14,0,9,0);
     vara:0;varb:0;lft:361;rgt:362;leaf:0),
     (opcls:4;txt:'CON(3)';flgs:53;
     opclen:3;opc:(0,0,0,0,0);
     vara:1;varb:3;lft:0;rgt:0;leaf:1),
     (opcls:4;txt:'REL(5)';flgs:37;
     opclen:5;opc:(0,0,0,0,0);
     vara:1;varb:5;lft:0;rgt:0;leaf:1),
     (opcls:24;txt:'TITLE ';flgs:5;
     opclen:0;opc:(0,0,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?B<A  ';flgs:7;
     opclen:3;opc:(8,0,0,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'BSLC  ';flgs:5;
     opclen:3;opc:(8,1,1,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'SETHEX';flgs:1;
     opclen:2;opc:(0,4,0,0,0);
     vara:0;varb:0;lft:364;rgt:365;leaf:0),
     (opcls:2;txt:'C=C+B ';flgs:0;
     opclen:3;opc:(0,0,9,0,0);
     vara:1;varb:0;lft:366;rgt:367;leaf:0),
     (opcls:5;txt:'SREQ? ';flgs:5;
     opclen:3;opc:(8,0,14,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:1;txt:'?D<=C ';flgs:7;
     opclen:3;opc:(8,0,15,0,0);
     vara:2;varb:0;lft:0;rgt:0;leaf:1),
     (opcls:5;txt:'CSTEX ';flgs:5;
     opclen:2;opc:(0,11,0,0,0);
     vara:0;varb:0;lft:0;rgt:0;leaf:1));
type       SFILLTYP= (BFILL,ZFILL);

       STRING7   = string[7];
       STRING40  = string[40];
       STRING10  = string[10];
       STRING96  = string[96];
       STRING50  = string[50];
       STRING80  = string[80];

       LREF    = ^lineref;
       LINEREF = record
                   LINENO: integer;
                   NEXTREF: lref
                   end;

       REF= ^sytentry;

       SYTENTRY= record
                 NAME    : STRING7;
                 VALUE   : LongInt;
                 TYP     : syttyp;
                 FIRSTREF: lref;
                 LASTREF : lref;
                 LEFT    : ref;
                 RIGHT   : ref
                 end;

       entrytype =  record
                       E_Name: string7;
                       E_Value : LongInt;
                     end;

type     entryvector= array[1..2000] of entrytype; 
const N_Entries:integer= 1992;
      Ext_Entry:entryvector= (
   (E_Name:'=#CK   ';E_Value:13142),
   (E_Name:'=-CHAR ';E_Value:86653),
   (E_Name:'=-LINE ';E_Value:86645),
   (E_Name:'=1/X15 ';E_Value:49982),
   (E_Name:'=?PRFI+';E_Value:95104),
   (E_Name:'=?PRFIL';E_Value:95102),
   (E_Name:'=A-MULT';E_Value:111433),
   (E_Name:'=ACCEPT';E_Value:17679),
   (E_Name:'=ACOS12';E_Value:56275),
   (E_Name:'=ACOS15';E_Value:56279),
   (E_Name:'=ACTIVE';E_Value:193960),
   (E_Name:'=AD15M ';E_Value:50022),
   (E_Name:'=AD15S ';E_Value:57757),
   (E_Name:'=AD15s ';E_Value:50025),
   (E_Name:'=AD2-12';E_Value:50015),
   (E_Name:'=AD2-15';E_Value:50019),
   (E_Name:'=ADDF  ';E_Value:50034),
   (E_Name:'=ADDONE';E_Value:49968),
   (E_Name:'=ADDP  ';E_Value:14851),
   (E_Name:'=ADDRCK';E_Value:116133),
   (E_Name:'=ADDRSS';E_Value:62759),
   (E_Name:'=ADHEAD';E_Value:98743),
   (E_Name:'=ADJA  ';E_Value:75930),
   (E_Name:'=ADJN  ';E_Value:75813),
   (E_Name:'=ADRS40';E_Value:62763),
   (E_Name:'=ADRS50';E_Value:62801),
   (E_Name:'=ADRS80';E_Value:62823),
   (E_Name:'=ADRSUB';E_Value:62671),
   (E_Name:'=ALINFO';E_Value:5425),
   (E_Name:'=ALLDUN';E_Value:19439),
   (E_Name:'=ALMSRV';E_Value:75133),
   (E_Name:'=ALRM1 ';E_Value:194329),
   (E_Name:'=ALRM2 ';E_Value:194341),
   (E_Name:'=ALRM3 ';E_Value:194353),
   (E_Name:'=ALRM4 ';E_Value:194365),
   (E_Name:'=ALRM5 ';E_Value:194377),
   (E_Name:'=ALRM6 ';E_Value:194389),
   (E_Name:'=ANN1.5';E_Value:188673),
   (E_Name:'=ANNAD1';E_Value:188672),
   (E_Name:'=ANNAD2';E_Value:188674),
   (E_Name:'=ANNAD3';E_Value:189260),
   (E_Name:'=ANNAD4';E_Value:189262),
   (E_Name:'=ARG12 ';E_Value:54907),
   (E_Name:'=ARG15 ';E_Value:54911),
   (E_Name:'=ARGERR';E_Value:48921),
   (E_Name:'=ARGF  ';E_Value:54948),
   (E_Name:'=ARGPR+';E_Value:59627),
   (E_Name:'=ARGPRP';E_Value:59631),
   (E_Name:'=ARGST-';E_Value:59664),
   (E_Name:'=ARGSTA';E_Value:59660),
   (E_Name:'=ARITH ';E_Value:25056),
   (E_Name:'=ARRYCK';E_Value:13930),
   (E_Name:'=ARYDC ';E_Value:20856),
   (E_Name:'=ARYELM';E_Value:46503),
   (E_Name:'=ARYSIZ';E_Value:46619),
   (E_Name:'=ASCICK';E_Value:20814),
   (E_Name:'=ASCII ';E_Value:1947),
   (E_Name:'=ASIN12';E_Value:56264),
   (E_Name:'=ASIN15';E_Value:56268),
   (E_Name:'=ASLW3 ';E_Value:60705),
   (E_Name:'=ASLW4 ';E_Value:60702),
   (E_Name:'=ASLW5 ';E_Value:60699),
   (E_Name:'=ASNMNT';E_Value:62944),
   (E_Name:'=ASRW3 ';E_Value:60688),
   (E_Name:'=ASRW4 ';E_Value:60685),
   (E_Name:'=ASRW5 ';E_Value:60682),
   (E_Name:'=ATAN15';E_Value:56254),
   (E_Name:'=ATNCLR';E_Value:1296),
   (E_Name:'=ATNDIS';E_Value:193601),
   (E_Name:'=ATNFLG';E_Value:193602),
   (E_Name:'=AUTINC';E_Value:194251),
   (E_Name:'=AVE=C ';E_Value:101307),
   (E_Name:'=AVE=D1';E_Value:101304),
   (E_Name:'=AVM2DS';E_Value:7169),
   (E_Name:'=AVMEME';E_Value:193945),
   (E_Name:'=AVMEMS';E_Value:193940),
   (E_Name:'=AVS2DS';E_Value:38664),
   (E_Name:'=AVS=D0';E_Value:5268),
   (E_Name:'=BACK  ';E_Value:113231),
   (E_Name:'=BACK1B';E_Value:80652),
   (E_Name:'=BACK2B';E_Value:80650),
   (E_Name:'=BACK3B';E_Value:80648),
   (E_Name:'=BASCHA';E_Value:30529),
   (E_Name:'=BASCHK';E_Value:30526),
   (E_Name:'=BASE  ';E_Value:63827),
   (E_Name:'=BASICs';E_Value:181),
   (E_Name:'=BCKSPC';E_Value:86503),
   (E_Name:'=BDISPJ';E_Value:13730),
   (E_Name:'=BEEP  ';E_Value:60014),
   (E_Name:'=BF2DS+';E_Value:7176),
   (E_Name:'=BF2DSP';E_Value:7182),
   (E_Name:'=BF2STK';E_Value:99939),
   (E_Name:'=BIASA+';E_Value:54573),
   (E_Name:'=BIASC+';E_Value:54592),
   (E_Name:'=BIG   ';E_Value:46919),
   (E_Name:'=BLANKC';E_Value:30744),
   (E_Name:'=BLDBIT';E_Value:6588),
   (E_Name:'=BLDCAT';E_Value:25344),
   (E_Name:'=BLDCON';E_Value:90745),
   (E_Name:'=BLDDSP';E_Value:6296),
   (E_Name:'=BLDLCD';E_Value:6300),
   (E_Name:'=BLNC+ ';E_Value:30736),
   (E_Name:'=BLNKCK';E_Value:20929),
   (E_Name:'=BOPNM-';E_Value:112740),
   (E_Name:'=BP+C  ';E_Value:60224),
   (E_Name:'=BRT30 ';E_Value:56291),
   (E_Name:'=BRTF  ';E_Value:56341),
   (E_Name:'=BSCEX2';E_Value:29754),
   (E_Name:'=BSCEXC';E_Value:29751),
   (E_Name:'=BSCEXT';E_Value:30159),
   (E_Name:'=BSERR ';E_Value:37786),
   (E_Name:'=BitsOK';E_Value:1),
   (E_Name:'=BldIM+';E_Value:113258),
   (E_Name:'=BldIMA';E_Value:113254),
   (E_Name:'=BldIMG';E_Value:113256),
   (E_Name:'=C+A2D1';E_Value:114771),
   (E_Name:'=CALBIN';E_Value:101772),
   (E_Name:'=CALL  ';E_Value:101806),
   (E_Name:'=CALLP ';E_Value:14492),
   (E_Name:'=CALSTK';E_Value:193965),
   (E_Name:'=CAT$20';E_Value:26438),
   (E_Name:'=CAT$83';E_Value:26836),
   (E_Name:'=CAT$90';E_Value:26839),
   (E_Name:'=CATC++';E_Value:16230),
   (E_Name:'=CATCH+';E_Value:16233),
   (E_Name:'=CATCHR';E_Value:16240),
   (E_Name:'=CATEDT';E_Value:25653),
   (E_Name:'=CHAIN+';E_Value:31762),
   (E_Name:'=CHAIN-';E_Value:31772),
   (E_Name:'=CHEDIT';E_Value:85145),
   (E_Name:'=CHIRP ';E_Value:60506),
   (E_Name:'=CHKAIO';E_Value:16518),
   (E_Name:'=CHKASN';E_Value:15447),
   (E_Name:'=CHKEOL';E_Value:81261),
   (E_Name:'=CHKMAS';E_Value:16988),
   (E_Name:'=CHKSET';E_Value:12617),
   (E_Name:'=CHKST+';E_Value:12640),
   (E_Name:'=CHKSTS';E_Value:2959),
   (E_Name:'=CHKSUM';E_Value:118254),
   (E_Name:'=CHKmem';E_Value:4807),
   (E_Name:'=CHN#SV';E_Value:194927),
   (E_Name:'=CHNHED';E_Value:62841),
   (E_Name:'=CHNLST';E_Value:193982),
   (E_Name:'=CK"ON"';E_Value:30381),
   (E_Name:'=CKINF-';E_Value:99636),
   (E_Name:'=CKINFO';E_Value:99650),
   (E_Name:'=CKSREQ';E_Value:1825),
   (E_Name:'=CKSUM2';E_Value:43649),
   (E_Name:'=CKSUM3';E_Value:86953),
   (E_Name:'=CKSUM4';E_Value:121766),
   (E_Name:'=CLASSA';E_Value:54672),
   (E_Name:'=CLCBFR';E_Value:193910),
   (E_Name:'=CLCSTK';E_Value:193925),
   (E_Name:'=CLLINK';E_Value:108332),
   (E_Name:'=CLOSEA';E_Value:73956),
   (E_Name:'=CLOSEF';E_Value:73863),
   (E_Name:'=CLRFRC';E_Value:50932),
   (E_Name:'=CLRPRM';E_Value:18471),
   (E_Name:'=CMD1ST';E_Value:5716),
   (E_Name:'=CMDFND';E_Value:5779),
   (E_Name:'=CMDINI';E_Value:5841),
   (E_Name:'=CMDPR"';E_Value:5671),
   (E_Name:'=CMDPTR';E_Value:194260),
   (E_Name:'=CMDS20';E_Value:5746),
   (E_Name:'=CMOSTV';E_Value:5775),
   (E_Name:'=CMOSTW';E_Value:193592),
   (E_Name:'=CMPT  ';E_Value:75186),
   (E_Name:'=CNFFND';E_Value:68012),
   (E_Name:'=CNFLCT';E_Value:48405),
   (E_Name:'=CNTADR';E_Value:194174),
   (E_Name:'=CNVUCR';E_Value:86695),
   (E_Name:'=CNVWUC';E_Value:16312),
   (E_Name:'=COLDST';E_Value:0),
   (E_Name:'=COLLAP';E_Value:37371),
   (E_Name:'=COMCK ';E_Value:14029),
   (E_Name:'=COMCK+';E_Value:12974),
   (E_Name:'=COMCKO';E_Value:12970),
   (E_Name:'=COMPL#';E_Value:30832),
   (E_Name:'=CONCOM';E_Value:18046),
   (E_Name:'=CONF  ';E_Value:66066),
   (E_Name:'=CONFST';E_Value:195046),
   (E_Name:'=CONVUC';E_Value:86698),
   (E_Name:'=COPYu ';E_Value:33385),
   (E_Name:'=CORUPT';E_Value:36995),
   (E_Name:'=COS12 ';E_Value:55073),
   (E_Name:'=COS15 ';E_Value:55077),
   (E_Name:'=COUNTC';E_Value:115526),
   (E_Name:'=CPL#10';E_Value:30855),
   (E_Name:'=CR    ';E_Value:180224),
   (E_Name:'=CRDFIL';E_Value:119325),
   (E_Name:'=CREATE';E_Value:71079),
   (E_Name:'=CRETF+';E_Value:33988),
   (E_Name:'=CRFSB-';E_Value:71268),
   (E_Name:'=CRLFND';E_Value:8862),
   (E_Name:'=CRLFOF';E_Value:8854),
   (E_Name:'=CRLFSD';E_Value:8866),
   (E_Name:'=CRTF  ';E_Value:71361),
   (E_Name:'=CSL9R0';E_Value:113165),
   (E_Name:'=CSLC1 ';E_Value:111681),
   (E_Name:'=CSLC10';E_Value:111640),
   (E_Name:'=CSLC11';E_Value:111643),
   (E_Name:'=CSLC12';E_Value:111646),
   (E_Name:'=CSLC13';E_Value:111649),
   (E_Name:'=CSLC14';E_Value:111652),
   (E_Name:'=CSLC15';E_Value:111655),
   (E_Name:'=CSLC2 ';E_Value:111678),
   (E_Name:'=CSLC3 ';E_Value:111675),
   (E_Name:'=CSLC4 ';E_Value:111672),
   (E_Name:'=CSLC5 ';E_Value:111669),
   (E_Name:'=CSLC6 ';E_Value:111666),
   (E_Name:'=CSLC7 ';E_Value:111663),
   (E_Name:'=CSLC8 ';E_Value:111660),
   (E_Name:'=CSLC9 ';E_Value:111637),
   (E_Name:'=CSLW3 ';E_Value:60739),
   (E_Name:'=CSLW4 ';E_Value:60736),
   (E_Name:'=CSLW5 ';E_Value:60733),
   (E_Name:'=CSPEED';E_Value:194935),
   (E_Name:'=CSRC1 ';E_Value:111655),
   (E_Name:'=CSRC10';E_Value:111666),
   (E_Name:'=CSRC11';E_Value:111669),
   (E_Name:'=CSRC12';E_Value:111672),
   (E_Name:'=CSRC13';E_Value:111675),
   (E_Name:'=CSRC14';E_Value:111678),
   (E_Name:'=CSRC15';E_Value:111681),
   (E_Name:'=CSRC2 ';E_Value:111652),
   (E_Name:'=CSRC3 ';E_Value:111649),
   (E_Name:'=CSRC4 ';E_Value:111646),
   (E_Name:'=CSRC5 ';E_Value:111643),
   (E_Name:'=CSRC6 ';E_Value:111640),
   (E_Name:'=CSRC7 ';E_Value:111637),
   (E_Name:'=CSRC8 ';E_Value:111660),
   (E_Name:'=CSRC9 ';E_Value:111663),
   (E_Name:'=CSRW3 ';E_Value:60722),
   (E_Name:'=CSRW4 ';E_Value:60719),
   (E_Name:'=CSRW5 ';E_Value:60716),
   (E_Name:'=CURBOT';E_Value:65625),
   (E_Name:'=CURDVC';E_Value:42507),
   (E_Name:'=CURREN';E_Value:193900),
   (E_Name:'=CURRL ';E_Value:194536),
   (E_Name:'=CURRST';E_Value:193885),
   (E_Name:'=CURSFL';E_Value:86495),
   (E_Name:'=CURSFR';E_Value:86487),
   (E_Name:'=CURSOR';E_Value:193662),
   (E_Name:'=CURSRD';E_Value:65700),
   (E_Name:'=CURSRL';E_Value:86479),
   (E_Name:'=CURSRR';E_Value:86471),
   (E_Name:'=CURSRT';E_Value:38593),
   (E_Name:'=CURSRU';E_Value:65690),
   (E_Name:'=CURTOP';E_Value:65635),
   (E_Name:'=CVUCW ';E_Value:16316),
   (E_Name:'=CkLoop';E_Value:112233),
   (E_Name:'=CkLpNC';E_Value:112237),
   (E_Name:'=Clear ';E_Value:5),
   (E_Name:'=CurOff';E_Value:6),
   (E_Name:'=D0+2RD';E_Value:80434),
   (E_Name:'=D0=AVS';E_Value:39724),
   (E_Name:'=D0=FIB';E_Value:80581),
   (E_Name:'=D0=OBS';E_Value:20583),
   (E_Name:'=D0=PCA';E_Value:39735),
   (E_Name:'=D0ASC+';E_Value:38956),
   (E_Name:'=D0ASCI';E_Value:38963),
   (E_Name:'=D12R0A';E_Value:113212),
   (E_Name:'=D1=AVE';E_Value:99921),
   (E_Name:'=D1@AVS';E_Value:4761),
   (E_Name:'=D1C=R3';E_Value:12359),
   (E_Name:'=D1FSTK';E_Value:103773),
   (E_Name:'=D1MST+';E_Value:81441),
   (E_Name:'=D1MSTK';E_Value:103758),
   (E_Name:'=D=AVME';E_Value:107638),
   (E_Name:'=D=AVMS';E_Value:107616),
   (E_Name:'=D=WORD';E_Value:19470),
   (E_Name:'=DATLEN';E_Value:46468),
   (E_Name:'=DATPTR';E_Value:194194),
   (E_Name:'=DAY2JD';E_Value:78855),
   (E_Name:'=DAYYMD';E_Value:78645),
   (E_Name:'=DBLPI4';E_Value:56060),
   (E_Name:'=DBLSUB';E_Value:56029),
   (E_Name:'=DCHX=C';E_Value:111312),
   (E_Name:'=DCHXF ';E_Value:111139),
   (E_Name:'=DCHXW ';E_Value:60636),
   (E_Name:'=DCONTR';E_Value:189438),
   (E_Name:'=DCPLIN';E_Value:65800),
   (E_Name:'=DCRMNT';E_Value:115063),
   (E_Name:'=DD1CTL';E_Value:189439),
   (E_Name:'=DD1END';E_Value:189260),
   (E_Name:'=DD1ST ';E_Value:189184),
   (E_Name:'=DD2CTL';E_Value:189183),
   (E_Name:'=DD2END';E_Value:189024),
   (E_Name:'=DD2ST ';E_Value:188928),
   (E_Name:'=DD3CTL';E_Value:188927),
   (E_Name:'=DD3END';E_Value:188768),
   (E_Name:'=DD3ST ';E_Value:188676),
   (E_Name:'=DDL   ';E_Value:27429),
   (E_Name:'=DDT   ';E_Value:27444),
   (E_Name:'=DEBNCE';E_Value:3319),
   (E_Name:'=DECHEX';E_Value:111314),
   (E_Name:'=DECP  ';E_Value:12943),
   (E_Name:'=DEFADC';E_Value:21244),
   (E_Name:'=DEFADR';E_Value:194919),
   (E_Name:'=DELAYT';E_Value:194888),
   (E_Name:'=DELAYp';E_Value:10950),
   (E_Name:'=DEST  ';E_Value:63408),
   (E_Name:'=DEVPAR';E_Value:7152),
   (E_Name:'=DEVPR$';E_Value:7222),
   (E_Name:'=DISINT';E_Value:193648),
   (E_Name:'=DISPDC';E_Value:21584),
   (E_Name:'=DISPP ';E_Value:13732),
   (E_Name:'=DISPt ';E_Value:0),
   (E_Name:'=DIVF  ';E_Value:50360),
   (E_Name:'=DMNSN ';E_Value:44601),
   (E_Name:'=DONNA ';E_Value:38486),
   (E_Name:'=DPART2';E_Value:97955),
   (E_Name:'=DPART3';E_Value:98040),
   (E_Name:'=DPOS  ';E_Value:194893),
   (E_Name:'=DPVCTR';E_Value:44112),
   (E_Name:'=DRANGE';E_Value:110710),
   (E_Name:'=DROPDC';E_Value:21616),
   (E_Name:'=DSLEEP';E_Value:1389),
   (E_Name:'=DSP$00';E_Value:99803),
   (E_Name:'=DSPBFE';E_Value:193856),
   (E_Name:'=DSPBFS';E_Value:193664),
   (E_Name:'=DSPBUF';E_Value:38691),
   (E_Name:'=DSPCAT';E_Value:25969),
   (E_Name:'=DSPCHA';E_Value:7230),
   (E_Name:'=DSPCHC';E_Value:7228),
   (E_Name:'=DSPCHX';E_Value:194164),
   (E_Name:'=DSPCL?';E_Value:8374),
   (E_Name:'=DSPCNA';E_Value:38689),
   (E_Name:'=DSPCNB';E_Value:38687),
   (E_Name:'=DSPCNO';E_Value:38678),
   (E_Name:'=DSPDGT';E_Value:194269),
   (E_Name:'=DSPFMT';E_Value:194268),
   (E_Name:'=DSPLI+';E_Value:65807),
   (E_Name:'=DSPLIN';E_Value:65831),
   (E_Name:'=DSPMSK';E_Value:193856),
   (E_Name:'=DSPRST';E_Value:9283),
   (E_Name:'=DSPSET';E_Value:194481),
   (E_Name:'=DSPSTA';E_Value:193653),
   (E_Name:'=DSPUPD';E_Value:6874),
   (E_Name:'=DSTRDC';E_Value:21120),
   (E_Name:'=DV15M ';E_Value:50348),
   (E_Name:'=DV15S ';E_Value:50354),
   (E_Name:'=DV2-12';E_Value:50344),
   (E_Name:'=DV2-15';E_Value:50348),
   (E_Name:'=DVCSPp';E_Value:31013),
   (E_Name:'=DVZNIB';E_Value:194300),
   (E_Name:'=DWIDTH';E_Value:194895),
   (E_Name:'=DXP100';E_Value:53119),
   (E_Name:'=DZP   ';E_Value:3),
   (E_Name:'=EDIT80';E_Value:42405),
   (E_Name:'=EDITWF';E_Value:42291),
   (E_Name:'=EFIELD';E_Value:0),
   (E_Name:'=ENDALL';E_Value:30362),
   (E_Name:'=ENDBIN';E_Value:30283),
   (E_Name:'=ENDFN ';E_Value:1984),
   (E_Name:'=ENDIMG';E_Value:114752),
   (E_Name:'=ENDSUB';E_Value:103848),
   (E_Name:'=ENDTAP';E_Value:17625),
   (E_Name:'=EOLCK ';E_Value:10878),
   (E_Name:'=EOLCK8';E_Value:10898),
   (E_Name:'=EOLCKR';E_Value:10874),
   (E_Name:'=EOLDC ';E_Value:21506),
   (E_Name:'=EOLLEN';E_Value:194906),
   (E_Name:'=EOLSCN';E_Value:35495),
   (E_Name:'=EOLSN5';E_Value:35505),
   (E_Name:'=EOLSTR';E_Value:194907),
   (E_Name:'=EOLXC*';E_Value:21228),
   (E_Name:'=EOLXCK';E_Value:21509),
   (E_Name:'=ERR#  ';E_Value:194532),
   (E_Name:'=ERRADR';E_Value:194184),
   (E_Name:'=ERRL# ';E_Value:194540),
   (E_Name:'=ERRM$f';E_Value:38918),
   (E_Name:'=ERRRTN';E_Value:29933),
   (E_Name:'=ERRSUB';E_Value:194179),
   (E_Name:'=ESCSEQ';E_Value:9153),
   (E_Name:'=ESCSTA';E_Value:193659),
   (E_Name:'=EX-115';E_Value:53064),
   (E_Name:'=EX12  ';E_Value:54726),
   (E_Name:'=EX15M ';E_Value:54730),
   (E_Name:'=EX15S ';E_Value:54734),
   (E_Name:'=EXAB1 ';E_Value:54247),
   (E_Name:'=EXAB2 ';E_Value:54286),
   (E_Name:'=EXACT ';E_Value:75952),
   (E_Name:'=EXCAD+';E_Value:34353),
   (E_Name:'=EXCHRe';E_Value:11905),
   (E_Name:'=EXCPAR';E_Value:100328),
   (E_Name:'=EXDCLP';E_Value:22830),
   (E_Name:'=EXF   ';E_Value:54751),
   (E_Name:'=EXP15 ';E_Value:53082),
   (E_Name:'=EXPEX+';E_Value:61826),
   (E_Name:'=EXPEX-';E_Value:61816),
   (E_Name:'=EXPEXC';E_Value:61830),
   (E_Name:'=EXPP10';E_Value:16355),
   (E_Name:'=EXPPAR';E_Value:16345),
   (E_Name:'=EXPPLS';E_Value:16348),
   (E_Name:'=EXPR  ';E_Value:62012),
   (E_Name:'=EXPRDC';E_Value:22818),
   (E_Name:'=EXPSKP';E_Value:108972),
   (E_Name:'=EndNum';E_Value:230),
   (E_Name:'=Except';E_Value:12),
   (E_Name:'=F-R0-0';E_Value:194715),
   (E_Name:'=F-R0-1';E_Value:194720),
   (E_Name:'=F-R0-2';E_Value:194725),
   (E_Name:'=F-R0-3';E_Value:194730),
   (E_Name:'=F-R1-0';E_Value:194731),
   (E_Name:'=F-R1-1';E_Value:194736),
   (E_Name:'=F-R1-2';E_Value:194741),
   (E_Name:'=F-R1-3';E_Value:194746),
   (E_Name:'=FAC15S';E_Value:59179),
   (E_Name:'=FASCFD';E_Value:69827),
   (E_Name:'=FCHLBL';E_Value:30764),
   (E_Name:'=FCSTRT';E_Value:59223),
   (E_Name:'=FGTBL ';E_Value:3227),
   (E_Name:'=FIBAD-';E_Value:70776),
   (E_Name:'=FIBADR';E_Value:70743),
   (E_Name:'=FIBOFF';E_Value:74034),
   (E_Name:'=FILCRD';E_Value:116857),
   (E_Name:'=FILDC*';E_Value:22361),
   (E_Name:'=FILEF ';E_Value:40880),
   (E_Name:'=FILEP ';E_Value:16028),
   (E_Name:'=FILEP!';E_Value:16143),
   (E_Name:'=FILEP+';E_Value:16135),
   (E_Name:'=FILEP-';E_Value:16128),
   (E_Name:'=FILEP1';E_Value:16124),
   (E_Name:'=FILFIL';E_Value:4558),
   (E_Name:'=FILSK+';E_Value:28445),
   (E_Name:'=FILXQ$';E_Value:39829),
   (E_Name:'=FILXQ^';E_Value:39798),
   (E_Name:'=FIND  ';E_Value:62819),
   (E_Name:'=FINDA ';E_Value:9187),
   (E_Name:'=FINDD0';E_Value:9184),
   (E_Name:'=FINDF ';E_Value:40823),
   (E_Name:'=FINDF+';E_Value:40803),
   (E_Name:'=FINDF+';E_Value:18086),
   (E_Name:'=FINDFL';E_Value:18079),
   (E_Name:'=FINDFx';E_Value:18226),
   (E_Name:'=FINDL ';E_Value:65508),
   (E_Name:'=FINDL0';E_Value:65533),
   (E_Name:'=FINDLB';E_Value:30598),
   (E_Name:'=FINDLR';E_Value:65502),
   (E_Name:'=FINITA';E_Value:52483),
   (E_Name:'=FINITC';E_Value:52495),
   (E_Name:'=FINLIN';E_Value:100922),
   (E_Name:'=FIRSTC';E_Value:193660),
   (E_Name:'=FIXDC ';E_Value:21651),
   (E_Name:'=FIXP  ';E_Value:10862),
   (E_Name:'=FLADDR';E_Value:4715),
   (E_Name:'=FLDEVX';E_Value:4436),
   (E_Name:'=FLGREG';E_Value:194281),
   (E_Name:'=FLIP10';E_Value:56220),
   (E_Name:'=FLIP11';E_Value:56235),
   (E_Name:'=FLIP8 ';E_Value:56205),
   (E_Name:'=FLOAT ';E_Value:111394),
   (E_Name:'=FLTDH ';E_Value:111139),
   (E_Name:'=FLTYPp';E_Value:15985),
   (E_Name:'=FNDCH-';E_Value:2939),
   (E_Name:'=FNDCHK';E_Value:2950),
   (E_Name:'=FNDCLR';E_Value:121583),
   (E_Name:'=FNDFCN';E_Value:106657),
   (E_Name:'=FNDMB+';E_Value:15271),
   (E_Name:'=FNDMB-';E_Value:15275),
   (E_Name:'=FNDMBD';E_Value:15306),
   (E_Name:'=FNDMBX';E_Value:15328),
   (E_Name:'=FNPWDS';E_Value:54208),
   (E_Name:'=FNRTN1';E_Value:61974),
   (E_Name:'=FNRTN2';E_Value:61977),
   (E_Name:'=FNRTN3';E_Value:62005),
   (E_Name:'=FNRTN4';E_Value:62008),
   (E_Name:'=FORMAT';E_Value:17041),
   (E_Name:'=FORSTK';E_Value:193950),
   (E_Name:'=FORUPD';E_Value:42670),
   (E_Name:'=FPOLL ';E_Value:75018),
   (E_Name:'=FRAC15';E_Value:50958),
   (E_Name:'=FRAME+';E_Value:1837),
   (E_Name:'=FRAME-';E_Value:1851),
   (E_Name:'=FRAMEE';E_Value:27459),
   (E_Name:'=FRASPp';E_Value:30420),
   (E_Name:'=FRASPp';E_Value:31945),
   (E_Name:'=FRange';E_Value:46186),
   (E_Name:'=FSPECe';E_Value:12034),
   (E_Name:'=FSPECp';E_Value:15557),
   (E_Name:'=FSPECx';E_Value:40749),
   (E_Name:'=FTBSCH';E_Value:69779),
   (E_Name:'=FTYPDC';E_Value:26882),
   (E_Name:'=FTYPF#';E_Value:69721),
   (E_Name:'=FUNCD0';E_Value:194747),
   (E_Name:'=FUNCD1';E_Value:194752),
   (E_Name:'=FUNCR0';E_Value:194715),
   (E_Name:'=FUNCR1';E_Value:194731),
   (E_Name:'=FXQPIL';E_Value:29519),
   (E_Name:'=GADDR ';E_Value:2303),
   (E_Name:'=GADRR+';E_Value:16314),
   (E_Name:'=GADRRM';E_Value:16299),
   (E_Name:'=GADRST';E_Value:28772),
   (E_Name:'=GDIRST';E_Value:18499),
   (E_Name:'=GDISP$';E_Value:115655),
   (E_Name:'=GET   ';E_Value:26449),
   (E_Name:'=GETAVM';E_Value:99917),
   (E_Name:'=GETCH#';E_Value:70695),
   (E_Name:'=GETCNT';E_Value:106614),
   (E_Name:'=GETCON';E_Value:55971),
   (E_Name:'=GETD  ';E_Value:26568),
   (E_Name:'=GETDI!';E_Value:18391),
   (E_Name:'=GETDID';E_Value:28036),
   (E_Name:'=GETDIM';E_Value:44395),
   (E_Name:'=GETDIR';E_Value:18464),
   (E_Name:'=GETDIX';E_Value:28066),
   (E_Name:'=GETDR"';E_Value:18398),
   (E_Name:'=GETDR#';E_Value:18400),
   (E_Name:'=GETDR+';E_Value:18425),
   (E_Name:'=GETDVW';E_Value:28979),
   (E_Name:'=GETDev';E_Value:2907),
   (E_Name:'=GETEND';E_Value:26597),
   (E_Name:'=GETERR';E_Value:26513),
   (E_Name:'=GETHSS';E_Value:12602),
   (E_Name:'=GETID ';E_Value:26638),
   (E_Name:'=GETID+';E_Value:26618),
   (E_Name:'=GETLPs';E_Value:7445),
   (E_Name:'=GETMBX';E_Value:15202),
   (E_Name:'=GETMSK';E_Value:7098),
   (E_Name:'=GETNAM';E_Value:106629),
   (E_Name:'=GETNE ';E_Value:26427),
   (E_Name:'=GETPI+';E_Value:28180),
   (E_Name:'=GETPIL';E_Value:28171),
   (E_Name:'=GETPR+';E_Value:27637),
   (E_Name:'=GETPR1';E_Value:27643),
   (E_Name:'=GETPRO';E_Value:27630),
   (E_Name:'=GETSA ';E_Value:58705),
   (E_Name:'=GETST ';E_Value:26503),
   (E_Name:'=GETST*';E_Value:30486),
   (E_Name:'=GETST-';E_Value:30504),
   (E_Name:'=GETST-';E_Value:26526),
   (E_Name:'=GETSTC';E_Value:30502),
   (E_Name:'=GETVAL';E_Value:55986),
   (E_Name:'=GETX  ';E_Value:26288),
   (E_Name:'=GFTYPE';E_Value:11670),
   (E_Name:'=GHEXB+';E_Value:16257),
   (E_Name:'=GHEXBT';E_Value:16253),
   (E_Name:'=GLOOP#';E_Value:11610),
   (E_Name:'=GNXTCR';E_Value:12388),
   (E_Name:'=GOSUB ';E_Value:31209),
   (E_Name:'=GOSUBp';E_Value:10742),
   (E_Name:'=GOTO  ';E_Value:31226),
   (E_Name:'=GOTODC';E_Value:21806),
   (E_Name:'=GOTOp ';E_Value:10742),
   (E_Name:'=GSBSTK';E_Value:193955),
   (E_Name:'=GTEXT ';E_Value:20601),
   (E_Name:'=GTEXT+';E_Value:20889),
   (E_Name:'=GTEXT1';E_Value:20901),
   (E_Name:'=GTFLAG';E_Value:79454),
   (E_Name:'=GTKY54';E_Value:36506),
   (E_Name:'=GTKYC+';E_Value:36251),
   (E_Name:'=GTKYCD';E_Value:36242),
   (E_Name:'=GTPTRS';E_Value:83510),
   (E_Name:'=GTPTRX';E_Value:83568),
   (E_Name:'=GTXT++';E_Value:20882),
   (E_Name:'=GTYPE ';E_Value:3071),
   (E_Name:'=GTYPR+';E_Value:16236),
   (E_Name:'=GTYPRM';E_Value:16238),
   (E_Name:'=GTYPST';E_Value:28659),
   (E_Name:'=GetEXP';E_Value:114822),
   (E_Name:'=HASH1 ';E_Value:110753),
   (E_Name:'=HASH2 ';E_Value:110755),
   (E_Name:'=HDFLT ';E_Value:111387),
   (E_Name:'=HEXASC';E_Value:94536),
   (E_Name:'=HEXDEC';E_Value:60591),
   (E_Name:'=HMSSEC';E_Value:78452),
   (E_Name:'=HNDLFL';E_Value:52169),
   (E_Name:'=HPSCRH';E_Value:194943),
   (E_Name:'=HTRAP ';E_Value:52015),
   (E_Name:'=HUGE  ';E_Value:46941),
   (E_Name:'=HXDASC';E_Value:24564),
   (E_Name:'=HXDCW ';E_Value:60596),
   (E_Name:'=I/OAL+';E_Value:72059),
   (E_Name:'=I/OALL';E_Value:72061),
   (E_Name:'=I/OCOL';E_Value:72057),
   (E_Name:'=I/OCON';E_Value:71968),
   (E_Name:'=I/ODAL';E_Value:72257),
   (E_Name:'=I/OEX2';E_Value:72207),
   (E_Name:'=I/OEXP';E_Value:72209),
   (E_Name:'=I/OFND';E_Value:71866),
   (E_Name:'=I/ORES';E_Value:71935),
   (E_Name:'=IDIV  ';E_Value:60539),
   (E_Name:'=IDIVA ';E_Value:60526),
   (E_Name:'=IF12A ';E_Value:51001),
   (E_Name:'=ILCNTe';E_Value:11888),
   (E_Name:'=IMD0+2';E_Value:113197),
   (E_Name:'=IMD0-2';E_Value:113185),
   (E_Name:'=IMGxq1';E_Value:113323),
   (E_Name:'=IMentr';E_Value:111925),
   (E_Name:'=IMerr ';E_Value:113033),
   (E_Name:'=IMinit';E_Value:112783),
   (E_Name:'=IMoffs';E_Value:113240),
   (E_Name:'=IMxq27';E_Value:113564),
   (E_Name:'=IN/REP';E_Value:86613),
   (E_Name:'=INADDR';E_Value:194260),
   (E_Name:'=INBS  ';E_Value:194246),
   (E_Name:'=INF*0 ';E_Value:50695),
   (E_Name:'=INFR15';E_Value:51005),
   (E_Name:'=INITFL';E_Value:26852),
   (E_Name:'=INPOFF';E_Value:101193),
   (E_Name:'=INTA  ';E_Value:193552),
   (E_Name:'=INTB  ';E_Value:193568),
   (E_Name:'=INTGR ';E_Value:63899),
   (E_Name:'=INTM  ';E_Value:193584),
   (E_Name:'=INTR4 ';E_Value:193536),
   (E_Name:'=INTR50';E_Value:219),
   (E_Name:'=INTRPT';E_Value:15),
   (E_Name:'=INVNaN';E_Value:50783),
   (E_Name:'=INXNIB';E_Value:194297),
   (E_Name:'=IOBFEN';E_Value:193910),
   (E_Name:'=IOBFST';E_Value:193905),
   (E_Name:'=IOFND0';E_Value:71873),
   (E_Name:'=IOFSCR';E_Value:71822),
   (E_Name:'=IS-DSP';E_Value:194445),
   (E_Name:'=IS-INP';E_Value:194459),
   (E_Name:'=IS-PLT';E_Value:194466),
   (E_Name:'=IS-PRT';E_Value:194452),
   (E_Name:'=IS-TBL';E_Value:194445),
   (E_Name:'=ISRAM?';E_Value:65938),
   (E_Name:'=IVAERR';E_Value:59680),
   (E_Name:'=IVARG ';E_Value:55113),
   (E_Name:'=IVEXPe';E_Value:11829),
   (E_Name:'=IVLNIB';E_Value:194301),
   (E_Name:'=IVP   ';E_Value:4),
   (E_Name:'=IVPARe';E_Value:11839),
   (E_Name:'=IVVARe';E_Value:11878),
   (E_Name:'=InhEOL';E_Value:4),
   (E_Name:'=Insert';E_Value:7),
   (E_Name:'=KCOL0 ';E_Value:193647),
   (E_Name:'=KCOL1 ';E_Value:193646),
   (E_Name:'=KCOL2 ';E_Value:193645),
   (E_Name:'=KCOL3 ';E_Value:193644),
   (E_Name:'=KCOL4 ';E_Value:193643),
   (E_Name:'=KCOL5 ';E_Value:193642),
   (E_Name:'=KCOL6 ';E_Value:193641),
   (E_Name:'=KCOL7 ';E_Value:193640),
   (E_Name:'=KCOL8 ';E_Value:193639),
   (E_Name:'=KCOL9 ';E_Value:193638),
   (E_Name:'=KCOLA ';E_Value:193637),
   (E_Name:'=KCOLB ';E_Value:193636),
   (E_Name:'=KCOLC ';E_Value:193635),
   (E_Name:'=KCOLD ';E_Value:193634),
   (E_Name:'=KEY$  ';E_Value:109736),
   (E_Name:'=KEYBUF';E_Value:193604),
   (E_Name:'=KEYCOD';E_Value:130338),
   (E_Name:'=KEYDEL';E_Value:36140),
   (E_Name:'=KEYFND';E_Value:36024),
   (E_Name:'=KEYMRG';E_Value:35727),
   (E_Name:'=KEYNAM';E_Value:109572),
   (E_Name:'=KEYPTR';E_Value:193603),
   (E_Name:'=KEYRD ';E_Value:85521),
   (E_Name:'=KEYSAV';E_Value:193634),
   (E_Name:'=KEYSCN';E_Value:3405),
   (E_Name:'=KYDN? ';E_Value:1908),
   (E_Name:'=LABELP';E_Value:16031),
   (E_Name:'=LABLDC';E_Value:22274),
   (E_Name:'=LASTFN';E_Value:180),
   (E_Name:'=LBLIN#';E_Value:194673),
   (E_Name:'=LBLINP';E_Value:10756),
   (E_Name:'=LBLNAM';E_Value:30695),
   (E_Name:'=LBLNIF';E_Value:10765),
   (E_Name:'=LCDINI';E_Value:1637),
   (E_Name:'=LDCEXT';E_Value:20318),
   (E_Name:'=LDCM10';E_Value:20335),
   (E_Name:'=LDCOMP';E_Value:20329),
   (E_Name:'=LDCSET';E_Value:20576),
   (E_Name:'=LDCSPC';E_Value:194241),
   (E_Name:'=LDSST1';E_Value:20338),
   (E_Name:'=LDSST2';E_Value:20382),
   (E_Name:'=LEAVE ';E_Value:19457),
   (E_Name:'=LEEWAY';E_Value:212),
   (E_Name:'=LEXBF+';E_Value:69087),
   (E_Name:'=LEXPTR';E_Value:194255),
   (E_Name:'=LGT15 ';E_Value:53678),
   (E_Name:'=LIMITS';E_Value:44094),
   (E_Name:'=LIN#AU';E_Value:20770),
   (E_Name:'=LIN#D+';E_Value:20754),
   (E_Name:'=LIN#DC';E_Value:20757),
   (E_Name:'=LINEP ';E_Value:9760),
   (E_Name:'=LINEP*';E_Value:9780),
   (E_Name:'=LINEP+';E_Value:9766),
   (E_Name:'=LINP  ';E_Value:10759),
   (E_Name:'=LINSKP';E_Value:35333),
   (E_Name:'=LISTDC';E_Value:22585),
   (E_Name:'=LISTEN';E_Value:3164),
   (E_Name:'=LN1+15';E_Value:52548),
   (E_Name:'=LN1+XF';E_Value:52561),
   (E_Name:'=LN12  ';E_Value:52605),
   (E_Name:'=LN15  ';E_Value:52609),
   (E_Name:'=LN30  ';E_Value:52636),
   (E_Name:'=LNEP66';E_Value:10218),
   (E_Name:'=LNPEXT';E_Value:9751),
   (E_Name:'=LNSKP-';E_Value:35327),
   (E_Name:'=LOCADR';E_Value:42513),
   (E_Name:'=LOCFIL';E_Value:94749),
   (E_Name:'=LOCKWD';E_Value:194482),
   (E_Name:'=LOOP#d';E_Value:31914),
   (E_Name:'=LOOP#p';E_Value:30375),
   (E_Name:'=LOOPST';E_Value:194476),
   (E_Name:'=LSLEEP';E_Value:1741),
   (E_Name:'=LSTENT';E_Value:18996),
   (E_Name:'=LSTLEN';E_Value:27687),
   (E_Name:'=LXFND ';E_Value:38813),
   (E_Name:'=LXTXTT';E_Value:126623),
   (E_Name:'=MAIN05';E_Value:824),
   (E_Name:'=MAIN30';E_Value:894),
   (E_Name:'=MAINEN';E_Value:193905),
   (E_Name:'=MAINLP';E_Value:765),
   (E_Name:'=MAINST';E_Value:193880),
   (E_Name:'=MAKE1 ';E_Value:56014),
   (E_Name:'=MAKEBF';E_Value:5969),
   (E_Name:'=MANSTK';E_Value:104147),
   (E_Name:'=MAXCMD';E_Value:194934),
   (E_Name:'=MBOX^ ';E_Value:194473),
   (E_Name:'=MEMBER';E_Value:110744),
   (E_Name:'=MEMCKL';E_Value:4773),
   (E_Name:'=MEMER*';E_Value:37979),
   (E_Name:'=MEMERR';E_Value:37965),
   (E_Name:'=MEMERX';E_Value:37967),
   (E_Name:'=MESSG ';E_Value:52247),
   (E_Name:'=MFER42';E_Value:38444),
   (E_Name:'=MFERR ';E_Value:37779),
   (E_Name:'=MFERR*';E_Value:37873),
   (E_Name:'=MFERRS';E_Value:37790),
   (E_Name:'=MFERsp';E_Value:37901),
   (E_Name:'=MFLG=0';E_Value:81313),
   (E_Name:'=MFWRN ';E_Value:37820),
   (E_Name:'=MFWRNQ';E_Value:37829),
   (E_Name:'=MFWRQ8';E_Value:37827),
   (E_Name:'=MGOSUB';E_Value:110337),
   (E_Name:'=MLFFLG';E_Value:194672),
   (E_Name:'=MOD15 ';E_Value:51094),
   (E_Name:'=MOVE*M';E_Value:4872),
   (E_Name:'=MOVED0';E_Value:110836),
   (E_Name:'=MOVED1';E_Value:110849),
   (E_Name:'=MOVED2';E_Value:110852),
   (E_Name:'=MOVED3';E_Value:110857),
   (E_Name:'=MOVEDA';E_Value:110842),
   (E_Name:'=MOVEDD';E_Value:110854),
   (E_Name:'=MOVEDM';E_Value:110830),
   (E_Name:'=MOVEFL';E_Value:17777),
   (E_Name:'=MOVEU0';E_Value:110946),
   (E_Name:'=MOVEU1';E_Value:110959),
   (E_Name:'=MOVEU2';E_Value:110962),
   (E_Name:'=MOVEU3';E_Value:110967),
   (E_Name:'=MOVEU4';E_Value:110964),
   (E_Name:'=MOVEUA';E_Value:110952),
   (E_Name:'=MOVEUM';E_Value:110940),
   (E_Name:'=MP1-12';E_Value:50230),
   (E_Name:'=MP15S ';E_Value:50240),
   (E_Name:'=MP2-12';E_Value:50226),
   (E_Name:'=MP2-15';E_Value:50234),
   (E_Name:'=MPOP1N';E_Value:48525),
   (E_Name:'=MPOP2N';E_Value:48468),
   (E_Name:'=MPY   ';E_Value:60603),
   (E_Name:'=MSIZE ';E_Value:66567),
   (E_Name:'=MSIZE+';E_Value:66570),
   (E_Name:'=MSN12 ';E_Value:54611),
   (E_Name:'=MSN15 ';E_Value:54615),
   (E_Name:'=MSPARe';E_Value:11868),
   (E_Name:'=MTADDR';E_Value:33173),
   (E_Name:'=MTADR+';E_Value:33185),
   (E_Name:'=MTHSTK';E_Value:193945),
   (E_Name:'=MTYL  ';E_Value:3203),
   (E_Name:'=MTYLL ';E_Value:3210),
   (E_Name:'=MULTF ';E_Value:50246),
   (E_Name:'=MVMEM+';E_Value:4924),
   (E_Name:'=NAMEp ';E_Value:31128),
   (E_Name:'=NAMEpb';E_Value:31124),
   (E_Name:'=NEEDSC';E_Value:194890),
   (E_Name:'=NEWFI+';E_Value:19017),
   (E_Name:'=NEWFIL';E_Value:19045),
   (E_Name:'=NORDIM';E_Value:44589),
   (E_Name:'=NOSCRL';E_Value:85130),
   (E_Name:'=NRMCON';E_Value:90543),
   (E_Name:'=NTOKEN';E_Value:18747),
   (E_Name:'=NTOKNL';E_Value:18662),
   (E_Name:'=NULLP ';E_Value:31129),
   (E_Name:'=NUMC++';E_Value:13968),
   (E_Name:'=NUMC+O';E_Value:13974),
   (E_Name:'=NUMCK ';E_Value:13981),
   (E_Name:'=NUMSCN';E_Value:19736),
   (E_Name:'=NXPR10';E_Value:46000),
   (E_Name:'=NXPRMP';E_Value:45989),
   (E_Name:'=NXTADR';E_Value:83944),
   (E_Name:'=NXTELM';E_Value:84140),
   (E_Name:'=NXTENT';E_Value:18974),
   (E_Name:'=NXTEXP';E_Value:115447),
   (E_Name:'=NXTIRQ';E_Value:194317),
   (E_Name:'=NXTLIN';E_Value:65585),
   (E_Name:'=NXTP  ';E_Value:13397),
   (E_Name:'=NXTSTM';E_Value:35400),
   (E_Name:'=NXTVA-';E_Value:81496),
   (E_Name:'=NoCont';E_Value:14),
   (E_Name:'=NwOFFS';E_Value:114733),
   (E_Name:'=OAGNXT';E_Value:12384),
   (E_Name:'=OBCOLL';E_Value:5173),
   (E_Name:'=OBEDIT';E_Value:95879),
   (E_Name:'=OFFFLG';E_Value:193602),
   (E_Name:'=OKP   ';E_Value:0),
   (E_Name:'=ONDC20';E_Value:21761),
   (E_Name:'=ONINTR';E_Value:194189),
   (E_Name:'=ONP40 ';E_Value:11131),
   (E_Name:'=ONTIMR';E_Value:32776),
   (E_Name:'=OPENF ';E_Value:72454),
   (E_Name:'=ORGSB ';E_Value:54875),
   (E_Name:'=ORSB  ';E_Value:54844),
   (E_Name:'=ORXM  ';E_Value:54835),
   (E_Name:'=OUT1T+';E_Value:11487),
   (E_Name:'=OUT1TK';E_Value:11499),
   (E_Name:'=OUT2TC';E_Value:11517),
   (E_Name:'=OUT2TK';E_Value:11519),
   (E_Name:'=OUT3TC';E_Value:11538),
   (E_Name:'=OUT3TK';E_Value:11541),
   (E_Name:'=OUTBS ';E_Value:193935),
   (E_Name:'=OUTBY+';E_Value:11493),
   (E_Name:'=OUTBYT';E_Value:11496),
   (E_Name:'=OUTC15';E_Value:21537),
   (E_Name:'=OUTEL1';E_Value:21248),
   (E_Name:'=OUTELA';E_Value:21251),
   (E_Name:'=OUTLI1';E_Value:14089),
   (E_Name:'=OUTLIT';E_Value:14067),
   (E_Name:'=OUTNBC';E_Value:21539),
   (E_Name:'=OUTNBS';E_Value:21542),
   (E_Name:'=OUTNIB';E_Value:11560),
   (E_Name:'=OUTRES';E_Value:48260),
   (E_Name:'=OUTVAR';E_Value:14142),
   (E_Name:'=OVFL  ';E_Value:51827),
   (E_Name:'=OVFNIB';E_Value:194299),
   (E_Name:'=OVP   ';E_Value:2),
   (E_Name:'=P1-10 ';E_Value:16833),
   (E_Name:'=PACKd ';E_Value:31562),
   (E_Name:'=PARERR';E_Value:12040),
   (E_Name:'=PART3 ';E_Value:98455),
   (E_Name:'=PCADDR';E_Value:194169),
   (E_Name:'=PCEXPR';E_Value:26664),
   (E_Name:'=PDEV  ';E_Value:40606),
   (E_Name:'=PEDIT ';E_Value:65375),
   (E_Name:'=PEDITD';E_Value:65378),
   (E_Name:'=PEDITM';E_Value:65392),
   (E_Name:'=PFINDL';E_Value:30943),
   (E_Name:'=PFNDZL';E_Value:30946),
   (E_Name:'=PI/2  ';E_Value:56183),
   (E_Name:'=PI/2D ';E_Value:56186),
   (E_Name:'=PI/4  ';E_Value:55969),
   (E_Name:'=PNDALM';E_Value:194401),
   (E_Name:'=POLL  ';E_Value:74551),
   (E_Name:'=POLLD+';E_Value:74541),
   (E_Name:'=POP1N ';E_Value:48412),
   (E_Name:'=POP1N+';E_Value:48529),
   (E_Name:'=POP1R ';E_Value:59645),
   (E_Name:'=POP1S ';E_Value:48440),
   (E_Name:'=POP2N ';E_Value:48268),
   (E_Name:'=POP2N+';E_Value:48472),
   (E_Name:'=POPBUF';E_Value:4334),
   (E_Name:'=POPMTH';E_Value:111579),
   (E_Name:'=POPSTK';E_Value:36693),
   (E_Name:'=POPSTR';E_Value:111621),
   (E_Name:'=POPUPD';E_Value:36670),
   (E_Name:'=PPOS  ';E_Value:194902),
   (E_Name:'=PRASCI';E_Value:4074),
   (E_Name:'=PREND ';E_Value:4130),
   (E_Name:'=PREP  ';E_Value:44463),
   (E_Name:'=PRESCN';E_Value:19017),
   (E_Name:'=PRGFMF';E_Value:41286),
   (E_Name:'=PRGMEN';E_Value:193895),
   (E_Name:'=PRGMST';E_Value:193890),
   (E_Name:'=PRINT*';E_Value:98103),
   (E_Name:'=PRINTt';E_Value:1),
   (E_Name:'=PRMCHN';E_Value:45941),
   (E_Name:'=PRMCNT';E_Value:194891),
   (E_Name:'=PRMPTR';E_Value:193975),
   (E_Name:'=PRMSGA';E_Value:3257),
   (E_Name:'=PRNEXe';E_Value:11925),
   (E_Name:'=PRNTDC';E_Value:21584),
   (E_Name:'=PRNTSd';E_Value:31550),
   (E_Name:'=PRNTSp';E_Value:29800),
   (E_Name:'=PROCDW';E_Value:29056),
   (E_Name:'=PROCLT';E_Value:29134),
   (E_Name:'=PROCST';E_Value:28347),
   (E_Name:'=PRPSND';E_Value:27415),
   (E_Name:'=PRSC00';E_Value:31635),
   (E_Name:'=PRSsc+';E_Value:113284),
   (E_Name:'=PRSscn';E_Value:113288),
   (E_Name:'=PRT#DC';E_Value:26689),
   (E_Name:'=PSHGSB';E_Value:36627),
   (E_Name:'=PSHMCR';E_Value:36619),
   (E_Name:'=PSHSTK';E_Value:35967),
   (E_Name:'=PSHSTL';E_Value:35973),
   (E_Name:'=PSHUPD';E_Value:36621),
   (E_Name:'=PUGFIB';E_Value:74136),
   (E_Name:'=PURGDC';E_Value:22341),
   (E_Name:'=PURGEF';E_Value:95065),
   (E_Name:'=PUTALR';E_Value:3645),
   (E_Name:'=PUTARL';E_Value:3621),
   (E_Name:'=PUTC  ';E_Value:27420),
   (E_Name:'=PUTC+ ';E_Value:27416),
   (E_Name:'=PUTC+N';E_Value:27368),
   (E_Name:'=PUTCN ';E_Value:27372),
   (E_Name:'=PUTD  ';E_Value:27310),
   (E_Name:'=PUTDX ';E_Value:3669),
   (E_Name:'=PUTE  ';E_Value:27328),
   (E_Name:'=PUTEN ';E_Value:27377),
   (E_Name:'=PUTEX ';E_Value:27336),
   (E_Name:'=PUTGF ';E_Value:3057),
   (E_Name:'=PUTGF+';E_Value:3053),
   (E_Name:'=PUTGF-';E_Value:3049),
   (E_Name:'=PUTRES';E_Value:98581),
   (E_Name:'=PUTX  ';E_Value:27138),
   (E_Name:'=PWIDTH';E_Value:194904),
   (E_Name:'=PWROFF';E_Value:1318),
   (E_Name:'=PgmRun';E_Value:13),
   (E_Name:'=QUOEXe';E_Value:11915),
   (E_Name:'=QUOTCK';E_Value:25149),
   (E_Name:'=R1REV ';E_Value:1925),
   (E_Name:'=R2REV ';E_Value:43651),
   (E_Name:'=R3=D10';E_Value:13606),
   (E_Name:'=R3REV ';E_Value:86955),
   (E_Name:'=R4REV ';E_Value:121768),
   (E_Name:'=R<RST2';E_Value:5339),
   (E_Name:'=R<RSTK';E_Value:5341),
   (E_Name:'=RAMEND';E_Value:193970),
   (E_Name:'=RAMROM';E_Value:42487),
   (E_Name:'=RANGE ';E_Value:110716),
   (E_Name:'=RAWBFR';E_Value:193920),
   (E_Name:'=RCCD1 ';E_Value:54261),
   (E_Name:'=RCCD2 ';E_Value:54300),
   (E_Name:'=RCL*  ';E_Value:59779),
   (E_Name:'=RCLALL';E_Value:110527),
   (E_Name:'=RCLW1 ';E_Value:59777),
   (E_Name:'=RCLW2 ';E_Value:59838),
   (E_Name:'=RCLW3 ';E_Value:59844),
   (E_Name:'=RCSCR ';E_Value:59732),
   (E_Name:'=RCURON';E_Value:85120),
   (E_Name:'=RCVOFS';E_Value:114768),
   (E_Name:'=RDATTY';E_Value:97478),
   (E_Name:'=RDBAS ';E_Value:95231),
   (E_Name:'=RDBYTA';E_Value:80431),
   (E_Name:'=RDCHD+';E_Value:30446),
   (E_Name:'=RDCHDR';E_Value:30448),
   (E_Name:'=RDHDR1';E_Value:30461),
   (E_Name:'=RDINFO';E_Value:33899),
   (E_Name:'=RDLNAS';E_Value:80415),
   (E_Name:'=RDST01';E_Value:8812),
   (E_Name:'=RDTEXT';E_Value:95369),
   (E_Name:'=READ# ';E_Value:17663),
   (E_Name:'=READIN';E_Value:62596),
   (E_Name:'=READIT';E_Value:26185),
   (E_Name:'=READNB';E_Value:95512),
   (E_Name:'=READP5';E_Value:12859),
   (E_Name:'=READRG';E_Value:26629),
   (E_Name:'=READSU';E_Value:26173),
   (E_Name:'=RECADR';E_Value:62647),
   (E_Name:'=RECALL';E_Value:62081),
   (E_Name:'=RED-LF';E_Value:8783),
   (E_Name:'=REDC00';E_Value:8786),
   (E_Name:'=REDCHR';E_Value:8802),
   (E_Name:'=REDUCE';E_Value:88439),
   (E_Name:'=RELJMP';E_Value:20551),
   (E_Name:'=RENSUB';E_Value:108371),
   (E_Name:'=REPROM';E_Value:100894),
   (E_Name:'=RESCAN';E_Value:19020),
   (E_Name:'=RESERV';E_Value:194950),
   (E_Name:'=RESPTR';E_Value:12658),
   (E_Name:'=RESREG';E_Value:194498),
   (E_Name:'=REST* ';E_Value:12341),
   (E_Name:'=RESTOR';E_Value:15964),
   (E_Name:'=RESTRT';E_Value:12280),
   (E_Name:'=REV$  ';E_Value:111502),
   (E_Name:'=REVPOP';E_Value:48433),
   (E_Name:'=REWIND';E_Value:70501),
   (E_Name:'=RFAD++';E_Value:42747),
   (E_Name:'=RFAD+I';E_Value:42754),
   (E_Name:'=RFAD--';E_Value:42578),
   (E_Name:'=RFAD-I';E_Value:42585),
   (E_Name:'=RFNBFR';E_Value:193915),
   (E_Name:'=RFUPD+';E_Value:42606),
   (E_Name:'=RJUST ';E_Value:76514),
   (E_Name:'=RND-12';E_Value:110623),
   (E_Name:'=RND12+';E_Value:51669),
   (E_Name:'=RNDAHX';E_Value:79563),
   (E_Name:'=RNDNRM';E_Value:51889),
   (E_Name:'=RNSEED';E_Value:194302),
   (E_Name:'=ROMCHK';E_Value:69598),
   (E_Name:'=ROMCID';E_Value:3070),
   (E_Name:'=ROMCK5';E_Value:69604),
   (E_Name:'=ROMFND';E_Value:69679),
   (E_Name:'=ROMTYP';E_Value:16594),
   (E_Name:'=ROWDVR';E_Value:189264),
   (E_Name:'=RPLLIN';E_Value:5111),
   (E_Name:'=RPLSBH';E_Value:96667),
   (E_Name:'=RPTKY ';E_Value:86714),
   (E_Name:'=RST2<R';E_Value:5286),
   (E_Name:'=RSTD0 ';E_Value:26674),
   (E_Name:'=RSTD1 ';E_Value:116118),
   (E_Name:'=RSTK<R';E_Value:5288),
   (E_Name:'=RSTKBF';E_Value:194592),
   (E_Name:'=RSTKBp';E_Value:194591),
   (E_Name:'=RSTST ';E_Value:62917),
   (E_Name:'=RTNX10';E_Value:36850),
   (E_Name:'=RUNRT1';E_Value:29927),
   (E_Name:'=RUNRTN';E_Value:29930),
   (E_Name:'=ResetC';E_Value:8),
   (E_Name:'=S-R0-0';E_Value:194673),
   (E_Name:'=S-R0-1';E_Value:194678),
   (E_Name:'=S-R0-2';E_Value:194683),
   (E_Name:'=S-R0-3';E_Value:194688),
   (E_Name:'=S-R1-0';E_Value:194689),
   (E_Name:'=S-R1-1';E_Value:194694),
   (E_Name:'=S-R1-2';E_Value:194699),
   (E_Name:'=S-R1-3';E_Value:194704),
   (E_Name:'=SALLOC';E_Value:5435),
   (E_Name:'=SAVD0 ';E_Value:116103),
   (E_Name:'=SAVD1 ';E_Value:116088),
   (E_Name:'=SAVEIT';E_Value:15798),
   (E_Name:'=SAVESB';E_Value:54894),
   (E_Name:'=SAVEXM';E_Value:54883),
   (E_Name:'=SAVGSB';E_Value:54862),
   (E_Name:'=SAVSTK';E_Value:193950),
   (E_Name:'=SB15S ';E_Value:57754),
   (E_Name:'=SCAN  ';E_Value:19520),
   (E_Name:'=SCNRT ';E_Value:8889),
   (E_Name:'=SCOPCK';E_Value:37211),
   (E_Name:'=SCREX0';E_Value:194881),
   (E_Name:'=SCREX1';E_Value:194897),
   (E_Name:'=SCREX2';E_Value:194913),
   (E_Name:'=SCREX3';E_Value:194929),
   (E_Name:'=SCRLLR';E_Value:8494),
   (E_Name:'=SCROLT';E_Value:194886),
   (E_Name:'=SCRPTR';E_Value:194918),
   (E_Name:'=SCRST0';E_Value:194817),
   (E_Name:'=SCRTCH';E_Value:194817),
   (E_Name:'=SE1-10';E_Value:17512),
   (E_Name:'=SECHMS';E_Value:78418),
   (E_Name:'=SEEKA ';E_Value:16946),
   (E_Name:'=SEEKB ';E_Value:16953),
   (E_Name:'=SEEKRD';E_Value:25304),
   (E_Name:'=SEND20';E_Value:97786),
   (E_Name:'=SENDEL';E_Value:97729),
   (E_Name:'=SENDI+';E_Value:27017),
   (E_Name:'=SENDIT';E_Value:27023),
   (E_Name:'=SENDIT';E_Value:97763),
   (E_Name:'=SENDWD';E_Value:97813),
   (E_Name:'=SETALM';E_Value:76045),
   (E_Name:'=SETALR';E_Value:76055),
   (E_Name:'=SETFMT';E_Value:61471),
   (E_Name:'=SETLP ';E_Value:15229),
   (E_Name:'=SETSB ';E_Value:54849),
   (E_Name:'=SETTMO';E_Value:78168),
   (E_Name:'=SETUP ';E_Value:15667),
   (E_Name:'=SFLAG?';E_Value:79436),
   (E_Name:'=SFLAGC';E_Value:79361),
   (E_Name:'=SFLAGS';E_Value:79354),
   (E_Name:'=SFLAGT';E_Value:79368),
   (E_Name:'=SHF10 ';E_Value:50310),
   (E_Name:'=SHFLAC';E_Value:56134),
   (E_Name:'=SHFRAC';E_Value:56145),
   (E_Name:'=SHFRBD';E_Value:56159),
   (E_Name:'=SHRT  ';E_Value:63852),
   (E_Name:'=SHUTDN';E_Value:1506),
   (E_Name:'=SIGCHK';E_Value:48536),
   (E_Name:'=SIGTST';E_Value:58934),
   (E_Name:'=SIN12 ';E_Value:55062),
   (E_Name:'=SIN15 ';E_Value:55066),
   (E_Name:'=SKIPDC';E_Value:22518),
   (E_Name:'=SKP-LF';E_Value:8776),
   (E_Name:'=SLEEP ';E_Value:1730),
   (E_Name:'=SNAPBF';E_Value:194544),
   (E_Name:'=SNAPR*';E_Value:5496),
   (E_Name:'=SNAPRS';E_Value:5489),
   (E_Name:'=SNAPSV';E_Value:5543),
   (E_Name:'=SNDWD+';E_Value:97823),
   (E_Name:'=SPACE ';E_Value:44445),
   (E_Name:'=SPLITA';E_Value:50879),
   (E_Name:'=SPLITC';E_Value:51520),
   (E_Name:'=SPLTAC';E_Value:51508),
   (E_Name:'=SPLTAX';E_Value:58923),
   (E_Name:'=SQR15 ';E_Value:50484),
   (E_Name:'=SQR17 ';E_Value:50515),
   (E_Name:'=SQR70 ';E_Value:50627),
   (E_Name:'=SQRSAV';E_Value:54825),
   (E_Name:'=SRLEAS';E_Value:5612),
   (E_Name:'=STAB1 ';E_Value:54233),
   (E_Name:'=STAB2 ';E_Value:54272),
   (E_Name:'=START ';E_Value:2024),
   (E_Name:'=START+';E_Value:2030),
   (E_Name:'=START-';E_Value:2033),
   (E_Name:'=STATAR';E_Value:194477),
   (E_Name:'=STATRS';E_Value:94963),
   (E_Name:'=STATSV';E_Value:95023),
   (E_Name:'=STCD2 ';E_Value:54311),
   (E_Name:'=STKCHR';E_Value:99588),
   (E_Name:'=STKCMD';E_Value:87533),
   (E_Name:'=STKVCT';E_Value:83724),
   (E_Name:'=STMBCL';E_Value:37095),
   (E_Name:'=STMBUF';E_Value:37087),
   (E_Name:'=STMTD0';E_Value:194705),
   (E_Name:'=STMTD1';E_Value:194710),
   (E_Name:'=STMTR0';E_Value:194673),
   (E_Name:'=STMTR1';E_Value:194689),
   (E_Name:'=STORE ';E_Value:62968),
   (E_Name:'=STR$00';E_Value:98652),
   (E_Name:'=STR$SB';E_Value:98633),
   (E_Name:'=STRALL';E_Value:110429),
   (E_Name:'=STRASN';E_Value:63155),
   (E_Name:'=STREQL';E_Value:111087),
   (E_Name:'=STRGCK';E_Value:14010),
   (E_Name:'=STRHDR';E_Value:61594),
   (E_Name:'=STRHED';E_Value:85038),
   (E_Name:'=STRNGP';E_Value:14237),
   (E_Name:'=STRTST';E_Value:111047),
   (E_Name:'=STSAVE';E_Value:194238),
   (E_Name:'=STSCR ';E_Value:59692),
   (E_Name:'=STUFF ';E_Value:110770),
   (E_Name:'=SUBONE';E_Value:49959),
   (E_Name:'=SVINF+';E_Value:33879),
   (E_Name:'=SVINFO';E_Value:33882),
   (E_Name:'=SVTRC ';E_Value:64053),
   (E_Name:'=SWPBYT';E_Value:96804),
   (E_Name:'=SYNTXe';E_Value:11819),
   (E_Name:'=SYSEN ';E_Value:193930),
   (E_Name:'=SYSFLG';E_Value:194265),
   (E_Name:'=SavLvl';E_Value:5),
   (E_Name:'=SetAVM';E_Value:113146),
   (E_Name:'=TAN12 ';E_Value:55087),
   (E_Name:'=TAN15 ';E_Value:55091),
   (E_Name:'=TASTK ';E_Value:193945),
   (E_Name:'=TBLJM2';E_Value:9277),
   (E_Name:'=TBLJMC';E_Value:9254),
   (E_Name:'=TBLJMP';E_Value:9258),
   (E_Name:'=TBMSG$';E_Value:39339),
   (E_Name:'=TERCHR';E_Value:194941),
   (E_Name:'=TFHDLR';E_Value:94255),
   (E_Name:'=TFORN ';E_Value:193950),
   (E_Name:'=TGSBS ';E_Value:193955),
   (E_Name:'=TIMAF ';E_Value:194439),
   (E_Name:'=TIMER1';E_Value:189432),
   (E_Name:'=TIMER2';E_Value:189176),
   (E_Name:'=TIMER3';E_Value:188920),
   (E_Name:'=TIMLAF';E_Value:194427),
   (E_Name:'=TIMLST';E_Value:194415),
   (E_Name:'=TIMOFS';E_Value:194403),
   (E_Name:'=TKSCN+';E_Value:35435),
   (E_Name:'=TKSCN7';E_Value:35481),
   (E_Name:'=TMRAD1';E_Value:194199),
   (E_Name:'=TMRAD2';E_Value:194204),
   (E_Name:'=TMRAD3';E_Value:194209),
   (E_Name:'=TMRIN1';E_Value:194214),
   (E_Name:'=TMRIN2';E_Value:194222),
   (E_Name:'=TMRIN3';E_Value:194230),
   (E_Name:'=TODT  ';E_Value:78377),
   (E_Name:'=TONE  ';E_Value:60395),
   (E_Name:'=TRACDC';E_Value:21244),
   (E_Name:'=TRACEM';E_Value:194480),
   (E_Name:'=TRC90 ';E_Value:55825),
   (E_Name:'=TRFMBF';E_Value:194757),
   (E_Name:'=TRFROM';E_Value:65113),
   (E_Name:'=TRKDON';E_Value:118700),
   (E_Name:'=TRMNTR';E_Value:61917),
   (E_Name:'=TRPREG';E_Value:194297),
   (E_Name:'=TRSFMu';E_Value:93060),
   (E_Name:'=TRTO+ ';E_Value:65147),
   (E_Name:'=TST12A';E_Value:54390),
   (E_Name:'=TST15 ';E_Value:54394),
   (E_Name:'=TSTAT ';E_Value:16894),
   (E_Name:'=TSTATA';E_Value:16901),
   (E_Name:'=TWO*  ';E_Value:56120),
   (E_Name:'=Trace ';E_Value:15),
   (E_Name:'=TstEnd';E_Value:114943),
   (E_Name:'=ULYL  ';E_Value:3157),
   (E_Name:'=UNFNIB';E_Value:194298),
   (E_Name:'=UNP   ';E_Value:1),
   (E_Name:'=UPCPOS';E_Value:80999),
   (E_Name:'=UPD1EN';E_Value:193945),
   (E_Name:'=UPD1ST';E_Value:193885),
   (E_Name:'=UPD2EN';E_Value:194214),
   (E_Name:'=UPD2ST';E_Value:194164),
   (E_Name:'=UPDANN';E_Value:79217),
   (E_Name:'=UPDPCC';E_Value:31589),
   (E_Name:'=USG*10';E_Value:111880),
   (E_Name:'=USGch+';E_Value:113685),
   (E_Name:'=USGch-';E_Value:113675),
   (E_Name:'=USGrst';E_Value:113763),
   (E_Name:'=USING ';E_Value:111686),
   (E_Name:'=USINGp';E_Value:13864),
   (E_Name:'=USloop';E_Value:115019),
   (E_Name:'=USnm05';E_Value:113938),
   (E_Name:'=USst03';E_Value:113614),
   (E_Name:'=USst05';E_Value:113620),
   (E_Name:'=UTLEND';E_Value:1996),
   (E_Name:'=VAL00 ';E_Value:109967),
   (E_Name:'=VALCHK';E_Value:110177),
   (E_Name:'=VARDC ';E_Value:21372),
   (E_Name:'=VARNB-';E_Value:57997),
   (E_Name:'=VARNBR';E_Value:57993),
   (E_Name:'=VARP  ';E_Value:13582),
   (E_Name:'=VECTOR';E_Value:193596),
   (E_Name:'=VIEWD1';E_Value:86343),
   (E_Name:'=VRIABL';E_Value:19396),
   (E_Name:'=ValSub';E_Value:10),
   (E_Name:'=WFTMDT';E_Value:34269),
   (E_Name:'=WINDLN';E_Value:193651),
   (E_Name:'=WINDST';E_Value:193649),
   (E_Name:'=WIPOUT';E_Value:110767),
   (E_Name:'=WRBYTC';E_Value:80499),
   (E_Name:'=WRDSC+';E_Value:11302),
   (E_Name:'=WRDSCN';E_Value:11306),
   (E_Name:'=WRITE#';E_Value:17727),
   (E_Name:'=WRITIT';E_Value:26906),
   (E_Name:'=WRITNB';E_Value:95531),
   (E_Name:'=WRTFIB';E_Value:72942),
   (E_Name:'=WRTNUM';E_Value:80324),
   (E_Name:'=WRTSTR';E_Value:80239),
   (E_Name:'=WSTRFX';E_Value:80053),
   (E_Name:'=XDelay';E_Value:9),
   (E_Name:'=XMTADR';E_Value:33075),
   (E_Name:'=XROM01';E_Value:1),
   (E_Name:'=XXHEAD';E_Value:107598),
   (E_Name:'=XYEX  ';E_Value:50839),
   (E_Name:'=YMDDAY';E_Value:78596),
   (E_Name:'=YMDH01';E_Value:78053),
   (E_Name:'=YMDHMS';E_Value:78043),
   (E_Name:'=YTML  ';E_Value:3227),
   (E_Name:'=YX2-12';E_Value:53876),
   (E_Name:'=YX2-15';E_Value:53882),
   (E_Name:'=ZERBUF';E_Value:101152),
   (E_Name:'=a!    ';E_Value:33),
   (E_Name:'=a"    ';E_Value:34),
   (E_Name:'=a$    ';E_Value:36),
   (E_Name:'=a''    ';E_Value:39),
   (E_Name:'=a.    ';E_Value:46),
   (E_Name:'=a0    ';E_Value:48),
   (E_Name:'=a1    ';E_Value:49),
   (E_Name:'=a2    ';E_Value:50),
   (E_Name:'=a3    ';E_Value:51),
   (E_Name:'=a4    ';E_Value:52),
   (E_Name:'=a5    ';E_Value:53),
   (E_Name:'=a6    ';E_Value:54),
   (E_Name:'=a7    ';E_Value:55),
   (E_Name:'=a8    ';E_Value:56),
   (E_Name:'=a9    ';E_Value:57),
   (E_Name:'=bALTCH';E_Value:3067),
   (E_Name:'=bASSGN';E_Value:2052),
   (E_Name:'=bCARD ';E_Value:2055),
   (E_Name:'=bCHARS';E_Value:3067),
   (E_Name:'=bECOMD';E_Value:2057),
   (E_Name:'=bFIB  ';E_Value:2051),
   (E_Name:'=bFILE ';E_Value:2053),
   (E_Name:'=bIEXKY';E_Value:2050),
   (E_Name:'=bLEX  ';E_Value:3068),
   (E_Name:'=bPILAI';E_Value:2064),
   (E_Name:'=bPILSV';E_Value:2063),
   (E_Name:'=bROMTB';E_Value:3070),
   (E_Name:'=bSCRTC';E_Value:3584),
   (E_Name:'=bSTART';E_Value:2056),
   (E_Name:'=bSTAT ';E_Value:2054),
   (E_Name:'=bSTMT ';E_Value:2049),
   (E_Name:'=bSTMXQ';E_Value:2065),
   (E_Name:'=cC->C ';E_Value:104),
   (E_Name:'=cR->C ';E_Value:105),
   (E_Name:'=cRCL  ';E_Value:103),
   (E_Name:'=dCARD ';E_Value:7),
   (E_Name:'=dIRAM ';E_Value:1),
   (E_Name:'=dMAIN ';E_Value:0),
   (E_Name:'=dPCRD ';E_Value:7),
   (E_Name:'=dPORT ';E_Value:1),
   (E_Name:'=e#of# ';E_Value:247),
   (E_Name:'=e0^0  ';E_Value:6),
   (E_Name:'=e0^NEG';E_Value:5),
   (E_Name:'=e1^INF';E_Value:17),
   (E_Name:'=e2MROM';E_Value:26),
   (E_Name:'=eAF   ';E_Value:27),
   (E_Name:'=eALGN ';E_Value:240),
   (E_Name:'=eCALGN';E_Value:96),
   (E_Name:'=eCHNL#';E_Value:41),
   (E_Name:'=eDATTY';E_Value:31),
   (E_Name:'=eDVCNF';E_Value:64),
   (E_Name:'=eEOFIL';E_Value:54),
   (E_Name:'=eEXCHR';E_Value:78),
   (E_Name:'=eEXP0 ';E_Value:3),
   (E_Name:'=eEXPCT';E_Value:231),
   (E_Name:'=eF2BIG';E_Value:74),
   (E_Name:'=eFACCS';E_Value:60),
   (E_Name:'=eFEXST';E_Value:59),
   (E_Name:'=eFILE ';E_Value:234),
   (E_Name:'=eFNNtF';E_Value:33),
   (E_Name:'=eFOPEN';E_Value:62),
   (E_Name:'=eFPROT';E_Value:61),
   (E_Name:'=eFSPEC';E_Value:58),
   (E_Name:'=eFTYPE';E_Value:63),
   (E_Name:'=eFnFND';E_Value:57),
   (E_Name:'=eFwoNX';E_Value:42),
   (E_Name:'=eIF*ZR';E_Value:16),
   (E_Name:'=eIF-IF';E_Value:15),
   (E_Name:'=eIF/IF';E_Value:14),
   (E_Name:'=eILCNT';E_Value:79),
   (E_Name:'=eILEXP';E_Value:80),
   (E_Name:'=eILKEY';E_Value:85),
   (E_Name:'=eILLEG';E_Value:230),
   (E_Name:'=eILPAR';E_Value:81),
   (E_Name:'=eILTFM';E_Value:55),
   (E_Name:'=eILVAR';E_Value:83),
   (E_Name:'=eIMGOV';E_Value:47),
   (E_Name:'=eINF  ';E_Value:243),
   (E_Name:'=eINF^0';E_Value:18),
   (E_Name:'=eINPUT';E_Value:244),
   (E_Name:'=eINVIM';E_Value:45),
   (E_Name:'=eINVLD';E_Value:236),
   (E_Name:'=eINVST';E_Value:237),
   (E_Name:'=eINVUS';E_Value:46),
   (E_Name:'=eINX  ';E_Value:21),
   (E_Name:'=eIVARG';E_Value:11),
   (E_Name:'=eIVSAR';E_Value:51),
   (E_Name:'=eIVSOP';E_Value:53),
   (E_Name:'=eIVSTA';E_Value:52),
   (E_Name:'=eIVTAB';E_Value:48),
   (E_Name:'=eL2LNG';E_Value:65),
   (E_Name:'=eLN0  ';E_Value:12),
   (E_Name:'=eLOBAT';E_Value:22),
   (E_Name:'=eLOG- ';E_Value:13),
   (E_Name:'=eMEM  ';E_Value:24),
   (E_Name:'=eMMCOR';E_Value:23),
   (E_Name:'=eMPI  ';E_Value:25),
   (E_Name:'=eMSPAR';E_Value:82),
   (E_Name:'=eNEG^X';E_Value:9),
   (E_Name:'=eNFOUN';E_Value:232),
   (E_Name:'=eNODAT';E_Value:32),
   (E_Name:'=eNOTIN';E_Value:67),
   (E_Name:'=eNSVAR';E_Value:51),
   (E_Name:'=eNUMIN';E_Value:38),
   (E_Name:'=eNVSTA';E_Value:51),
   (E_Name:'=eNXwoF';E_Value:43),
   (E_Name:'=eOVFL*';E_Value:245),
   (E_Name:'=eOVFLW';E_Value:2),
   (E_Name:'=ePALGN';E_Value:94),
   (E_Name:'=ePLLC ';E_Value:90),
   (E_Name:'=ePLLC#';E_Value:89),
   (E_Name:'=ePRCER';E_Value:84),
   (E_Name:'=ePRMIS';E_Value:36),
   (E_Name:'=ePRNEX';E_Value:76),
   (E_Name:'=ePROTD';E_Value:66),
   (E_Name:'=ePRTCT';E_Value:248),
   (E_Name:'=ePULL ';E_Value:246),
   (E_Name:'=eQUOEX';E_Value:77),
   (E_Name:'=eR0WRN';E_Value:86),
   (E_Name:'=eR1WRN';E_Value:87),
   (E_Name:'=eRALGN';E_Value:93),
   (E_Name:'=eRECOR';E_Value:29),
   (E_Name:'=eRWERR';E_Value:70),
   (E_Name:'=eRwoGS';E_Value:44),
   (E_Name:'=eSIGOP';E_Value:19),
   (E_Name:'=eSPGNF';E_Value:49),
   (E_Name:'=eSQR- ';E_Value:10),
   (E_Name:'=eSTMNF';E_Value:30),
   (E_Name:'=eSTROV';E_Value:37),
   (E_Name:'=eSUBSC';E_Value:28),
   (E_Name:'=eSYNTX';E_Value:75),
   (E_Name:'=eSYSER';E_Value:23),
   (E_Name:'=eTFFLD';E_Value:56),
   (E_Name:'=eTFM  ';E_Value:241),
   (E_Name:'=eTFWRN';E_Value:88),
   (E_Name:'=eTNINF';E_Value:4),
   (E_Name:'=eTOO  ';E_Value:239),
   (E_Name:'=eTOOFI';E_Value:40),
   (E_Name:'=eTOOMI';E_Value:39),
   (E_Name:'=eTRKDN';E_Value:97),
   (E_Name:'=eTRKOF';E_Value:229),
   (E_Name:'=eTUFAS';E_Value:71),
   (E_Name:'=eTUSLO';E_Value:72),
   (E_Name:'=eUALGN';E_Value:95),
   (E_Name:'=eUNFLW';E_Value:1),
   (E_Name:'=eUNKCD';E_Value:69),
   (E_Name:'=eUNORC';E_Value:20),
   (E_Name:'=eVALGN';E_Value:92),
   (E_Name:'=eVARTY';E_Value:50),
   (E_Name:'=eVFYER';E_Value:68),
   (E_Name:'=eWALGN';E_Value:91),
   (E_Name:'=eWRGNM';E_Value:73),
   (E_Name:'=eXFNNF';E_Value:34),
   (E_Name:'=eXWORD';E_Value:35),
   (E_Name:'=eZRDIV';E_Value:8),
   (E_Name:'=eZRO/0';E_Value:7),
   (E_Name:'=enull ';E_Value:0),
   (E_Name:'=ew/o  ';E_Value:235),
   (E_Name:'=fAOS  ';E_Value:223),
   (E_Name:'=fASCII';E_Value:1),
   (E_Name:'=fBASIC';E_Value:57876),
   (E_Name:'=fBIN  ';E_Value:57860),
   (E_Name:'=fDATA ';E_Value:57584),
   (E_Name:'=fEOF  ';E_Value:255),
   (E_Name:'=fEOR  ';E_Value:239),
   (E_Name:'=fEOS  ';E_Value:111),
   (E_Name:'=fKEY  ';E_Value:57868),
   (E_Name:'=fLEX  ';E_Value:57864),
   (E_Name:'=fLIF1 ';E_Value:1),
   (E_Name:'=fMOS  ';E_Value:127),
   (E_Name:'=fROM  ';E_Value:57884),
   (E_Name:'=fSDATA';E_Value:57552),
   (E_Name:'=fSOS  ';E_Value:207),
   (E_Name:'=fTEXT ';E_Value:1),
   (E_Name:'=flAC  ';E_Value:1048519),
   (E_Name:'=flALRM';E_Value:1048516),
   (E_Name:'=flBASE';E_Value:1048560),
   (E_Name:'=flBAT ';E_Value:1048515),
   (E_Name:'=flBEEP';E_Value:1048574),
   (E_Name:'=flBPLD';E_Value:1048551),
   (E_Name:'=flCALC';E_Value:1048512),
   (E_Name:'=flCLOC';E_Value:1048531),
   (E_Name:'=flCMDS';E_Value:1048529),
   (E_Name:'=flCTON';E_Value:1048573),
   (E_Name:'=flCTRL';E_Value:1048528),
   (E_Name:'=flDG0 ';E_Value:1048559),
   (E_Name:'=flDG1 ';E_Value:1048558),
   (E_Name:'=flDG2 ';E_Value:1048557),
   (E_Name:'=flDG3 ';E_Value:1048556),
   (E_Name:'=flDORM';E_Value:1048533),
   (E_Name:'=flDVZ ';E_Value:1048569),
   (E_Name:'=flEOT ';E_Value:1048553),
   (E_Name:'=flEXAC';E_Value:1048530),
   (E_Name:'=flEXTD';E_Value:1048554),
   (E_Name:'=flFXEN';E_Value:1048563),
   (E_Name:'=flINFR';E_Value:1048565),
   (E_Name:'=flINX ';E_Value:1048572),
   (E_Name:'=flIVL ';E_Value:1048568),
   (E_Name:'=flLC  ';E_Value:1048561),
   (E_Name:'=flMKOF';E_Value:1048526),
   (E_Name:'=flNEGR';E_Value:1048564),
   (E_Name:'=flNOFN';E_Value:1048534),
   (E_Name:'=flNOPR';E_Value:1048550),
   (E_Name:'=flNZ4 ';E_Value:1048552),
   (E_Name:'=flNZ5 ';E_Value:1048523),
   (E_Name:'=flNZ6 ';E_Value:1048522),
   (E_Name:'=flNZ7 ';E_Value:1048521),
   (E_Name:'=flNZ8 ';E_Value:1048520),
   (E_Name:'=flOVF ';E_Value:1048570),
   (E_Name:'=flPDWN';E_Value:1048555),
   (E_Name:'=flPRGM';E_Value:1048514),
   (E_Name:'=flPWDN';E_Value:1048527),
   (E_Name:'=flQIET';E_Value:1048575),
   (E_Name:'=flRAD ';E_Value:1048566),
   (E_Name:'=flRPTD';E_Value:1048517),
   (E_Name:'=flRTN ';E_Value:1048532),
   (E_Name:'=flSCEN';E_Value:1048562),
   (E_Name:'=flSUSP';E_Value:1048513),
   (E_Name:'=flTNOF';E_Value:1048525),
   (E_Name:'=flUNF ';E_Value:1048571),
   (E_Name:'=flUSER';E_Value:1048567),
   (E_Name:'=flUSRX';E_Value:1048518),
   (E_Name:'=flVIEW';E_Value:1048524),
   (E_Name:'=k#-CHR';E_Value:104),
   (E_Name:'=k#-LIN';E_Value:107),
   (E_Name:'=k#1   ';E_Value:39),
   (E_Name:'=k#2   ';E_Value:40),
   (E_Name:'=k#3   ';E_Value:41),
   (E_Name:'=k#ATTN';E_Value:43),
   (E_Name:'=k#BKSP';E_Value:103),
   (E_Name:'=k#BOT ';E_Value:163),
   (E_Name:'=k#CALC';E_Value:111),
   (E_Name:'=k#CONT';E_Value:112),
   (E_Name:'=k#CTRL';E_Value:158),
   (E_Name:'=k#DOWN';E_Value:51),
   (E_Name:'=k#EOL ';E_Value:38),
   (E_Name:'=k#FLFT';E_Value:159),
   (E_Name:'=k#FRT ';E_Value:160),
   (E_Name:'=k#GON ';E_Value:155),
   (E_Name:'=k#I/R ';E_Value:105),
   (E_Name:'=k#LAST';E_Value:164),
   (E_Name:'=k#LC  ';E_Value:106),
   (E_Name:'=k#LERR';E_Value:161),
   (E_Name:'=k#LFT ';E_Value:47),
   (E_Name:'=k#OFF ';E_Value:99),
   (E_Name:'=k#RT  ';E_Value:48),
   (E_Name:'=k#RUN ';E_Value:46),
   (E_Name:'=k#SST ';E_Value:102),
   (E_Name:'=k#TOP ';E_Value:162),
   (E_Name:'=k#UP  ';E_Value:50),
   (E_Name:'=k#USER';E_Value:109),
   (E_Name:'=k#USEX';E_Value:165),
   (E_Name:'=k#VIEW';E_Value:110),
   (E_Name:'=kc-CHR';E_Value:0),
   (E_Name:'=kc-LIN';E_Value:4),
   (E_Name:'=kcATTN';E_Value:14),
   (E_Name:'=kcBKSP';E_Value:7),
   (E_Name:'=kcBOT ';E_Value:21),
   (E_Name:'=kcCALC';E_Value:23),
   (E_Name:'=kcCONT';E_Value:16),
   (E_Name:'=kcCTRL';E_Value:10),
   (E_Name:'=kcDOWN';E_Value:19),
   (E_Name:'=kcEOL ';E_Value:13),
   (E_Name:'=kcFLFT';E_Value:5),
   (E_Name:'=kcFRT ';E_Value:6),
   (E_Name:'=kcGON ';E_Value:22),
   (E_Name:'=kcI/R ';E_Value:2),
   (E_Name:'=kcLAST';E_Value:25),
   (E_Name:'=kcLC  ';E_Value:1),
   (E_Name:'=kcLERR';E_Value:26),
   (E_Name:'=kcLFT ';E_Value:8),
   (E_Name:'=kcOFF ';E_Value:24),
   (E_Name:'=kcRT  ';E_Value:9),
   (E_Name:'=kcRUN ';E_Value:15),
   (E_Name:'=kcSST ';E_Value:17),
   (E_Name:'=kcTOP ';E_Value:20),
   (E_Name:'=kcUP  ';E_Value:18),
   (E_Name:'=kcUSER';E_Value:3),
   (E_Name:'=kcUSEX';E_Value:12),
   (E_Name:'=kcVIEW';E_Value:11),
   (E_Name:'=lACCSb';E_Value:1),
   (E_Name:'=lAp   ';E_Value:16),
   (E_Name:'=lBPOSp';E_Value:5),
   (E_Name:'=lCOPYb';E_Value:1),
   (E_Name:'=lCPOSb';E_Value:6),
   (E_Name:'=lD0p  ';E_Value:5),
   (E_Name:'=lD1p  ';E_Value:5),
   (E_Name:'=lDATEh';E_Value:6),
   (E_Name:'=lDBEGb';E_Value:11),
   (E_Name:'=lDEVC ';E_Value:5),
   (E_Name:'=lDEVCb';E_Value:1),
   (E_Name:'=lDLENb';E_Value:6),
   (E_Name:'=lDp   ';E_Value:16),
   (E_Name:'=lEOL  ';E_Value:2),
   (E_Name:'=lFBEGb';E_Value:6),
   (E_Name:'=lFBF#b';E_Value:3),
   (E_Name:'=lFIB  ';E_Value:63),
   (E_Name:'=lFIL#b';E_Value:2),
   (E_Name:'=lFILSV';E_Value:50),
   (E_Name:'=lFLAGh';E_Value:2),
   (E_Name:'=lFLENh';E_Value:5),
   (E_Name:'=lFNAM+';E_Value:4),
   (E_Name:'=lFNAM8';E_Value:16),
   (E_Name:'=lFNAMh';E_Value:16),
   (E_Name:'=lFSIZb';E_Value:6),
   (E_Name:'=lFTYPb';E_Value:4),
   (E_Name:'=lFTYPh';E_Value:4),
   (E_Name:'=lLXADR';E_Value:5),
   (E_Name:'=lLXENT';E_Value:11),
   (E_Name:'=lLXFAD';E_Value:5),
   (E_Name:'=lLXID ';E_Value:2),
   (E_Name:'=lLXTKR';E_Value:4),
   (E_Name:'=lMSGp ';E_Value:4),
   (E_Name:'=lPOL#p';E_Value:5),
   (E_Name:'=lPOLLp';E_Value:5),
   (E_Name:'=lPOLSV';E_Value:62),
   (E_Name:'=lPOLra';E_Value:6),
   (E_Name:'=lPROTb';E_Value:1),
   (E_Name:'=lREC#b';E_Value:4),
   (E_Name:'=lRECLb';E_Value:4),
   (E_Name:'=lRLENb';E_Value:5),
   (E_Name:'=lRTN1p';E_Value:5),
   (E_Name:'=lRTN2p';E_Value:5),
   (E_Name:'=lRTN3p';E_Value:5),
   (E_Name:'=lSHLNb';E_Value:2),
   (E_Name:'=lSPDTB';E_Value:78),
   (E_Name:'=lSPDn ';E_Value:1),
   (E_Name:'=lSPDn2';E_Value:1),
   (E_Name:'=lTEXTp';E_Value:4),
   (E_Name:'=lTIMEh';E_Value:4),
   (E_Name:'=o41sod';E_Value:5),
   (E_Name:'=oACCSb';E_Value:11),
   (E_Name:'=oAp   ';E_Value:62),
   (E_Name:'=oBNsod';E_Value:17),
   (E_Name:'=oBPOSp';E_Value:5),
   (E_Name:'=oBSsod';E_Value:17),
   (E_Name:'=oCOPYb';E_Value:10),
   (E_Name:'=oCPOSb';E_Value:40),
   (E_Name:'=oD0p  ';E_Value:25),
   (E_Name:'=oD1p  ';E_Value:30),
   (E_Name:'=oDATEh';E_Value:26),
   (E_Name:'=oDAsod';E_Value:13),
   (E_Name:'=oDBEGb';E_Value:21),
   (E_Name:'=oDEVCb';E_Value:12),
   (E_Name:'=oDLENb';E_Value:46),
   (E_Name:'=oDp   ';E_Value:46),
   (E_Name:'=oFBEGb';E_Value:13),
   (E_Name:'=oFBF#b';E_Value:2),
   (E_Name:'=oFIL#b';E_Value:0),
   (E_Name:'=oFLAGh';E_Value:20),
   (E_Name:'=oFLENh';E_Value:32),
   (E_Name:'=oFLSTr';E_Value:49),
   (E_Name:'=oFNAMh';E_Value:0),
   (E_Name:'=oFSIZb';E_Value:57),
   (E_Name:'=oFT-FL';E_Value:16),
   (E_Name:'=oFTYPb';E_Value:5),
   (E_Name:'=oFTYPh';E_Value:16),
   (E_Name:'=oIMPLh';E_Value:37),
   (E_Name:'=oKYsod';E_Value:5),
   (E_Name:'=oLXsod';E_Value:5),
   (E_Name:'=oMAINT';E_Value:93),
   (E_Name:'=oMSGPT';E_Value:9),
   (E_Name:'=oPOL#p';E_Value:10),
   (E_Name:'=oPROTb';E_Value:9),
   (E_Name:'=oREC#b';E_Value:32),
   (E_Name:'=oRECLb';E_Value:36),
   (E_Name:'=oRLENb';E_Value:52),
   (E_Name:'=oRTN1p';E_Value:10),
   (E_Name:'=oRTN2p';E_Value:15),
   (E_Name:'=oRTN3p';E_Value:20),
   (E_Name:'=oSHLNb';E_Value:19),
   (E_Name:'=oSPDTB';E_Value:273),
   (E_Name:'=oSPDn2';E_Value:14),
   (E_Name:'=oSUBLn';E_Value:37),
   (E_Name:'=oTIMEh';E_Value:22),
   (E_Name:'=oTXsod';E_Value:5),
   (E_Name:'=pBSCen';E_Value:245),
   (E_Name:'=pBSCex';E_Value:246),
   (E_Name:'=pCALRS';E_Value:54),
   (E_Name:'=pCALSV';E_Value:55),
   (E_Name:'=pCAT  ';E_Value:6),
   (E_Name:'=pCAT$ ';E_Value:7),
   (E_Name:'=pCLDST';E_Value:255),
   (E_Name:'=pCMPLX';E_Value:56),
   (E_Name:'=pCONFG';E_Value:251),
   (E_Name:'=pCOPYx';E_Value:8),
   (E_Name:'=pCRDAB';E_Value:51),
   (E_Name:'=pCREAT';E_Value:9),
   (E_Name:'=pCRT=8';E_Value:35),
   (E_Name:'=pCURSR';E_Value:41),
   (E_Name:'=pDATLN';E_Value:42),
   (E_Name:'=pDEVCp';E_Value:1),
   (E_Name:'=pDIDST';E_Value:10),
   (E_Name:'=pDSWKY';E_Value:253),
   (E_Name:'=pDSWNK';E_Value:254),
   (E_Name:'=pEDIT ';E_Value:43),
   (E_Name:'=pENTER';E_Value:18),
   (E_Name:'=pEOFIL';E_Value:37),
   (E_Name:'=pERROR';E_Value:242),
   (E_Name:'=pExcpt';E_Value:248),
   (E_Name:'=pFASCH';E_Value:44),
   (E_Name:'=pFILDC';E_Value:2),
   (E_Name:'=pFILXQ';E_Value:3),
   (E_Name:'=pFINDF';E_Value:23),
   (E_Name:'=pFNIN ';E_Value:61),
   (E_Name:'=pFNOUT';E_Value:62),
   (E_Name:'=pFPROT';E_Value:11),
   (E_Name:'=pFSPCp';E_Value:4),
   (E_Name:'=pFSPCx';E_Value:5),
   (E_Name:'=pFTYPE';E_Value:45),
   (E_Name:'=pIMCHR';E_Value:30),
   (E_Name:'=pIMXCH';E_Value:31),
   (E_Name:'=pIMXQT';E_Value:29),
   (E_Name:'=pIMbck';E_Value:32),
   (E_Name:'=pIMcpi';E_Value:33),
   (E_Name:'=pIMcpw';E_Value:34),
   (E_Name:'=pKYDF ';E_Value:27),
   (E_Name:'=pLIST ';E_Value:12),
   (E_Name:'=pLIST2';E_Value:46),
   (E_Name:'=pMEM  ';E_Value:241),
   (E_Name:'=pMERGE';E_Value:13),
   (E_Name:'=pMNLP ';E_Value:250),
   (E_Name:'=pMRGE2';E_Value:47),
   (E_Name:'=pPARSE';E_Value:244),
   (E_Name:'=pPRGPR';E_Value:50),
   (E_Name:'=pPRIN#';E_Value:38),
   (E_Name:'=pPRTCL';E_Value:14),
   (E_Name:'=pPRTIS';E_Value:15),
   (E_Name:'=pPURGE';E_Value:16),
   (E_Name:'=pPWROF';E_Value:252),
   (E_Name:'=pRCRD ';E_Value:52),
   (E_Name:'=pRDCBF';E_Value:24),
   (E_Name:'=pRDNBF';E_Value:25),
   (E_Name:'=pREAD#';E_Value:39),
   (E_Name:'=pREN  ';E_Value:57),
   (E_Name:'=pRNAME';E_Value:17),
   (E_Name:'=pRTNTp';E_Value:58),
   (E_Name:'=pRUNft';E_Value:48),
   (E_Name:'=pRUNnB';E_Value:49),
   (E_Name:'=pSREC#';E_Value:40),
   (E_Name:'=pSREQ ';E_Value:249),
   (E_Name:'=pTEST ';E_Value:240),
   (E_Name:'=pTIMR#';E_Value:59),
   (E_Name:'=pTRANS';E_Value:239),
   (E_Name:'=pTRFMx';E_Value:60),
   (E_Name:'=pVER$ ';E_Value:0),
   (E_Name:'=pWARN ';E_Value:243),
   (E_Name:'=pWCRD ';E_Value:53),
   (E_Name:'=pWCRD8';E_Value:36),
   (E_Name:'=pWRCBF';E_Value:26),
   (E_Name:'=pWTKY ';E_Value:28),
   (E_Name:'=pZERPG';E_Value:247),
   (E_Name:'=sARITH';E_Value:7),
   (E_Name:'=sBYEx ';E_Value:0),
   (E_Name:'=sC/P  ';E_Value:1),
   (E_Name:'=sCARD ';E_Value:2),
   (E_Name:'=sCARDC';E_Value:8),
   (E_Name:'=sCHAIN';E_Value:11),
   (E_Name:'=sCONT ';E_Value:10),
   (E_Name:'=sCONTK';E_Value:9),
   (E_Name:'=sCURBT';E_Value:3),
   (E_Name:'=sCURUD';E_Value:4),
   (E_Name:'=sCURUP';E_Value:2),
   (E_Name:'=sCntg ';E_Value:2),
   (E_Name:'=sCplxP';E_Value:7),
   (E_Name:'=sDEST ';E_Value:3),
   (E_Name:'=sENDx ';E_Value:1),
   (E_Name:'=sEOF  ';E_Value:7),
   (E_Name:'=sERROR';E_Value:0),
   (E_Name:'=sEXTDV';E_Value:0),
   (E_Name:'=sEXTGS';E_Value:5),
   (E_Name:'=sFOUND';E_Value:10),
   (E_Name:'=sGOSUB';E_Value:3),
   (E_Name:'=sI/OBF';E_Value:10),
   (E_Name:'=sINFRD';E_Value:10),
   (E_Name:'=sINX  ';E_Value:5),
   (E_Name:'=sIRAM ';E_Value:2),
   (E_Name:'=sIX   ';E_Value:7),
   (E_Name:'=sInit ';E_Value:3),
   (E_Name:'=sKEYS ';E_Value:5),
   (E_Name:'=sMAINc';E_Value:5),
   (E_Name:'=sMULT ';E_Value:8),
   (E_Name:'=sNEGRD';E_Value:11),
   (E_Name:'=sNoChn';E_Value:2),
   (E_Name:'=sONERR';E_Value:4),
   (E_Name:'=sONTMR';E_Value:6),
   (E_Name:'=sPCRD ';E_Value:8),
   (E_Name:'=sPRGCF';E_Value:11),
   (E_Name:'=sRAD  ';E_Value:9),
   (E_Name:'=sRDX  ';E_Value:11),
   (E_Name:'=sREADI';E_Value:4),
   (E_Name:'=sRENAM';E_Value:6),
   (E_Name:'=sRENUM';E_Value:8),
   (E_Name:'=sRESTR';E_Value:10),
   (E_Name:'=sRETRN';E_Value:0),
   (E_Name:'=sRFILE';E_Value:8),
   (E_Name:'=sRUNBn';E_Value:4),
   (E_Name:'=sRUNDC';E_Value:7),
   (E_Name:'=sSIGN ';E_Value:9),
   (E_Name:'=sSST  ';E_Value:2),
   (E_Name:'=sSSTdc';E_Value:1),
   (E_Name:'=sSTAT ';E_Value:6),
   (E_Name:'=sSTOP ';E_Value:5),
   (E_Name:'=sSpecl';E_Value:6),
   (E_Name:'=sUNDEF';E_Value:1),
   (E_Name:'=sXCPT ';E_Value:4),
   (E_Name:'=sXQT  ';E_Value:0),
   (E_Name:'=sXWORD';E_Value:9),
   (E_Name:'=t!    ';E_Value:252),
   (E_Name:'=t%    ';E_Value:133),
   (E_Name:'=t&    ';E_Value:137),
   (E_Name:'=t*    ';E_Value:131),
   (E_Name:'=t+    ';E_Value:135),
   (E_Name:'=t-    ';E_Value:130),
   (E_Name:'=t/    ';E_Value:132),
   (E_Name:'=t@    ';E_Value:244),
   (E_Name:'=tABS  ';E_Value:162),
   (E_Name:'=tACOS ';E_Value:154),
   (E_Name:'=tADD  ';E_Value:213),
   (E_Name:'=tADIG0';E_Value:96),
   (E_Name:'=tADIG1';E_Value:97),
   (E_Name:'=tADIG2';E_Value:98),
   (E_Name:'=tADIG3';E_Value:99),
   (E_Name:'=tADIG4';E_Value:100),
   (E_Name:'=tADIG5';E_Value:101),
   (E_Name:'=tADIG6';E_Value:102),
   (E_Name:'=tADIG7';E_Value:103),
   (E_Name:'=tADIG8';E_Value:104),
   (E_Name:'=tADIG9';E_Value:105),
   (E_Name:'=tALL  ';E_Value:248),
   (E_Name:'=tAND  ';E_Value:139),
   (E_Name:'=tANGLE';E_Value:393651),
   (E_Name:'=tARRAY';E_Value:125),
   (E_Name:'=tASIN ';E_Value:153),
   (E_Name:'=tATAN ';E_Value:155),
   (E_Name:'=tAUTO ';E_Value:238),
   (E_Name:'=tBASE ';E_Value:233),
   (E_Name:'=tBEEP ';E_Value:232),
   (E_Name:'=tBIG  ';E_Value:16),
   (E_Name:'=tCALL ';E_Value:249),
   (E_Name:'=tCARD ';E_Value:208),
   (E_Name:'=tCAT  ';E_Value:236),
   (E_Name:'=tCEIL ';E_Value:114),
   (E_Name:'=tCFLAG';E_Value:250),
   (E_Name:'=tCHR$ ';E_Value:164),
   (E_Name:'=tCLOCK';E_Value:328175),
   (E_Name:'=tCMPLX';E_Value:122),
   (E_Name:'=tCOLON';E_Value:226),
   (E_Name:'=tCOMMA';E_Value:241),
   (E_Name:'=tCOPY ';E_Value:181),
   (E_Name:'=tCOS  ';E_Value:151),
   (E_Name:'=tCVAL ';E_Value:225),
   (E_Name:'=tDATA ';E_Value:198),
   (E_Name:'=tDATE ';E_Value:119),
   (E_Name:'=tDATE$';E_Value:120),
   (E_Name:'=tDEF  ';E_Value:185),
   (E_Name:'=tDEG  ';E_Value:111),
   (E_Name:'=tDEGRE';E_Value:211),
   (E_Name:'=tDELAY';E_Value:214),
   (E_Name:'=tDELET';E_Value:183),
   (E_Name:'=tDIM  ';E_Value:204),
   (E_Name:'=tDISP ';E_Value:197),
   (E_Name:'=tDIV  ';E_Value:134),
   (E_Name:'=tDMYAR';E_Value:126),
   (E_Name:'=tDSTRY';E_Value:190),
   (E_Name:'=tDVZ  ';E_Value:177),
   (E_Name:'=tEDIT ';E_Value:184),
   (E_Name:'=tELSE ';E_Value:245),
   (E_Name:'=tEND  ';E_Value:218),
   (E_Name:'=tENDDF';E_Value:186),
   (E_Name:'=tENDSB';E_Value:194),
   (E_Name:'=tENTER';E_Value:327663),
   (E_Name:'=tEOL  ';E_Value:240),
   (E_Name:'=tEPS  ';E_Value:113),
   (E_Name:'=tERRL ';E_Value:117),
   (E_Name:'=tERRN ';E_Value:118),
   (E_Name:'=tERROR';E_Value:227),
   (E_Name:'=tEXOR ';E_Value:140),
   (E_Name:'=tEXP  ';E_Value:148),
   (E_Name:'=tEXTIF';E_Value:244),
   (E_Name:'=tEXTND';E_Value:393711),
   (E_Name:'=tFACT ';E_Value:168),
   (E_Name:'=tFETCH';E_Value:200),
   (E_Name:'=tFFN  ';E_Value:180),
   (E_Name:'=tFLOW ';E_Value:590319),
   (E_Name:'=tFLT1 ';E_Value:29),
   (E_Name:'=tFLT10';E_Value:20),
   (E_Name:'=tFLT11';E_Value:19),
   (E_Name:'=tFLT12';E_Value:18),
   (E_Name:'=tFLT2 ';E_Value:28),
   (E_Name:'=tFLT3 ';E_Value:27),
   (E_Name:'=tFLT4 ';E_Value:26),
   (E_Name:'=tFLT5 ';E_Value:25),
   (E_Name:'=tFLT6 ';E_Value:24),
   (E_Name:'=tFLT7 ';E_Value:23),
   (E_Name:'=tFLT8 ';E_Value:22),
   (E_Name:'=tFLT9 ';E_Value:21),
   (E_Name:'=tFN   ';E_Value:124),
   (E_Name:'=tFOR  ';E_Value:195),
   (E_Name:'=tFP   ';E_Value:107),
   (E_Name:'=tGOSUB';E_Value:220),
   (E_Name:'=tGOTO ';E_Value:221),
   (E_Name:'=tIF   ';E_Value:223),
   (E_Name:'=tIMAGE';E_Value:255),
   (E_Name:'=tIN   ';E_Value:242),
   (E_Name:'=tINF  ';E_Value:112),
   (E_Name:'=tINPUT';E_Value:201),
   (E_Name:'=tINT  ';E_Value:156),
   (E_Name:'=tINT10';E_Value:4),
   (E_Name:'=tINT11';E_Value:3),
   (E_Name:'=tINT12';E_Value:2),
   (E_Name:'=tINT2 ';E_Value:12),
   (E_Name:'=tINT3 ';E_Value:11),
   (E_Name:'=tINT4 ';E_Value:10),
   (E_Name:'=tINT5 ';E_Value:9),
   (E_Name:'=tINT6 ';E_Value:8),
   (E_Name:'=tINT7 ';E_Value:7),
   (E_Name:'=tINT8 ';E_Value:6),
   (E_Name:'=tINT9 ';E_Value:5),
   (E_Name:'=tINTEG';E_Value:202),
   (E_Name:'=tINTO ';E_Value:917999),
   (E_Name:'=tINTR ';E_Value:5631),
   (E_Name:'=tINX  ';E_Value:178),
   (E_Name:'=tIP   ';E_Value:106),
   (E_Name:'=tIS   ';E_Value:231),
   (E_Name:'=tISUB$';E_Value:167),
   (E_Name:'=tIVL  ';E_Value:174),
   (E_Name:'=tKEY  ';E_Value:229),
   (E_Name:'=tKEY$ ';E_Value:115),
   (E_Name:'=tKEYS ';E_Value:207),
   (E_Name:'=tLBLRF';E_Value:14),
   (E_Name:'=tLBLST';E_Value:246),
   (E_Name:'=tLEN  ';E_Value:169),
   (E_Name:'=tLET  ';E_Value:192),
   (E_Name:'=tLINE#';E_Value:15),
   (E_Name:'=tLINPT';E_Value:191),
   (E_Name:'=tLIST ';E_Value:187),
   (E_Name:'=tLITRL';E_Value:196),
   (E_Name:'=tLN   ';E_Value:145),
   (E_Name:'=tLOG  ';E_Value:144),
   (E_Name:'=tLOG10';E_Value:147),
   (E_Name:'=tLPRP ';E_Value:170),
   (E_Name:'=tLR   ';E_Value:182),
   (E_Name:'=tMAIN ';E_Value:210),
   (E_Name:'=tMATH ';E_Value:393711),
   (E_Name:'=tMAX  ';E_Value:173),
   (E_Name:'=tMAXRL';E_Value:108),
   (E_Name:'=tMEAN ';E_Value:157),
   (E_Name:'=tMIN  ';E_Value:172),
   (E_Name:'=tMOD  ';E_Value:116),
   (E_Name:'=tNAME ';E_Value:189),
   (E_Name:'=tNEAR ';E_Value:786927),
   (E_Name:'=tNEG  ';E_Value:852463),
   (E_Name:'=tNEXT ';E_Value:196),
   (E_Name:'=tNOT  ';E_Value:129),
   (E_Name:'=tNUM  ';E_Value:163),
   (E_Name:'=tOFF  ';E_Value:225),
   (E_Name:'=tON   ';E_Value:224),
   (E_Name:'=tOPT''N';E_Value:237),
   (E_Name:'=tOR   ';E_Value:141),
   (E_Name:'=tOVF  ';E_Value:175),
   (E_Name:'=tPAUSE';E_Value:215),
   (E_Name:'=tPCRD ';E_Value:917999),
   (E_Name:'=tPI   ';E_Value:121),
   (E_Name:'=tPORT ';E_Value:209),
   (E_Name:'=tPOS  ';E_Value:131507),
   (E_Name:'=tPREDV';E_Value:159),
   (E_Name:'=tPRINT';E_Value:205),
   (E_Name:'=tPRMEN';E_Value:248),
   (E_Name:'=tPRMST';E_Value:243),
   (E_Name:'=tPURGE';E_Value:235),
   (E_Name:'=tRAD  ';E_Value:110),
   (E_Name:'=tRDIAN';E_Value:212),
   (E_Name:'=tREAD ';E_Value:199),
   (E_Name:'=tREAL ';E_Value:188),
   (E_Name:'=tRELOP';E_Value:138),
   (E_Name:'=tREM  ';E_Value:230),
   (E_Name:'=tRES  ';E_Value:127),
   (E_Name:'=tRESTR';E_Value:222),
   (E_Name:'=tRETRN';E_Value:219),
   (E_Name:'=tRFILE';E_Value:222),
   (E_Name:'=tRMD  ';E_Value:109),
   (E_Name:'=tRND  ';E_Value:160),
   (E_Name:'=tROUND';E_Value:786927),
   (E_Name:'=tRUN  ';E_Value:254),
   (E_Name:'=tSDEV ';E_Value:158),
   (E_Name:'=tSEMIC';E_Value:242),
   (E_Name:'=tSFLAG';E_Value:251),
   (E_Name:'=tSGN  ';E_Value:161),
   (E_Name:'=tSHORT';E_Value:203),
   (E_Name:'=tSIN  ';E_Value:150),
   (E_Name:'=tSMALL';E_Value:17),
   (E_Name:'=tSQR  ';E_Value:146),
   (E_Name:'=tSTAT ';E_Value:206),
   (E_Name:'=tSTEP ';E_Value:246),
   (E_Name:'=tSTOP ';E_Value:217),
   (E_Name:'=tSTR$ ';E_Value:166),
   (E_Name:'=tSUB  ';E_Value:193),
   (E_Name:'=tSVAR ';E_Value:45),
   (E_Name:'=tTAB  ';E_Value:247),
   (E_Name:'=tTAN  ';E_Value:152),
   (E_Name:'=tTHEN ';E_Value:244),
   (E_Name:'=tTIME ';E_Value:123),
   (E_Name:'=tTIME$';E_Value:149),
   (E_Name:'=tTIMER';E_Value:228),
   (E_Name:'=tTO   ';E_Value:243),
   (E_Name:'=tTRACE';E_Value:234),
   (E_Name:'=tUNF  ';E_Value:176),
   (E_Name:'=tUPRC$';E_Value:171),
   (E_Name:'=tUSER ';E_Value:226),
   (E_Name:'=tUSING';E_Value:253),
   (E_Name:'=tVAL  ';E_Value:165),
   (E_Name:'=tVARS ';E_Value:721391),
   (E_Name:'=tWAIT ';E_Value:216),
   (E_Name:'=tXFN  ';E_Value:179),
   (E_Name:'=tXWORD';E_Value:239),
   (E_Name:'=tZ    ';E_Value:90),
   (E_Name:'=tZERO ';E_Value:786927),
   (E_Name:'=t^    ';E_Value:128),
   (E_Name:'=uALit ';E_Value:247),
   (E_Name:'=uCPLXC';E_Value:238),
   (E_Name:'=uDELIM';E_Value:244),
   (E_Name:'=uHKB^ ';E_Value:246),
   (E_Name:'=uIMXCH';E_Value:212),
   (E_Name:'=uIMbck';E_Value:220),
   (E_Name:'=uIMend';E_Value:240),
   (E_Name:'=uIMsta';E_Value:222),
   (E_Name:'=uJMPdl';E_Value:219),
   (E_Name:'=uJMPst';E_Value:218),
   (E_Name:'=uJMP{}';E_Value:217),
   (E_Name:'=uLOOPB';E_Value:210),
   (E_Name:'=uLOOPP';E_Value:239),
   (E_Name:'=uLOOPS';E_Value:211),
   (E_Name:'=uMODES';E_Value:48561),
   (E_Name:'=uMULT ';E_Value:209),
   (E_Name:'=uNUMEn';E_Value:252),
   (E_Name:'=uNUMEs';E_Value:253),
   (E_Name:'=uNUMFn';E_Value:250),
   (E_Name:'=uNUMFs';E_Value:251),
   (E_Name:'=uNUMNn';E_Value:248),
   (E_Name:'=uNUMNs';E_Value:249),
   (E_Name:'=uOPNM-';E_Value:223),
   (E_Name:'=uOPNNM';E_Value:216),
   (E_Name:'=uOPNWM';E_Value:224),
   (E_Name:'=uRES12';E_Value:51604),
   (E_Name:'=uRESD1';E_Value:57838),
   (E_Name:'=uRESNX';E_Value:51645),
   (E_Name:'=uRESTP';E_Value:241),
   (E_Name:'=uRESXT';E_Value:51649),
   (E_Name:'=uRND>P';E_Value:51663),
   (E_Name:'=uSTRPT';E_Value:208),
   (E_Name:'=uTEST ';E_Value:54325),
   (E_Name:'=xANGLE';E_Value:6),
   (E_Name:'=xCLOCK';E_Value:21),
   (E_Name:'=xEXTND';E_Value:38),
   (E_Name:'=xFLOW ';E_Value:41),
   (E_Name:'=xINTO ';E_Value:46),
   (E_Name:'=xMATH ';E_Value:54),
   (E_Name:'=xNEAR ';E_Value:60),
   (E_Name:'=xNEG  ';E_Value:61),
   (E_Name:'=xPCRD ';E_Value:62),
   (E_Name:'=xPOS  ';E_Value:66),
   (E_Name:'=xROUND';E_Value:76),
   (E_Name:'=xVARS ';E_Value:91),
   (E_Name:'=xZERO ';E_Value:28),
   (E_Name:'       ';E_VALUE:0),
   (E_Name:'       ';E_VALUE:0),
   (E_Name:'       ';E_VALUE:0),
   (E_Name:'       ';E_VALUE:0),
   (E_Name:'       ';E_VALUE:0),
   (E_Name:'       ';E_VALUE:0),
   (E_Name:'       ';E_VALUE:0),
   (E_Name:'       ';E_VALUE:0)
   );


var    ROOT            : ref;
       PASS1,LAST_REQ,DONE,TOLIST,F_LSET,F_RETY,
       F_GOYS,F_ABSL,F_EXPR,F_GSUB,FIRST,TOKEXIST,
       EXPR_ERR,ALREADY_ERR,NOLIST,OBJECTFILE_EXISTS,
       LISTFILE_EXISTS,SOURCE_EXISTS     : boolean;

       ERRORCOUNT,SLINE_NR,LLINE_NR,PAGENO,OPTYPE,OPLEN,
       HITOK,LOTOK,PAGESIZE,FILL_MARK,FILL_LENGTH,ORD0,
       ORDA,TENT,KENT           : integer;
       { DOTCOUNT : integer ; }

       GETCHCOUNT: integer;
       GCH:        char;

       LC       : LongInt;
       FILESIZE : LongInt;
       REF_OPT  : integer;
       STRICT_OPT: integer;
       TESTMODE : boolean;
       FILETYPE : filtyp;
       KNOWN    : syttyp;
       DECHEX   : array[0..15] of char;
       TIT,STIT : string40;
       SFILE,
       LFILE,
       OFILE    : string80;
       SLINE    : string96;
       LLINE    : string96;
       LABEL_FIELD,
       OPCODE_FIELD: string50;
       EXPR_FIELD,
       OLD_EXPR : string50;
       SOURCE,
       LIST     : text;
       OBJECTF  : file of byte;
       OPTINDEX : array[0..MAXOPCIND] of integer;
       OP       : array[1..18] of nib;
       TIMEVAR  : string10;
       DATEVAR  : string10;
       OUTBYTE  : byte;
       OUTFILLED: boolean;

(*ASM71ERR.INC*)


function ERRMSG(ERRNO: integer):string50;

var E:string[50];

begin
     case ERRNO of
     1002: E:='File not found';
     1003: E:='Path not found';
     1004: E:='Too many open files';
     1005: E:='File access denied';
     1006: E:='Invalid file handle';
     1012: E:='Invalid file access code';
     1015: E:='Invalid drive number';
     1016: E:='Cannot remove current directory';
     1017: E:='Cannot rename across drives';
     1018: E:='Error in numeric Format';
     1100: E:='Disk read error';
     1101: E:='Disk write error';
     1102: E:='File not assigned';
     1103: E:='File not open';
     1104: E:='File not open for input';
     1105: E:='File not open for output';
     1106: E:='Invalid numeric format';

     1200: E:='Runtime error: Division by zero';
     1201: E:='Runtime error: Range check error';
     1202: E:='Runtime error: Stack overflow';
     1203: E:='Runtime error: Heap overflow';
     1204: E:='Runtime error: Invalid pointer operation';
     1205: E:='Runtime error: Floating point overflow';
     1206: E:='Runtime error: Floating point underflow';
     1207: E:='Runtime error: Invalid floating point operation';
     1208: E:='Runtime error: Overlay manager not installed';
     1209: E:='Runtime error: Overlay file read error';

     20: E:= 'Unknown opcode';
     21: E:= 'GOYES or RTNYES required';
     22: E:= 'Missing/illegal label';
     23: E:= 'Invalid listing argument';
     24: E:= 'Invalid quoted string';
     26: E:= 'Invalid HP-71 filename specifier';
     27: E:= 'Illegal word select';
     28: E:= 'Jump or value too large';
     29: E:= 'Needs previous test instruction';
     30: E:= 'Illegal pointer position';
     31: E:= 'Illegal status bit';
     32: E:= 'Illegal dp arithmetic value';
     33: E:= 'Illegal transfer value';
     34: E:= 'Non-hexadecimal digit present';
     35: E:= 'Too many hexadecimal digits present';
     36: E:= 'Unrecognized label';
     37: E:= 'Mismatched parantheses';
     38: E:= 'Illegal expression';
     39: E:= 'Excess characters in expression';
     41: E:= 'Duplicate label';
     51: E:= 'Missing/multiple filetype';
     56: E:= 'Assembler aborted';
     57: E:= 'Cannot resolve equate';
     58: E:= 'Pagesize too small';
     61: E:= 'Restricted label FiLeNd exists';
     62: E:= 'Illegal pagesize';
     63: E:= 'Cannot open source file';
     64: E:= 'Cannot erase object file';
     65: E:= 'Cannot output object code';
     66: E:= 'Cannot read source line';
     68: E:= 'Cannot open object file';
     69: E:= 'Cannot write to list file';
     70: E:= 'in line: ';
     71: E:= 'Cannot reset source file';
     72: E:= '**** SYMBOL TABLE *****';
     73: E:= ' Source : ';
     74: E:= ' Object : ';
     75: E:= 'Listing : ';
     76: E:= '   Date : ';
     77: E:= ' on ';
     78: E:= ' Errors : ';
     79: E:= 'Decimal constant overflow';
     80: E:= 'Hexadecimal constant overflow';
     81: E:= 'Ascii constant overflow';
     82: E:= 'Illegal symbol';
     83: E:= 'Expression overflow';
     84: E:= 'Cannot open ASM71.TBL';
     85: E:= 'Cannot read ASM71.TBL';
     86: E:= 'Excess characters in label field';
     87: E:= 'Excess characters in opcode filed';
     88: E:= 'Page ';
     89: E:= 'purged';
     90: E:= 'Source Lines : ';
     91: E:= 'Illegal commandline option';
     92: E:= 'Cannot access ASM71ENT.TBL';
     93: E:= 'External symbol definition not allowed';
     else
         E:= 'Unclassified error condition';
     end;
     ERRMSG:= E
end;

(* ASM71IO.INC*)


function NTOHEX(I:LongInt;LEN: integer; TYP: sfilltyp): string10;
var ST: string10;
begin
     ST:='';
     while I <> 0 do begin
           ST:= DECHEX [I mod 16] + ST;
           I:= I div 16
           end;
     while length(ST) < LEN do
           if TYP = ZFILL then ST:= '0'+ ST
           else ST:= ' '+ ST;
     NTOHEX:= ST
end;

function NTODEC(I,LEN: integer; TYP: sfilltyp): string10;
var ST: string10;

begin
     str(I,ST);
     while length(ST) < LEN do
           if TYP = ZFILL then ST:= '0'+ ST
           else ST:= ' '+ ST;
     NTODEC:= ST
end;

procedure HALTASM;

begin 
      if SOURCE_EXISTS then close(SOURCE);
      if LISTFILE_EXISTS then close(LIST);
      if OBJECTFILE_EXISTS then begin
         close(OBJECTF);
         assign(OBJECTF,OFILE);
         erase(OBJECTF);
      end;
      writeln(errmsg(56));
      HALT(1)
end;

procedure RUNSTRING;

const MaxOptions = 3;

var OPTION: array[1.. MaxOptions] of record
                                Key: char;
                                Val: integer;
                                Min: integer;
                                Max: integer;
                                end;

    RUNST: string[100];
    TEMP:  string40;

procedure GET_OPTIONS;
label 99;

var L,J,I,K: integer;
    Value: integer;
    Ch: char;
    Nichts: boolean;

begin
   with OPTION[1] do begin Key:= 'L'; Val:=63;Min:=8;Max:=Maxint;end;
   with OPTION[2] do begin Key:= 'R'; Val:=1;Min:=0;Max:=2;end;
   with OPTION[3] do begin Key:= 'S'; Val:=0;Min:=0;Max:=1;end;
   L:= length(Temp); J:=1;
   while J < L do begin
      ch:= Temp[J];
      if ch = ' ' then Exit;
      for I:= 1 to MaxOptions do begin
          if ch = Option[I].Key then begin
              K:= I;
              goto 99
          end
      end;
      writeln(Errmsg(91));
      Halt;
   99:Value:=0;
      J:=J+1;
      Nichts:= true;
      while Temp[J] in ['0'..'9'] do begin
         Value:= Value*10 + ord(Temp[J])- ord('0');
         J:=j+1;
         Nichts:= false
      end;
      if Nichts or (Value < Option[K].Min) or (Value > Option[K].Max) then begin
          writeln(Errmsg(91));
          Halt
      end;
      Option[K].VAL:= Value
   end;
end;

function GETPAR: string80;
   var I: integer;
       PAR: string80;

begin
      I:=POS(',',RUNST);
      if I = 0 then begin
         PAR:= RUNST;
         RUNST:=''
         end
      else begin
         PAR:= copy(RUNST,1,I-1);
         delete(RUNST,1,I)
         end;
      GETPAR:= PAR;
end;


begin
  RUNST:= paramstr(1);
  SFILE:= GETPAR;
  OFILE:= GETPAR;
  LFILE:= GETPAR;
  TEMP:= GETPAR+' ';
{  if SFILE='' then begin
      writeln(ERRMSG(63));
      haltasm
      end;}
  if pos('.',SFILE) = 0 then SFILE:= SFILE+'.asm';
  if pos('.',OFILE)<> 0 then OFILE:=copy(OFILE,1,pos('.',OFILE)-1);
  if (LFILE <> '') and(  pos('.',LFILE)=0) then LFILE:= LFILE+'.lst';
  if (OFILE ='') then OFILE:= copy(SFILE,1,pos('.',SFILE)-1);
  Get_Options;
  PageSize:= Option[1].Val;
  Ref_Opt:=  Option[2].Val;
  Strict_Opt:= Option[3].Val;
  if LFILE = '' then Ref_Opt:=0
end;


procedure IO_ERROR(IMESS,IOS: integer);

begin
     if IOS <> 0 then begin
        writeln(ERRMSG(IMESS),' --- ',ERRMSG(IOS+1000));
        HALTASM;
     end;
end;

procedure OUT_OBJ;
var I: integer;
    OPC_NIB: nib;

begin 
      if OPLEN > 0 then
         for I:= 1 to OPLEN do begin
             if I > 18 then OPC_NIB:= 0
             else OPC_NIB:= OP[I];
             if OUTFILLED then begin
                OUTBYTE:= OPC_NIB;
                OUTFILLED:= false
             end else begin
                OUTBYTE:= OUTBYTE or (OPC_NIB shl 4);
{$I-}
                write(OBJECTF,OUTBYTE);
                IO_ERROR(65,IoResult);
{$I+}
                OUTFILLED:= true
             end;
         end;
end; 

procedure READ_SOURCE;

begin 
{$I-}
     readln(SOURCE,SLINE);
     SLINE_NR:= SLINE_NR+ 1;
     IO_ERROR(66,IoResult)
{$I+}
end; 

procedure LIST_INIT;

begin 
      if LFILE = '' then NOLIST:= true
      else begin
           if PAGESIZE < 8 then begin
              writeln(ERRMSG(58));
              HALTASM
              end;
{$I-}
           assign(LIST,LFILE);
           IO_ERROR(67,IoResult);
           rewrite(LIST);
           NOLIST:= false;
           IO_ERROR(67,IoResult);
{$I+}
           LISTFILE_EXISTS:= true;
      end
end; 

procedure OPEN_SOURCE;

begin 
{$I-}
     assign(SOURCE,SFILE);
     reset(SOURCE);
     IO_ERROR(63,IoResult);
{$I+}
     SOURCE_EXISTS:=true;
end; 

procedure OBJ_INIT;

begin 
{$I-}
      assign(OBJECTF,OFILE);
      rewrite(OBJECTF);
      IO_ERROR(68,IoResult);
{$I+}
      OUTFILLED:=true;
      OBJECTFILE_EXISTS:= true;
end; 

procedure EJECT; forward;

procedure outline(LLINE: string96);

begin 
      if TOLIST and ( not NOLIST) then begin
{$I-}
         writeln(List,LLINE);
         IO_ERROR(69,IoResult);
{$I+}
         LLINE_NR:= LLINE_NR + 1;
         if LLINE_NR > PAGESIZE then EJECT
      end
end; 

procedure EJECT;

begin
     if TOLIST and ( not NOLIST) then begin
        LLINE_NR:= 0;
        PAGENO:= PAGENO +1;
        OUTLINE(#12);
        OUTLINE(ERRMSG(88)+NTODEC(PAGENO,4,ZFILL)+
                '         '+TIT);
        OUTLINE('HP-71 Assembler   '+STIT);
        OUTLINE(' ')
     end
end;

procedure OUTPUT_LIST;
var NLOOP,ICNT: integer;
    TLC: LongInt;
    LOP: LongInt;
    I,J: integer;

begin
     if TOLIST and ( not NOLIST) then begin
        TLC:= LC;
        ICNT:= 1;
        if OPLEN > 24 then NLOOP:=24 else NLOOP:= OPLEN;
        NLOOP:= (NLOOP+7) div 8;
        if NLOOP = 0 then NLOOP:=1;
        for I:= 1 to NLOOP do begin
            if I = 1 then LLINE:= NTODEC(SLINE_NR,4,ZFILL)+' '
            else LLINE:='     ';
            LLINE:= LLINE+ NTOHEX(TLC,5,ZFILL)+ ' ';
            for J:= ICNT to ICNT+7 do
                if J > OPLEN then LLINE:= LLINE+ ' '
                else if J > 17 then LLINE:= LLINE+ '0'
                else begin
                   LOP:= OP[J];
                   LLINE:= LLINE+ NTOHEX(LOP,1,ZFILL);
                end;
            if I = 1 then LLINE:= LLINE+ '  '+ SLINE;
            TLC:= TLC+ 8;
            ICNT:= ICNT+8;
            OUTLINE(LLINE)
        end
     end
end;

procedure ERROR(ERRNUM: integer);

begin
     ERRORCOUNT:= ERRORCOUNT+1;
     if TOLIST and ( not NOLIST) then begin
        if not ALREADY_ERR then begin
           OUTLINE(' ');
           ALREADY_ERR:= true
        end;
        OUTLINE('* '+ERRMSG(ERRNUM))
        end
     else  begin
        writeln;
        writeln(ERRMSG(ERRNUM),' ',ERRMSG(70),SLINE_NR:4)
     end
end;

procedure RESET_SOURCE;

begin 
{$I-}
      reset(SOURCE);
      IO_ERROR(71,IoResult)
{$I+}
end; 

procedure FILL_OBJECT;
var i,j: integer;

begin 
   if not outfilled then begin
{$I-}
      write(objectf,outbyte);
      io_error(68,ioresult);
      FILESIZE:=FILESIZE+1
   end;
   I:= 256 - (((FILESIZE - 64) DIV 2) mod 256);
   outbyte:=$20;
   for j:= 1 to i do begin
      write(objectf,outbyte);
      io_error(68,ioresult);
   end;
   { fill object file }
end; 


procedure CLEANUP;

begin 
      FILL_OBJECT;
      close(SOURCE);
      if LISTFILE_EXISTS then close(LIST);
      close(OBJECTF);
      if ERRORCOUNT > 0 then begin
{$I-}
         assign(OBJECTF,OFILE);
         erase(OBJECTF);
         OFILE:= ERRMSG(89);
         IO_ERROR(64,IOResult);
{$I+}
      end;  
      writeln;writeln;
      writeln(ERRMSG(73)+ SFILE);
      writeln(ERRMSG(74)+ OFILE);
      writeln(ERRMSG(75)+ LFILE);
      writeln;
      writeln(ERRMSG(90),SLINE_NR:6,' ':10,ERRMSG(78),ERRORCOUNT:5);
end;

(* ASM71TD.INC*)

procedure GET_TIME_DATE;

function GET_Date: string10;


var
  y,m,d:         word;
  month,day:     string[2];
  year:          string[4];

begin
  DecodeDate(Date,y,d,m);
  year:= NTODEC(y,2,ZFILL);
  day:= NTODEC(d,2,ZFILL);
  month:= NTODEC(m,2,ZFILL);
  GET_Date := month+'/'+day+'/'+year;
end;


function Get_Time: string10;

var
  h,m,s,ms    :  word;
  hour,min,sec:  string[2];

begin
  DecodeTime(Time,h,m,s,ms);
  MIN:= NTODEC(m,2,ZFILL);
  HOUR:=NTODEC(h,2,ZFILL);
  SEC:= NTODEC(s,2,ZFILL);
  GET_time := hour+':'+min+':'+sec;
end;

begin
   if(TESTMODE) then
   begin
      TIMEVAR:='00:00:00';
      DATEVAR:='01/01/2000';
   end else begin
      TIMEVAR:= GET_TIME;
      DATEVAR:= GET_DATE;
   end;
end;
(* ASM71SYT.INC*)


procedure SYT_INIT;

begin
     ROOT:= nil;
end;

function LABEL_OK(SNAME:string7): boolean;
var FLAG: boolean;

begin
     {if SNAME[1] = '='then delete(SNAME,1,1);}
     FLAG:= SNAME[1] in ['#','''','(','1','2','3','4','5','6',
                         '7','8','9','0','-'];
     FLAG:= FLAG or (POS(',',SNAME) <> 0);
     FLAG:= FLAG or (POS(')',SNAME) <> 0);
     LABEL_OK:= not FLAG
end;

procedure PUT_SYT(SNAME:string7;SVALUE:LongInt;STYP:SYTTYP);

procedure SYT_INSERT(SNAME:string7; var P:ref);

begin
          if P = nil then begin
             new(P);
             with P^ do begin
                  NAME:= SNAME;
                  VALUE:= SVALUE;
                  TYP:= STYP;
                  FIRSTREF:= nil;
                  LASTREF:= nil;
                  LEFT:= nil;
                  RIGHT:= nil
                  end;
             { writeln('SYT_INSERT -- inserted: ',P^.NAME); }
             end
          else begin
               { writeln('SYT_INSERT -- compare with :',P^.NAME); }
               if SNAME < P^.NAME then SYT_INSERT(SNAME,P^.LEFT)
               else if SNAME > P^.NAME then SYT_INSERT(SNAME,P^.RIGHT)
               end
end;

begin
     { writeln('PUT_SYT >'+SNAME+'<'); }
     if LABEL_OK(SNAME) then begin
        { if SNAME[1] <> '=' then SYT_INSERT(SNAME,ROOT) }
        SYT_INSERT(SNAME,ROOT) 
        end
end;

function SYT_SEARCH(SNAME:string7; P:ref): REF;
var FOUND: boolean;

begin
   FOUND:= false;
   { writeln('SYT_SEARCH >'+SNAME+'<');  }
   while (P <> nil) and (not FOUND) do begin
      { writeln('compare with >'+P^.NAME+'<'); }  
      if P^.NAME = SNAME then FOUND:= true
      else if P^.NAME> SNAME then P:= P^.LEFT else P:= P^.RIGHT
      end;
   { writeln('SYT_SEARCH -- FOUND ' ,FOUND); }
   SYT_SEARCH:=P
end;


function Entry_Search(Name:string7):integer;
var l,r,m : integer;
    nam: string7;

begin
  {for l:= 1 to 7 do nam[l]:= name[l];}
  nam:=name;
  l:=1;
  r:= N_Entries;
  if Nam = Ext_Entry[r].E_Name then begin
     Entry_Search:= r;
     Exit
  end;
  while (l<>r) do begin
     m:= (l+r) div 2;
     if Nam < Ext_Entry[m].E_Name then r:=m
     else if Nam > Ext_Entry[m].E_Name then l:=m+1
     else begin
        Entry_Search:= m;
        Exit
     end;
  end;
  Entry_Search:=0
end;


procedure ENTER_REF (P: Ref;SLine_Nr: integer);
var T:LRef;

begin
   with P^ do begin
      if LASTREF <> nil then begin
         if LASTREF^.LineNo = Sline_Nr then Exit;
      end;
      new(T);
      if FIRSTREF = nil then begin
         FIRSTREF:= T;
         T^.NextRef:= nil;
         T^.LineNo:= Sline_NR;
         LASTREF:= T
      end else begin
         T^.NextRef:= nil;
         T^.LineNo:= Sline_NR;
         LASTREF^.NEXTREF:= T;
         LASTREF:= T
      end
   end
end;

function GET_SYT(SNAME: string7): LongInt;
var P: ref;
    I: integer;
    VALUE: LongInt;

begin
     { writeln('GET SYT >'+SNAME+'<'); }
     VALUE:= 0;
     KNOWN:= NOTFOUND;
     if SNAME[1] = '=' then begin  { external Symbol found }
        P:= SYT_SEARCH(SNAME,ROOT);{ search Entry in Symbol Table }
        if P= nil then begin       { not found in Table }
           I:= ENTRY_SEARCH(SNAME);{ search in external Entry Table }
           { writeln('GET_SYT -- SNAME,I : ',SNAME,' ',I); }
           if I <> 0 then begin { something found in external Entry Table }
              VALUE:= Ext_Entry[i].E_Value;
              { writeln('GET_SYT -- Value : ',Value); }
              PUT_SYT(SNAME,Value,EXTERN); { put sym into Symbol Table }
              KNOWN:= EXTERN;
              if (not PASS1) and (REF_OPT=2) then begin
                 { writeln('GET_SYT -- SEARCH FOR ',SNAME); }
                 P:= SYT_SEARCH(SNAME,ROOT);
                 ENTER_REF(P,SLINE_NR);
              end;
           end else begin { not found }
              delete(SNAME,1,1);  { change to local symbol }
              SNAME:=SNAME+' ';
           end
        end
        else begin { external symbol found in symbol table }
           VALUE:=P^.VALUE;
           KNOWN:= P^.TYP;
           if (not PASS1) and (REF_OPT=2) then ENTER_REF(P,SLINE_NR)
        end
     end;
     if KNOWN= NOTFOUND then begin { search non external symbol }
        P:=SYT_SEARCH(SNAME,ROOT);
        if P= nil then begin
           VALUE:= 0;
           KNOWN:= NOTFOUND
        end else begin
           VALUE:=P^.VALUE;
           KNOWN:= P^.TYP;
           if (not PASS1) and (REF_OPT=2) then ENTER_REF(P,SLINE_NR)
        end
     end;
     GET_SYT:=VALUE;
end;


procedure OUT_SYT;
var I: integer;
    T: string[9];

procedure printtree(P:ref);
     var 
         I: integer;
         R: Lref;
begin
          if P <> nil then
             with P^ do begin
                  PRINTTREE(LEFT);
                  LLINE:=NAME;
                  { while length (LLINE) < 7 do LLINE:= LLINE+' '; }
                  LLINE:= LLINE+'  ';
                  case TYP of
         EXTERN:  LLINE:= LLINE+'Ext ';
         LABL  :  LLINE:= LLINE+'Rel ';
                  else  LLINE:= LLINE+ 'Abs ';
                  end;
                  str(VALUE:9,T);
                  LLINE:= LLINE+ T ;
                  { if VALUE < 0 then VALUE:= MAXNUM +  VALUE; }
                  LLINE:= LLINE + ' #'+ NTOHEX(VALUE,5,ZFILL)+ ' -';
                  if REF_OPT = 2 then begin
                     I:=0;
                     R:= FIRSTREF;
                     while R <> nil do begin
                        if I = 8 then begin
                           I:=0;
                           OUTLINE(LLINE);
                           LLINE:='                              -'
                        end;
                        str(R^.LineNo:6,T);
                        LLINE:=LLINE+T;
                        I:=I+1;
                        R:=R^.NextRef;
                     end;
                  end;
                  OUTLINE(LLINE);
                  PRINTTREE(RIGHT)
                  end
end;

begin
     if REF_OPT <> 0 then begin
        STIT:= ERRMSG(72);
        EJECT;
        PRINTTREE(ROOT);
     end;
     STIT:='';
     for I:= 1 to 6 do OUTLINE(' ');
     LLINE:= ERRMSG(73)+ SFILE;
     OUTLINE(LLINE);OUTLINE(' ');
     LLINE:= ERRMSG(74);
     if ERRORCOUNT > 0 then LLINE:= LLINE+'purged'
     else LLINE:= LLINE+OFILE;
     OUTLINE(LLINE);OUTLINE(' ');
     LLINE:= ERRMSG(75)+ LFILE;
     OUTLINE(LLINE);OUTLINE(' ');
     LLINE:= ERRMSG(76)+TIMEVAR+ERRMSG(77)+DATEVAR;
     OUTLINE(LLINE);OUTLINE(' ');
     LLINE:= ERRMSG(78)+NTODEC(ERRORCOUNT,3,ZFILL);
     OUTLINE(LLINE);
end;
(* ASM71EXP.INC*)


procedure P2ERR(IERR: integer);
begin
   if not PASS1 then ERROR(IERR)
end;

procedure GETCH;
begin
        GETCHCOUNT:= GETCHCOUNT+1;
        if GETCHCOUNT > length(expr_field) then GCH:= chr(255)
        else GCH:= EXPR_FIELD[GETCHCOUNT] ;
end;

function TERM:LongInt; forward;

function BASE :LongInt;
var BVALUE: LongInt;

procedure LOC;

begin
           BVALUE:= LC;
           GETCH
end;

procedure DEC;
      var OVER: boolean;

begin
         BVALUE:= 0;
         OVER:= false;
         repeat
            if not OVER then begin
               BVALUE:= BVALUE*10 + ord(GCH)- ORD0;
               if BVALUE > MAXNUM then begin
                  OVER:= true;
                  BVALUE:= 0;
                  P2ERR(79);
                  EXPR_ERR:= true;
               end
            end;
            GETCH;
         until not (GCH in ['0'..'9'])
end;

procedure HEX;
      var OVER: boolean;

begin
         BVALUE:= 0;
         OVER:= false;
         GETCH;
         if not (GCH in ['0'..'9','A'..'F']) then begin
            P2ERR(34);
            EXPR_ERR:= true
            end
         else repeat
            if not over then begin
               if GCH in ['0'..'9'] then BVALUE:= (BVALUE*16)+
                                        ord(GCH)- ORD0
               else BVALUE:=(BVALUE*16) + ord(GCH)- ORDA;
               if BVALUE > MAXNUM then begin
                  OVER:= true;
                  BVALUE:= 0;
                  P2ERR(80);
                  EXPR_ERR:= true
                  end
            end;
            GETCH;
            until not (GCH in ['0'..'9','A'..'F'])
end;

procedure ASC;
      var OVER: boolean;

begin
         BVALUE:= 0;
         OVER:= false;
         GETCH;
         while GCH <> '''' do begin
            if not OVER then begin
               BVALUE:=(BVALUE*256)+ ord(GCH);
               if BVALUE > MAXNUM then begin
                  OVER:= true;
                  BVALUE:= 0;
                  P2ERR(81);
                  EXPR_ERR:= true
               end
            end;
            GETCH;
            if GCH = chr(255) then begin
               P2ERR(24);
               EXIT
             end
         end;
         GETCH
end;

procedure SYMBOL;
      var SYM: string[7];
          OVER: boolean;

begin
         SYM:='';
         OVER:= false;
         repeat
            if not OVER then begin
               if length(SYM) = 7 then begin
                  OVER:= true;
                  if Strict_Opt = 1 then begin
                     BVALUE:= 0;
                     P2ERR(82);
                     EXPR_ERR:= true; 
                  end
               end
               else SYM:= SYM+ GCH
            end;
            GETCH
          until GCH in [')',' ',chr(255)];
          while length(SYM)< 7 do SYM:= SYM+' ';
          BVALUE:= GET_SYT(SYM);
          if KNOWN= NOTFOUND then begin
             P2ERR(36);
             EXPR_ERR:= true
          end;
          { writeln('SYMBOL -- : ',SYM); }
end;

begin
        case GCH of
        '*'     : LOC;
        '0'..'9': DEC;
        '#'     : HEX;
        ''''    : ASC;
        '('     : begin
                     GETCH;
                     BVALUE:=TERM();
                     if GCH <> ')' then begin
                        P2ERR(37);
                        EXIT
                     end;
                     GETCH;
                  end
        else SYMBOL
        end;
        { writeln('BASE -- VALUE:= ',BVALUE); }
        BASE:= BVALUE;
end;

function unary:LongInt;
var UVALUE: LongInt;
begin
      if GCH= '-' then begin
         GETCH;
         UVALUE:=BASE();
         UVALUE:=-UVALUE
         end
      else UVALUE:=BASE();
      { writeln('UNARY -- VALUE:= ',UVALUE); }
      UNARY:= UVALUE;
end;

function BOOL:LongInt;
   var LOGAND,FIRST,FERTIG: boolean;
       UVALUE:LongInt;
       BVALUE: LongInt;

begin
      FIRST:= true;
      LOGAND:= true;
      repeat
         UVALUE:=UNARY();
         if FIRST then begin
            FIRST:= false;
            BVALUE:= UVALUE;
            end
         else begin
            if LOGAND then begin
               BVALUE:= BVALUE and UVALUE;
               end
            else begin
               BVALUE:= BVALUE or UVALUE;
               end
            end;
         fertig:= true;
         if GCH= '&'then begin
            logand:= true;
            fertig:= false;
            GETCH
            end;
         if GCH='!'then begin
            logand:= false;
            fertig:= false;
            GETCH
            end;
      until fertig;
      { writeln('BOOL -- BVALUE:= ',BVALUE); }
      BOOL:= BVALUE;
end;

function factor:LongInt;
   var times,fertig: boolean;
       BVALUE: LongInt;
       FVALUE: LongInt;

begin
      FVALUE:= 1; 
      TIMES:= true;
      repeat
         BVALUE:=BOOL();
         if TIMES then FVALUE:= FVALUE*BVALUE
         else FVALUE:= FVALUE div BVALUE;
         if FVALUE > MAXNUM then begin
            FVALUE:=0;
            P2ERR(83);
            EXPR_ERR:= true
            end;
         FERTIG:= true;
         if GCH= '*' then begin
            TIMES:= true;
            FERTIG:= false;
            GETCH
            end;
         if GCH= '/' then begin
            TIMES:= false;
            FERTIG:= false;
            GETCH
            end;
      until FERTIG;
      { writeln('FACTOR -- FVALUE:= ',FVALUE); }
      FACTOR:= FVALUE;
end;

function TERM:LongInt;
   var PLUS,FERTIG: boolean;
       TVALUE: LongInt;
       FVALUE: LongInt;

begin
      PLUS:= true;
      TVALUE:= 0; 
      repeat
         FVALUE:=FACTOR();
         if PLUS then TVALUE:= TVALUE+ FVALUE
         else TVALUE:= TVALUE- FVALUE;
         if TVALUE > MAXNUM then begin
            TVALUE:= 0;
            P2ERR(83);
            EXPR_ERR:= true
            end;
         FERTIG:= true;
         if GCH= '+' then begin
            PLUS:= true;
            FERTIG:= false;
            GETCH;
            end;
         if GCH= '-' then begin
            PLUS:= false;
            FERTIG:= false;
            GETCH
            end
      until FERTIG ;
      { writeln('TERM -- TVALUE:= ',TVALUE); }
      TERM:= TVALUE;
end;

function EXPRESSION : LongInt;
var  EXP: LongInt;


begin
   { writeln('EXPRESSION -- : ',EXPR_FIELD); }
   GETCH;
   EXPR_ERR:= false;
   EXP:=TERM();
   if EXPR_ERR then EXP:= 0;
   EXPRESSION:= EXP;
   { writeln('EXPRESSION -- VALUE: ',EXP); }
end;

(* ASM71OPC.INC*)


function FIELD_SELECT:integer;

begin
  if length (EXPR_FIELD) = 2 then begin
     if EXPR_FIELD = 'XS'then FIELD_SELECT:= 3
     else if EXPR_FIELD = 'WP'then FIELD_SELECT:= 2
     else FIELD_SELECT:= 0
     end
  else
     case EXPR_FIELD[1] of
     'A': FIELD_SELECT:= 9;
     'W': FIELD_SELECT:= 8;
     'P': FIELD_SELECT:= 1;
     'B': FIELD_SELECT:= 7;
     'S': FIELD_SELECT:= 5;
     'X': FIELD_SELECT:= 4;
     'M': FIELD_SELECT:= 6;
     else  FIELD_SELECT:= 0
   end
end;

procedure REGTEST;
var FS: integer;

begin
   FS:= FIELD_SELECT;
   if FS = 9 then OP[2]:= FS+ FILL_MARK
   else begin
      OP[1]:=9;
      OP[2]:=FS-1;
      if FILL_MARK = 2 then OP[2]:= OP[2]+8
   end
end;

procedure REGARITH;
var FS: integer;

begin
   if PASS1 then begin
      if EXPR_FIELD='A'then OPLEN:=2
      end
   else begin
      FS:= FIELD_SELECT;
      if FS = 0 then P2ERR(27)
      else begin
         if FS= 9 then begin
            OPLEN:= 2;
            OP[2]:= OP[3];
            OP[1]:= 11+ FILL_MARK
            end
         else begin
            OP[2]:= FS-1;
            if (FILL_MARK in [1,2]) then OP[1]:=10 else OP[1]:=11;
            if (FILL_MARK in [2,4]) then OP[2]:= OP[2]+8
         end
      end
   end
end;

procedure REGLOGIC;
var FS: integer;

begin
   FS:= FIELD_SELECT;
   if FS= 0 then P2ERR(27)
   else begin
      if FS = 9 then OP[3]:= 15 else OP[3]:= FS-1
   end
end;

procedure BRANCHES;
var EX,BASE: LongInt;
   I: integer;

begin
  if F_GOYS and (not LAST_REQ) then P2ERR(29);
  EX:= EXPRESSION();
  if not F_ABSL then begin
     if F_GSUB then EX:= EX-(LC+OPLEN)
     else EX:= EX-(LC+FILL_MARK-1);
     case FILL_LENGTH of
        5: BASE:= 1048576;
        4: BASE:= 65536;
        3: BASE:= 4096;
        2: BASE:= 256;
        1: BASE:= 16;
     end;
     if EX < 0 then EX:= BASE+EX;
     if (EX < 0) or (EX >= BASE) then begin
        P2ERR(28);
        EX:= 0
     end;
  end;
  for I:= FILL_MARK to FILL_MARK+FILL_LENGTH-1 do begin
     OP[I]:= EX and $f;
     EX:= EX  shr 4;
  end
end;

procedure RTNYES;

begin
   if not LAST_REQ then P2ERR(29)
end;

procedure PTRTEST;
var IPOS: integer;

begin
   IPOS:= EXPRESSION();
   if (IPOS < 0) or (IPOS > 15) then P2ERR(30)
   else OP[3]:= IPOS
end;

procedure STATTEST;
var IPOS: integer;

begin
   IPOS:= EXPRESSION();
   if (IPOS < 0) or (IPOS > 15) then P2ERR(31)
   else OP[3]:= IPOS
end;

procedure SETPTR;
var IPOS: integer;

begin
   IPOS:= EXPRESSION();
   if (IPOS < 0) or (IPOS > 15) then P2ERR(30)
   else OP[OPLEN]:= IPOS
end;

procedure SETSTAT;
var IPOS: integer;

begin
   IPOS:= EXPRESSION();
   if (IPOS < 0) or (IPOS > 15) then P2ERR(31)
   else OP[3]:= IPOS
end;

procedure DPARITH;
var IPOS: integer;

begin
   IPOS:= EXPRESSION();
   if (IPOS < 1) or (IPOS > 16) then P2ERR(31)
   else OP[OPLEN]:= IPOS-1
end;

procedure DATATRANS;
var FS: integer;

begin
   if PASS1 then begin
      if (EXPR_FIELD[1] in ['A','B']) then OPLEN:= 3 else OPLEN:=4
      end
   else begin
      FS:= FIELD_SELECT;
      case FS of
      9: begin
         OPLEN:= 3;
         OP[2]:= 4
         end;
      7: begin
         OPLEN:= 3;
         OP[2]:= 4;
         OP[3]:= OP[3]+8
         end;
      0: begin
         FS:= EXPRESSION();
         if (FS < 1) or (FS > 16) then P2ERR(33)
         else begin
            OP[3]:= OP[3]+8;
            OP[4]:= FS-1
            end
         end;
         else OP[4]:= FS-1
      end
   end
end;

procedure NIBHEX;
var I: integer;
   HEXERR: boolean;
   CH: char;

begin
  if PASS1 then begin
     OPLEN:= length(EXPR_FIELD);
     if EXPR_FIELD[1]='#'then OPLEN:= OPLEN -1;
     if OPLEN > 16 then OPLEN:= 16
     end
  else begin
     if EXPR_FIELD[1] = '#' then delete(EXPR_FIELD,1,1);
     OPLEN:= length(EXPR_FIELD);
     if OPLEN> 16 then begin
        P2ERR(35);
        OPLEN:= 16;
        end;
     HEXERR:= false;
     for I:= 1 to OPLEN do begin
        CH:= EXPR_FIELD[I];
        case CH of
        '0'..'9': OP[I]:= ORD(CH)- ORD0;
        'A'..'F': OP[I]:= ORD(CH)- ORDA;
        else begin
           OP[I]:= 0;
           if not HEXERR then begin
              HEXERR:= true;
              P2ERR(34)
              end
           end
        end
     end
  end
end;

procedure LCHEX;
var I,J: integer;
    HEXERR: boolean;
    CH: char;

begin
   if PASS1 then begin
      OPLEN:= length(EXPR_FIELD)+2;
      if EXPR_FIELD[1]='#' then OPLEN:= OPLEN-1;
      if OPLEN > 18 then OPLEN:= 18
      end
   else begin
      if EXPR_FIELD[1]= '#' then delete(EXPR_FIELD,1,1);
      OPLEN:= length(EXPR_FIELD)+2;
      if OPLEN > 18 then begin
         P2ERR(35);
         OPLEN:= 18
         end;
      HEXERR:= false;
      OP[2]:= OPLEN-3;
      J:=1;
      for I:= OPLEN downto 3 do begin
         CH:= EXPR_FIELD[J];
         J:= J+1;
         case CH of
         '0'..'9':OP[I]:= ord(CH)- ORD0;
         'A'..'F':OP[I]:= ord(CH)- ORDA;
         else begin
            OP[I]:= 0;
            if not HEXERR then begin
               HEXERR:= true;
               P2ERR(34)
               end
            end
         end
      end
   end
end;

procedure DX_HEX;
var I,J:integer;
    HEXERR: boolean;
    CH: char;

begin
   if EXPR_FIELD[1]='#' then delete(EXPR_FIELD,1,1);
   if length(EXPR_FIELD) > 2 then begin
      P2ERR(35)
      end;
   HEXERR:= false;
   J:=1;
   for I:= 4 downto 3 do begin
      CH:= EXPR_FIELD[J];
      J:= J+1;
      case CH of
      '0'..'9': OP[I]:= ord(CH)- ORD0;
      'A'..'F': OP[I]:= ord(CH)- ORDA;
      else begin
         OP[I]:=0;
         if not HEXERR then begin
            HEXERR:= true;
            P2ERR(34)
            end
         end
      end
   end
end;

function UNQUOTE(STRINGVAR: string50):string10;
var L: integer;

begin
   L:= length(STRINGVAR);
   if (STRINGVAR[1]='''') and (STRINGVAR[L]='''' ) then begin
      delete(STRINGVAR,L,1);
      delete(STRINGVAR,1,1)
      end
   else P2ERR(24);
   UNQUOTE:= STRINGVAR
end;

procedure NIBASC;
var I,J,K,L: integer;

begin
   if PASS1 then begin
      OPLEN:= length(EXPR_FIELD)*2-4;
      if OPLEN > 16 then OPLEN:= 16
      end
   else begin
      EXPR_FIELD:= UNQUOTE(EXPR_FIELD);
      L:= length(EXPR_FIELD);
      if L> 8 then begin
         P2ERR(36);
         L:=8
         end;
      OPLEN:= L*2;
      J:=1;
      for I:= 1 to L do begin
         K:= ord(EXPR_FIELD[I]);
         OP[J]:= K and 15;
         OP[J+1]:= (K and 240) shr 4;
         J:= J+2
      end
   end
end;

procedure LCASC;
var I,J,K,L: integer;

begin
   if PASS1 then begin
      OPLEN:= length(EXPR_FIELD)*2-2;
      if OPLEN > 18 then OPLEN:= 18
      end
   else begin
      EXPR_FIELD:= UNQUOTE(EXPR_FIELD);
      L:= length(EXPR_FIELD);
      if L> 8 then begin
         P2ERR(36);
         L:=8
         end;
      OPLEN:= L*2+2;
      OP[2]:= 2*L-1;
      J:=3;
      for I:= L downto 1 do begin
         K:= ord(EXPR_FIELD[I]);
         OP[J]:= K and 15;
         OP[J+1]:= (K and 240) shr 4;
         J:= J+2
      end
   end
end;
(* ASM71PSO.INC*)


procedure BSS;
var I,K: integer;

begin
   if PASS1 then OPLEN:= abs(EXPRESSION())
   else begin
      OPLEN:= EXPRESSION();
      if OPLEN<0 then begin
         OPLEN:= abs(OPLEN);
         P2ERR(39)
         end;
      K:= OPLEN;
      if K > 18 then K:= 18;
      for I:= 1 to K do OP[I]:=0
   end
end;

procedure ENDSYM;

begin
   if PASS1 then OPLEN:= 0;
   DONE:= true
end;

procedure EQU;
var P: ref;
    EX : LongInt;

begin
   if(length(LABEL_FIELD)=0) or (not LABEL_OK(LABEL_FIELD)) then P2ERR(22)
   else begin
      if (LABEL_FIELD[1] = '=' )then begin
         delete(LABEL_FIELD,1,1);
         LABEL_FIELD:=LABEL_FIELD+' ';
      end;
      P:=SYT_SEARCH(LABEL_FIELD,ROOT);
      EX:= EXPRESSION();
      if PASS1 then begin
         if P = nil then PUT_SYT(LABEL_FIELD,EX,EQUATE)
         end
      else begin
         if (Ref_Opt=2) then Enter_Ref(P,SLINE_NR);
         if P^.TYP <> EQUATE then P2ERR(41)
         else begin
            P^.TYP:= EQUPAS2;
            if EX <> P^.VALUE then P2ERR(57)
         end
      end
   end
end;

procedure LISTONOFF;

begin
   if EXPR_FIELD='ON' then TOLIST:= true
   else if EXPR_FIELD='OFF' then TOLIST:= false
   else P2ERR(23)
end;

function EXTRACT(LINE:string50):string50;
var I: integer;

begin
   I:= pos('TITLE',LINE);
   delete(LINE,1,I+4);
   while(length(LINE)> 0) and (LINE[1] = ' ') do delete(LINE,1,1);
   EXTRACT:= LINE
end;

procedure STITLE;

begin
   STIT:= EXTRACT(SLINE)
end;

procedure TITLE;

begin
   TIT:= EXTRACT(SLINE)
end;

procedure DO_LINE; forward;

procedure SPIT; forward;

procedure LCPLUS; forward;

procedure PARSE; forward;

procedure PROCESS; forward;

procedure SIM_LINE(str:string96);

begin
   SLINE:= STR;
   DO_LINE;
   LLINE:=''
end;

procedure WRAPUPOLD;
begin
   OPLEN:= 0;
   OLD_EXPR:= EXPR_FIELD;
   SPIT;
   LCPLUS;
   LLINE:=''
end;

procedure STARTUPNEW(STR:string96);
begin
   SLINE:= STR;
   PARSE;
   PROCESS
end;

procedure FILE_IS(FLT:filtyp);

begin
   if FILETYPE= NONE then FILETYPE:= FLT;
   if not PASS1 then begin
      if FIRST then FIRST:= false
      else P2ERR(51)
   end
end;

procedure FILE_TEST(FLT:filtyp);

begin
   if FILETYPE <> FLT then P2ERR(51)
end;

procedure TIME_DATE;
begin
   SIM_LINE('  CON(2) #'+DATEVAR[9]+DATEVAR[10]+'           Date of creation');
   SIM_LINE('  CON(2) #'+DATEVAR[1]+DATEVAR[2]);
   SIM_LINE('  CON(2) #'+DATEVAR[4]+DATEVAR[5]);
   SIM_LINE('  CON(2) #'+TIMEVAR[1]+TIMEVAR[2]+'           Time of creation');
   SIM_LINE('  CON(2) #'+TIMEVAR[4]+TIMEVAR[5]);
   SIM_LINE('  CON(2) #'+TIMEVAR[7]+TIMEVAR[8])
end;

procedure VALID_NAME(ST:string50);
var ERR: boolean;

begin
   ERR:= (length(ST)> 8) or (not (ST[1] in ['A'..'Z','0'..'9']));
   if ERR then begin
      writeln(ERRMSG(26));
      HALTASM
   end
end;

procedure NAMEFIELD(ST:string10);

begin
   while length(ST) < 8 do ST:= ST+ ' ';
   SIM_LINE('  NIBASC '''+ST+''''+'    Filename (LIF Directory Entry)');
   SIM_LINE('  NIBASC ''  ''');
end;

procedure FILE_RECS;
var n:integer;
    t:LongInt;

begin
   SIM_LINE('  NIBHEX 0000          File length (records)');
   n:=((filesize-64) div 512)+1;
   t:= hi(n);
   SIM_LINE('  CON(2) '+NTOHEX(t,2,zfill));
   t:=lo(n);
   SIM_LINE('  CON(2) '+NTODEC(t,2,zfill));
end;

procedure FILE_LEN;
begin
   SIM_LINE('  CON(5) (FiLeNd)-(64) File length (nibbles)');
end;

procedure LEXFILE;
var FN: string10;

begin
   FILE_IS(LEX);
   if PASS1 then begin
      OFILE:=OFILE+'.lex';
      FN:= UNQUOTE(EXPR_FIELD);
      VALID_NAME(FN);
      if OFILE = '' then OFILE:= FN;
      OPLEN:= 64
      end
   else begin
      WRAPUPOLD;
      FN:= UNQUOTE(OLD_EXPR);
      VALID_NAME(FN);
      NAMEFIELD(FN);
      SIM_LINE('  NIBHEX 2E80          File Type is Lex');
      SIM_LINE('  NIBHEX 00000000      ignore File Start Record');
      FILE_RECS;
      TIME_DATE;
      SIM_LINE('  NIBHEX 0810          Volume Flag/Number');
      FILE_LEN;
      STARTUPNEW('  NIBHEX 000           End of Directory Entry');
   end
end;

procedure ID;

begin
   if PASS1 then OPLEN:= 16
   else begin
      if FILETYPE <> LEX then P2ERR(51);
      WRAPUPOLD;
      SIM_LINE('  CON(2) '+OLD_EXPR);
      if TOKEXIST then
         SIM_LINE('  CON(2) 0'+NTODEC(LOTOK,3,ZFILL))
      else SIM_LINE('  CON(2) 0');
      if TOKEXIST then
         SIM_LINE('  CON(2) 0'+NTODEC(HITOK,3,ZFILL))
      else SIM_LINE('  CON(2) 0');
      SIM_LINE('  CON(5) 0');
      SIM_LINE('  NIBHEX F');
      STARTUPNEW('  REL(4) 1+TxTbSt')
   end
end;

procedure MSG;
var EX: LongInt;

begin
   if FILETYPE <> LEX then P2ERR(51);
   WRAPUPOLD;
   EX:= EXPRESSION();
   if EX = 0 then STARTUPNEW('  CON(4) 0')
   else STARTUPNEW('  REL(4) '+OLD_EXPR)
end;

procedure POLL;

begin
   if FILETYPE <> LEX then P2ERR(51);
   WRAPUPOLD;
   if EXPRESSION() = 0 then STARTUPNEW('  CON(5) 0')
   else STARTUPNEW('  REL(5) '+OLD_EXPR)
end;

procedure ENTRY;

begin
   if FILETYPE <> LEX then P2ERR(51);
   WRAPUPOLD;
   if TENT= 0 then SIM_LINE('  ***MAIN TABLE***');
   TENT:= TENT+1;
   SIM_LINE('  CON(3) (TxEn'+NTODEC(TENT,2,ZFILL)+')-(TxTbSt)');
   STARTUPNEW('  REL(5) '+OLD_EXPR)
end;

procedure CHAR;

begin
   if FILETYPE <> LEX then P2ERR(51);
   WRAPUPOLD;
   STARTUPNEW('  CON(1) '+OLD_EXPR)
end;

procedure KEYP;

begin
   if PASS1 then begin
      if KENT= 0 then PUT_SYT('TxTbSt ',LC,LABL);
      KENT:= KENT+1;
      PUT_SYT('TxEn'+NTODEC(KENT,2,ZFILL)+' ',LC,LABL);
      OPLEN:= (length(EXPR_FIELD)-2)*2+1
      end
   else begin
      if FILETYPE <> LEX then P2ERR(51);
      WRAPUPOLD;
      if KENT = 0 then begin
         SIM_LINE('  ***TEXT TABLE***');
         SIM_LINE('TxTbSt')
         end;
      KENT:= KENT+1;
      SIM_LINE('TxEn'+NTODEC(KENT,2,ZFILL));
      OLD_EXPR:= UNQUOTE(OLD_EXPR);
      SIM_LINE('  CON(1) '+NTODEC(((length(OLD_EXPR)*2)-1),2,ZFILL));
      STARTUPNEW('  NIBASC '''+OLD_EXPR+'''')
   end
end;

procedure TOKENP;
var EX: LongInt;
    ITOK: integer;

begin
   if PASS1 then begin
      TOKEXIST:= true;
      EX:= EXPRESSION();
      ITOK:= integer(EX);
      if ITOK < LOTOK then LOTOK:= ITOK;
      if ITOK > HITOK then HITOK:= ITOK;
      OPLEN:=2
      end
   else begin
      if FILETYPE <> LEX then P2ERR(51);
      WRAPUPOLD;
      STARTUPNEW('  CON(2) '+OLD_EXPR)
   end
end;

procedure ENDTXT;
begin
   if PASS1 then begin
      if KENT= 0 then PUT_SYT('TxTbSt ',LC,LABL);
      OPLEN:=3
      end
   else begin
      WRAPUPOLD;
      if KENT = 0 then SIM_LINE('TxTbSt');
      STARTUPNEW('  NIBHEX 1FF')
   end
end;

procedure BINFILE;
var FN: string10;

begin
   FILE_IS(BIN);
   if PASS1 then begin
      OFILE:=OFILE+'.bin';
      FN:= UNQUOTE(EXPR_FIELD);
      VALID_NAME(FN);
      if OFILE = '' then OFILE:= FN;
      OPLEN:= 64
      end
   else begin
      WRAPUPOLD;
      FN:= UNQUOTE(OLD_EXPR);
      VALID_NAME(FN);
      NAMEFIELD(FN);
      SIM_LINE('  NIBHEX 2E40          File Type is Bin');
      SIM_LINE('  NIBHEX 00000000      ignore File Start Record');
      FILE_RECS;
      TIME_DATE;
      SIM_LINE('  NIBHEX 0810          Volume Flag/Number');
      FILE_LEN;
      STARTUPNEW('  NIBHEX 000           End of Directory Entry');
   end
end;

procedure CHAIN;
begin
   if FILETYPE<> BIN then P2ERR(51);
   WRAPUPOLD;
   if EXPRESSION()= 1 then
      SIM_LINE('  CON(5) '+OLD_EXPR)
   else SIM_LINE('  REL(5) '+OLD_EXPR);
   SIM_LINE('  CON(5) -1');
   STARTUPNEW('  NIBHEX 20')
end;
(* ASM71PAR.INC*)

function OPC_LOOKUP(NAM:string6  ):integer;
var A: integer ;
    oname: string6;

function HASH(ONAME:string6  ):integer;
   var I: integer;
       K: integer;
       H: LongInt;
begin
      H:=0;
      for I:= 1 to 6 do begin
          K:= (ord(ONAME[I]) and 7);
          H:=H*8+K;
          end;
      HASH:= H mod 43;
end;

begin
   oname:=nam;
   A:= OPTINDEX[HASH(ONAME)];
   while MOT[A].TXT <> ONAME do begin
      if MOT[A].LEAF <> 0 then begin
         OPC_LOOKUP:= NULENT;
         EXIT
         end;
      if MOT[A].TXT < ONAME then A:= MOT[A].RGT
      else A:= MOT[A].LFT;
   end;
   OPC_LOOKUP:=A
end;

procedure SET_OP_VARS(A:integer);
VAR I: integer;
    O: integer;

begin
   with MOT[A] do begin
      OPTYPE:= OPCLS;
      F_LSET:= (flgs and 1) <> 0;
      F_RETY:= (flgs and 2) <> 0;
      F_GOYS:= (flgs and 8) <> 0;
      F_ABSL:= (flgs and 16) <> 0;
      F_EXPR:= (flgs and 32) <> 0;
      F_GSUB:= (flgs and 64) <> 0;
      OPLEN:= OPCLEN;
      if OPLEN > 5 then O:=5 else O:= OPLEN;
      for I:= 1 to O do OP[I]:= OPC[I];
      FILL_MARK:= VARA;
      FILL_LENGTH:= VARB
   end
end;

procedure GET_STR(var SLINE:string96;MAXLEN,IERR:integer;
                  var RESULT: string50;EXP_QUOTE,FILL:boolean);
var UNQUOTE,ENDBLANK: boolean;
    L,I,J: integer;

begin
   RESULT:='';
   I:=1;
   L:= length(SLINE);
   if L>0 then begin
      while SLINE[I] =' ' do begin
         I:= I+1;
         if I > L then begin
            SLINE:='';
            EXIT
            end
         end;
      delete(SLINE,1,I-1);
      I:=0;
      L:= length(SLINE);
      if EXP_QUOTE then begin
         ENDBLANK:= false;
         UNQUOTE:= true;
         while not ENDBLANK do begin
            I:= I+1;
            if SLINE[I]= '''' then UNQUOTE:= not UNQUOTE;
            ENDBLANK:= ((SLINE[I]=' ') and UNQUOTE) or (I=L)
            end
         end
      else begin
         I:= pos(' ',SLINE);
         if I= 0 then I:=L else I:= I-1
         end;
      if I > MAXLEN then begin
         J:= MAXLEN;
         if IERR > 0 then
            P2ERR(IERR);
         end
      else J:=I;
      RESULT:= copy(SLINE,1,J);
      delete(SLINE,1,I);
      if FILL then while length(RESULT)< MAXLEN do RESULT:= RESULT+' '
      else begin
         I:= length(RESULT);
         while (RESULT[I]=' ') and (I>1) do I:= I-1;
         delete(RESULT,I+1,length(RESULT)-I)
      end
   end;
end;

procedure PARSE;
type string1= string[1];
var A: integer;
    TLINE: string96;

function FIRSTCHAR:string1;
   var I: integer;
begin
      if length(SLINE)=0 then FIRSTCHAR:='*'
      else begin
         for I:= 1 to length(SLINE) do
            if SLINE[I]<>' ' then begin
               FIRSTCHAR:=SLINE[I];
               exit
               end;
         FIRSTCHAR:='*';
         end
end;

begin
   if (length(SLINE)=0) or (FIRSTCHAR = '*') then begin
      LABEL_FIELD:='';
      OPCODE_FIELD:='';
      EXPR_FIELD:='';
      SET_OP_VARS(NULENT)
      end
   else begin
      TLINE:= SLINE;
      if (TLINE[1]=' ') and (SLINE[2]=' ') then LABEL_FIELD:=''
      else begin
         if Strict_Opt = 1 then
            GET_STR(TLINE,7,86,LABEL_FIELD,false,true)
         else
            GET_STR(TLINE,7,-86,LABEL_FIELD,false,true);
      end;
      GET_STR(TLINE,6,87,OPCODE_FIELD,false,true);
      if OPCODE_FIELD = '' then A:= NULENT
      else begin
         A:= OPC_LOOKUP(OPCODE_FIELD);
         if A= NULENT then P2ERR(20);
         end;
      SET_OP_VARS(A);
      GET_STR(TLINE,50,40,EXPR_FIELD,F_EXPR,false);
      GETCHCOUNT:=0;
   end;
end;

procedure OPCODE_INIT;

begin
   optindex[0]:= 1;
   optindex[1]:= 10;
   optindex[2]:= 25;
   optindex[3]:= 34;
   optindex[4]:= 41;
   optindex[5]:= 54;
   optindex[6]:= 65;
   optindex[7]:= 74;
   optindex[8]:= 81;
   optindex[9]:= 96;
   optindex[10]:=103;
   optindex[11]:=110;
   optindex[12]:=117;
   optindex[13]:=128;
   optindex[14]:=137;
   optindex[15]:=144;
   optindex[16]:=157;
   optindex[17]:=168;
   optindex[18]:=175;
   optindex[19]:=180;
   optindex[20]:=187;
   optindex[21]:=192;
   optindex[22]:=199;
   optindex[23]:=206;
   optindex[24]:=213;
   optindex[25]:=218;
   optindex[26]:=229;
   optindex[27]:=236;
   optindex[28]:=245;
   optindex[29]:=250;
   optindex[30]:=257;
   optindex[31]:=264;
   optindex[32]:=275;
   optindex[33]:=284;
   optindex[34]:=295;
   optindex[35]:=304;
   optindex[36]:=315;
   optindex[37]:=322;
   optindex[38]:=329;
   optindex[39]:=340;
   optindex[40]:=349;
   optindex[41]:=354;
   optindex[42]:=363;
end;
(* ASM71MAI.INC*)


{procedure show_progress;

   begin
   if DOTCOUNT > 70 then begin
      DOTCOUNT:= 1;
      writeln;
      if PASS1 then write('Pass1 .') else write('Pass2 .')
      end
   else begin
      DOTCOUNT:= DOTCOUNT+1;
      write('.')
      end
   end;
}
procedure PROCESS;

begin
   case OPTYPE of
   0: begin end;
   1: REGTEST;
   2: REGARITH;
   3: REGLOGIC;
   4: BRANCHES;
   5: begin end;
   6: begin end;
   7: RTNYES;
   8: PTRTEST;
   9: STATTEST;
   10: SETPTR;
   11: SETSTAT;
   12: DPARITH;
   13: DATATRANS;
   14: NIBHEX;
   15: LCHEX;
   16: DX_HEX;
   17: NIBASC;
   18: LCASC;
   19: BSS;
   20: EJECT;
   21: ENDSYM;
   22: EQU;
   23: LISTONOFF;
   24: TITLE;
   25: STITLE;
   26: begin end;
   27: begin end;
   28: LEXFILE;
   29: ID;
   30: MSG;
   31: POLL;
   32: ENTRY;
   33: CHAR;
   34: KEYP;
   35: TOKENP;
   36: BINFILE;
   37: begin end;
   38: CHAIN;
   39: ENDTXT
   end
end;

procedure SPIT;

begin
   if LAST_REQ then
      if (OPLEN> 0) and (not F_GOYS) then P2ERR(21);
   OUT_OBJ;
   OUTPUT_LIST
end;

procedure LCPLUS;

begin
   if OPLEN > 0 then begin
      LAST_REQ:= F_RETY;
      LC:= LC+ OPLEN
   end
end;

procedure LABELS;

begin
   if length(LABEL_FIELD) = 0 then EXIT;
   if LABEL_FIELD[1]= '=' then begin
      delete(LABEL_FIELD,1,1);
      LABEL_FIELD:=LABEL_FIELD+' ';
   end;
   if PASS1 then PUT_SYT(LABEL_FIELD,LC,LABL)
   else if not LABEL_OK(LABEL_FIELD) then P2ERR(22)
   else if GET_SYT(LABEL_FIELD) <> LC then begin
       P2ERR(41)
   end;
end;

procedure DO_LINE;

begin
   {SHOW_PROGRESS;}
   PARSE;
   if OPTYPE <> 22 then LABELS;
   if PASS1 then begin
      if not F_LSET then PROCESS;
      if FILETYPE = NONE then begin
         writeln(ERRMSG(51));
         HALTASM
         end
      end
   else begin
      PROCESS;
      SPIT
      end;
   LCPLUS;
   ALREADY_ERR:= false
end;

procedure LISTHEADER;

begin
   if not NOLIST then begin
      OUTLINE(#12);
      if(TESTMODE) then
      begin
         OUTLINE('ASM71 ');
         OUTLINE(' ')
      end else begin
         OUTLINE('ASM71 '+SYS+' '+VERSION+'         '+VERS_DATE+'        '+DATEVAR+
          '    '+TIMEVAR);
         OUTLINE(COPYRIGHT);
      end;
      OUTLINE(' ');
   end;
end;

procedure PASS_INIT;

begin
   if PASS1 then begin
      LOTOK:= 255;
      HITOK:= -256;
      LC:=0;
      end
   else begin
      TOLIST:= true;
      PAGENO:= 1;
      LLINE_NR:=0;
      TIT:='';
      STIT:= '';
      LC:= 0;
      LISTHEADER
   end;
   SLINE_NR:= 0;
   LAST_REQ:= false;
   DONE:= false;
   TENT:=0;
   KENT:=0;
   { DOTCOUNT:= 100 }
end;

procedure VAR_INIT;

begin
   TESTMODE:=GetEnvironmentVariable('ASM71REGRESSIONTEST')<>'';
   ERRORCOUNT:=0;
   TOLIST:= false;
   TOKEXIST:= false;
   FIRST:= true;
   FILETYPE:=NONE;
   ALREADY_ERR:= false;
   OBJECTFILE_EXISTS:= false;
   LISTFILE_EXISTS:= false;
   SOURCE_EXISTS:= false;
   ORD0:= ord('0');
   ORDA:= ord('A')-10;
   GET_TIME_DATE;
   DECHEX[0]:='0';
   DECHEX[1]:='1';
   DECHEX[2]:='2';
   DECHEX[3]:='3';
   DECHEX[4]:='4';
   DECHEX[5]:='5';
   DECHEX[6]:='6';
   DECHEX[7]:='7';
   DECHEX[8]:='8';
   DECHEX[9]:='9';
   DECHEX[10]:='A';
   DECHEX[11]:='B';
   DECHEX[12]:='C';
   DECHEX[13]:='D';
   DECHEX[14]:='E';
   DECHEX[15]:='F'
end;

procedure HEADER;

begin
   writeln;
   if(TESTMODE) then
   begin
      writeln('ASM71 ');
      writeln(' ');
   end else begin
      writeln('ASM71 '+SYS+' '+VERSION+'         '+VERS_DATE+'        '+DATEVAR+
          '    '+TIMEVAR);
      writeln(COPYRIGHT);
   end;
end;

procedure INIT;

begin
   VAR_INIT;
   HEADER;
   RUNSTRING;
   LIST_INIT;
   OPEN_SOURCE;
   SYT_INIT;
   OPCODE_INIT;
end;

procedure DO_PASS;

begin
   PASS_INIT;
   while (not eof(SOURCE)) and (not DONE) do begin
      READ_SOURCE;
      DO_LINE
   end
end;


begin
   INIT;

   PASS1:= true;
   DO_PASS;
   if GET_SYT('FiLeNd ') <> 0 then begin
      writeln(ERRMSG(61));
      HALTASM
   end;
   PUT_SYT('FiLeNd ',LC,LABL);
   FILESIZE:= LC;
   RESET_SOURCE;
   OBJ_INIT;
   PASS1:= false;
   DO_PASS;
   if TOLIST then OUT_SYT;
   CLEANUP;
   if ERRORCOUNT > 0 then
      HALT(1)
   else
      HALT(0);
end.
