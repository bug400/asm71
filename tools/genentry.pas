program emtry71;

const  maxentry = 2000;

type   entrytype =  record
                       E_Name: string[6];
                       E_Value: LongInt;
                     end;
       entryvektor= array[1..maxentry] of entrytype;
       filename = string[63];
       string80 = string[80];
       xentry   = record
                   N_Entries: integer;
                   Entry: entryvektor;
                   end;

var   E: xentry;
      Infile: text;
      Infilname: Filename;
      outfile: text;
      Anz:   integer;
      Inpline: string80;

function upc(str:Filename): Filename;
var I: integer;

begin
   for I:= 1 to length(str) do  str[I]:= upcase(str[I]);
   upc:= str;
end;

procedure Init;

begin
     assign(Infile,'HP71ENTR.TXT');
     reset(infile);
     assign(Outfile,'ASM71ENT.INC');
     rewrite(Outfile);
end;

procedure Finish;

begin
   close(Infile);
   close(Outfile);
end;

function Decode(str:string80): LongInt ;
var I: integer;
    CH: char;
    t: LongInt;

begin
   t:= 0;
   for I:= 1 to length(str) do begin
      ch:= str[I];
      if ch in ['0'..'9'] then T:= T*16 + ord(ch)- ord('0')
      else if ch in ['A'..'F'] then T:= T*16+ ord(ch)- Ord('A')+10
      else begin
         writeln('non hexadecimal digit present at line: ',Anz);
         end;
   end;
   Decode:=t;
end;

procedure ReadEntries;
begin
   Anz:= 0;
   while not EOF(Infile) do begin
      Anz:= Anz + 1;
      if Anz > Maxentry then begin
         writeln('Max. Number of Entries exceeded');
         Halt;
      end;
      with E.Entry[Anz] do begin
         readln(infile,inpline);
         E_Name:= copy(Inpline,1,6);
         E_Value:= Decode(Copy(Inpline,8,12));
      end;
   end;
   writeln(Anz,' Entries read');
   E.N_Entries:= Anz;
end;

procedure SortEntries;

procedure Sort(l,r: integer);
var I,J: integer;
    X,W: Entrytype;

begin
   with E do begin
   I:=l; J:=R;
   X:= Entry[(L+R) div 2];
   repeat
      while Entry[i].E_Name < X.E_Name do I:= i+1;
      while X.E_Name < Entry[j].E_Name do J:= j-1;
      if i <= j then begin
         W:= Entry[I];
         Entry[I]:= Entry[J];
         Entry[J]:=W;
         I:=i+1;
         J:= J-1;
      end
   until I > j;
   if l < j then sort(l,j);
   if i < r then sort(i,r);
   end
end;

begin
   sort(1,anz);
   writeln('Entries sorted');
end;

procedure OutEntries;
var I: integer;
    nam: string[6];
    len: LongInt;

begin
   writeln(outfile); writeln(outfile,'type     entryvector= array[1..',
   maxentry,'] of entrytype; ');
   writeln(outfile,'const N_Entries:integer= ',anz,';');
   writeln(outfile,'      Ext_Entry:entryvector= (');
   for i:=1 to anz do begin
     nam:= e.entry[i].e_name;
     len:= e.entry[i].e_value;
     write(outfile,'   (E_Name:''',nam,''';E_Value:',len,')');
     if i= maxentry then writeln(outfile) else writeln(outfile,',');
  end;
  for i:= anz+1 to maxentry do begin
     write(outfile,'   (E_Name:''      '';E_VALUE:0)');
     if i= maxentry then writeln(outfile) else writeln(outfile,',');
  end;
  writeln(outfile,'   );');
end;

begin
   Init;
   ReadEntries;
   SortEntries;
   OutEntries;
   Finish;
end.
