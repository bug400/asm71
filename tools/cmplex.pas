program cmplex;
(* Utility to compare two lex files *)
uses sysutils;

type filheader = array[0..31] of Byte;

var filename1: string[80];
    filename2: string[80];
    header1: filheader;
    header2: filheader;
    file1: file of byte;
    file2: file of byte;
    len1: integer;
    len2: integer;
    l: boolean;
    b1: byte;
    b2: byte;
    n1: byte;
    n2: byte;
    bytepos: integer;
    ndiff: integer;
    i: integer;

begin
   ndiff:= 0;
   filename1:= paramstr(1);
   filename2:= paramstr(2);
   assign(file1,filename1);
   reset(file1);
   assign(file2,filename2);
   reset(file2);
   for i:= 0 to 31 do begin
      read(file1,b1);
      read(file2,b2);
      header1[i]:=b1;
      header2[i]:=b2;
   end;
   len1:=header1[28]+header1[29]*256+header1[30]*256*256;
   len2:=header2[28]+header2[29]*256+header2[30]*256*256;
   writeln('File1: ',filename1,' Length: ',len1,' nibs');
   writeln('File2: ',filename2,' Length: ',len2,' nibs');
   if len1 <> len2 then begin
      writeln('File length differs');
      halt;
   end;
   l:= True;
   bytepos:= 64;
   ndiff:=0;
   for i:=1 to len1 do begin
       if l then begin
          if eof(file1) then begin
             writeln('eof on file ',filename1);
             halt;
          end;
          read(file1,b1);
          if eof(file2) then begin
             writeln('eof on file ',filename2);
             halt;
          end;
          read(file2,b2);
          n1:=b1 and $F;
          n2:=b2 and $F;
          l:= False;
        end else begin
          n1:=(b1 shr 4);
          n2:=(b2 shr 4);
          l:= True;
        end;
        if n1 <> n2 then begin
           writeln('address: ',IntToHex(bytepos,5),' low nibble: ',l,' file1: ',IntToHex(n1,1), ' file2: ',IntToHex(n2,1));
           ndiff:= ndiff+1;
        end;
        bytepos:= bytepos+1;
   end;
   if ndiff=0 then writeln('LEXFILE ',filename1,' OK')
   else writeln(ndiff,' differences found');
   close(file1);
   close(file2)
end.
