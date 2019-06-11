for %%I in (*.asm) do (
   if exist %%~nI.lex del %%~nI.lex
   if exist %%~nI.lst del %%~nI.lst
   asm71 %%~nI.asm,%%~nI.lex,%%~nI.lst,R2
   echo Comparing lst file
   diff %%~nI.lst reference\%%~nI.lst
   echo Comparing lex file
   diff %%~nI.lex reference\%%~nI.lex
   if exist %%~nI.lex del %%~nI.lex
   if exist %%~nI.lst del %%~nI.lst
)
