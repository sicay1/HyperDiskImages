program TBdex;
{
******************************************************************************

  PROGRAM ID:  TBDEX.PAS
  PURPOSE:     EXAMPLE TOUCH SCREEN DRIVER APPLICATION
  AUTHOR:      TOUCHBASE LTD
  DATE:        SEPTEMBER 1989
  VERSION:     2.26
  LANGUAGE:    TURBO PASCAL 5.0

  DESCRIPTION:
  Simple four function touch calculator, demonstrating some of the main 
  functions of the DOS touchscreen driver.

  DISTRIBUTION:
  You may copy, use, or distribute this program in any way you like.
  However, it requires the driver to be loaded in order to run, and TouchBase's
  normal licencing arrangements always apply to the use of its drivers.
 
******************************************************************************
}
{$V-}
{$R+}
uses dos, crt;

type
   padrec = RECORD 
      x1,y1,x2,y2: BYTE;               { pad coordinates }
      key:         CHAR;               { Key Function }
      END;

   hilo = (high,low);

const
   padtable:   ARRAY[0..18] OF padrec = (
   (X1: 0 ;  Y1: 0 ;  X2: 0 ;  Y2:  0;  Key:  ' ' ),   { None } 
   (X1: 24;  Y1: 17;  X2: 31;  Y2: 19;  Key:  '0' ),   { 0 } 
   (X1: 24;  Y1: 14;  X2: 31;  Y2: 16;  Key:  '1' ),   { 1 } 
   (X1: 33;  Y1: 14;  X2: 40;  Y2: 16;  Key:  '2' ),   { 2 } 
   (X1: 42;  Y1: 14;  X2: 49;  Y2: 16;  Key:  '3' ),   { 3 } 
   (X1: 24;  Y1: 11;  X2: 31;  Y2: 13;  Key:  '4' ),   { 4 } 
   (X1: 33;  Y1: 11;  X2: 40;  Y2: 13;  Key:  '5' ),   { 5 } 
   (X1: 42;  Y1: 11;  X2: 49;  Y2: 13;  Key:  '6' ),   { 6 } 
   (X1: 24;  Y1: 8 ;  X2: 31;  Y2: 10;  Key:  '7' ),   { 7 } 
   (X1: 33;  Y1: 8 ;  X2: 40;  Y2: 10;  Key:  '8' ),   { 8 } 
   (X1: 42;  Y1: 8 ;  X2: 49;  Y2: 10;  Key:  '9' ),   { 9 } 
   (X1: 33;  Y1: 17;  X2: 40;  Y2: 19;  Key:  '.' ),   { Point } 
   (X1: 60;  Y1: 8 ;  X2: 67;  Y2: 10;  Key:  'C' ),   { Clear } 
   (X1: 51;  Y1: 11;  X2: 58;  Y2: 13;  Key:  'x' ),   { Multiply } 
   (X1: 60;  Y1: 11;  X2: 67;  Y2: 13;  Key:  'ö' ),   { Divide } 
   (X1: 51;  Y1: 14;  X2: 58;  Y2: 16;  Key:  '-' ),   { Minus } 
   (X1: 60;  Y1: 14;  X2: 67;  Y2: 16;  Key:  '+' ),   { Plus } 
   (X1: 51;  Y1: 8 ;  X2: 58;  Y2: 10;  Key:  'X' ),   { Exit } 
(* (X1: 42;  Y1: 17;  X2: 49;  Y2: 19;  Key:  ' ' ),   { Spare position } *)
   (X1: 51;  Y1: 17;  X2: 67;  Y2: 19;  Key:  '=' ));  { = } 
                             
var
   reg:        registers;              { processor registers }
   i:          INTEGER;                { loop count }
   TBdintvec:  POINTER;                { Initial value of int 66 }
   padhi:      INTEGER;                { pad currently highlighted (0=none) }
   numstring:  STRING;                 { number being entered }
   keyfunction:CHAR;                   { function of pad touched }
   operator:   CHAR;                   { current operator }
   opnum:      INTEGER;                { current operand number }
   operand1:   REAL;                   { current value of operand 1 }
   operand2:   REAL;                   { current value of operand 2 }
   pointused:  BOOLEAN;                { prevents multiple decimal points }

{----------------------------------------------------------------------------
}

FUNCTION Int2Str(l : LONGINT) : STRING;
VAR
  s : STRING;
BEGIN
  STR(l, s);
  Int2Str := s;
END;        

FUNCTION Str2Real(s: STRING) : REAL;
VAR
   r:    REAL;
   code: INTEGER;
BEGIN
   VAL(s,r,code);
   Str2Real := r;
END;

FUNCTION Real2Str(l : REAL) : STRING;
VAR
  S : STRING;
BEGIN
  STR(l :17 :2 , s);
  Real2Str := s;
END;        

PROCEDURE lowbeep;
BEGIN
   sound(180);
   delay(40);
   nosound;
END;

PROCEDURE highbeep;
BEGIN
   sound(320);
   delay(4);
   nosound;
END;

PROCEDURE HiddenCursor;
VAR
   reg: REGISTERS;
BEGIN
   reg.AH := 1;                        { BIOS Set cursor size }
   reg.CH := $20;                      { start line }
   reg.CL := 0;                        { end line }
   INTR($10,reg);                      { BIOS video services }
END;

PROCEDURE NormalCursor;
VAR
   reg: REGISTERS;
BEGIN
   reg.AH := 1;                        { BIOS Set cursor size }
   reg.CH := 6;                        { start line }
   reg.CL := 7;                        { end line }
   INTR($10,reg);                      { BIOS video services }
END;

{---------------------------------------------------------------------------
 This function returns TRUE if AltF10 was pressed on the keyboard
}
function AltF10pressed: Boolean;
begin
   AltF10pressed := False;
   if keypressed then
      begin
      reg.AH := 0;                     { BIOS read keyboard function }
      intr($16,reg);                   { BIOS keyboard services }
      if reg.ax = $7100 then           { Alt F10 }
         AltF10pressed := True;
      end;
end;

{---------------------------------------------------------------------------
 This procedure sets the display attributes of the specified screen positions
 without altering the text
}
PROCEDURE ChangeAttribute(num, row, col, attribute: BYTE);
VAR
   i:   BYTE;    { loop count }
   reg: REGISTERS;
BEGIN
   row := row - 1;                     { BIOS uses 0 origin }
   col := col - 1;                     { BIOS uses 0 origin }
   FOR i := 1 TO num DO
      BEGIN
      reg.AH := 2;                     { BIOS set cursor position }
      reg.BH := 0;                     { page 0 }
      reg.DH := row;
      reg.DL := col;
      INTR($10,reg);                   { set new cursor position }
      reg.AH := 8;                     { BIOS read char & attribute at cursor}
      reg.BH := 0;                     { page 0 }
      INTR($10,reg);                   { AH := attribute ; AL := character }
      reg.AH := 9;                     { BIOS write char & attribute }
      reg.BH := 0;                     { page 0 }
      reg.BL := attribute;             { new attribute ; AL = character }
      reg.CX := 1;                     { only do it once }
      INTR($10,reg);                   { write character & attribute }
      col := col + 1;                  { next column }
      END;
END;

{----------------------------------------------------------------------------
 This procedure changes the visual attributes of the pad number passed
}
PROCEDURE change(padnum: INTEGER; hilow: hilo);
VAR
   width:      INTEGER;                { width of pad }
   atr:        BYTE;                   { attribute to change to }
BEGIN
   IF hilow = low THEN
          atr := WHITE+BLUE*16         { low }
      ELSE
          atr := BLACK+LIGHTGRAY*16;         { high }
   width := padtable[padnum].X2 - padtable[padnum].X1 + 1;
   FOR i := padtable[padnum].Y1 TO padtable[padnum].Y2 DO
       ChangeAttribute(width,i,padtable[padnum].X1,atr);
END;

{----------------------------------------------------------------------------
 This function reads the driver until a finger lift is detected, then
 returns the pad number.  
 Highlighting is handled entirely by this function:  
  When it exits, all pads are in their normal colour
}
function readpad: integer;
begin
   WHILE TRUE DO 
      BEGIN
      if AltF10pressed then
         halt;
      reg.AL := $01;                      { read function }
      Intr($66,reg);                      { call the driver to read touch }
      Case CHAR(reg.AH) OF
          'F','R': BEGIN                      { First or Repeat touch }
                   IF reg.DX <> padhi THEN    { is pad already highlighted ? }
                       BEGIN                  { .. no .. }
                       IF padhi <> 0 THEN     { any other pad lit ? }
                           begin
                           change(padhi,low); { un-highlight old pad }
                           padhi := 0;        { not no pads highlighted }
                           end;
                       IF reg.DX <> 0 THEN    { was a pad touched ? }
                           begin                  { yes ... }
                           change(reg.DX,high);   { highlight new pad }
                           padhi := reg.DX;       { note new highlighted pad }
                           end;
                       END;
                   END;
          'N': BEGIN                   { No touch }
               IF padhi <> 0 THEN      { any pad highlighted ? }
                   BEGIN
                   change(padhi,low);  { un-highlight pad }
                   padhi := 0;         { note no pads highlighted }
                   END;
               END;
          'L': BEGIN                   { Last touch }
               IF padhi <> 0 THEN      { any pad highlighted ? }
                   BEGIN
                   change(padhi,low);  { un-highlight pad }
                   padhi := 0;         { note no pads highlighted }
                   END;
               readpad := reg.DX;      { function value is the pad number }
               IF reg.DX = 0 THEN      { Pad or no pad ? }
                        lowbeep        { invalid touch }
                   ELSE
                        highbeep;      { valid touch }   
               EXIT;                   { always exit on a Last touch }
               END
          END; {case}
      END; {while}
end;

{---------------------------------------------------------------------------
 This procedure displays the calculator
}
procedure showcalc;
begin
   textbackground(black);
   TextColor(White);
   clrscr;
   TextBackground(BLUE);
   Window(22,3,70,22);
   Writeln('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´ Touch-Base Ltd. ÃÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
   Writeln('³ ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸ ³');
   Writeln('³ ³                                          ³ ³');
   Writeln('³ ³                                          ³ ³');
   Writeln('³ ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾ ³');
   Writeln('³ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ³');
   Writeln('³ ³  7   ³ ³  8   ³ ³  9   ³ ³ Exit ³ ³Clear ³ ³');
   Writeln('³ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ³');
   Writeln('³ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ³');
   Writeln('³ ³  4   ³ ³  5   ³ ³  6   ³ ³  x   ³ ³  ö   ³ ³');
   Writeln('³ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ³');
   Writeln('³ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿ ³');
   Writeln('³ ³  1   ³ ³  2   ³ ³  3   ³ ³  -   ³ ³  +   ³ ³');
   Writeln('³ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ ³');
   Writeln('³ ÚÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄ¿          ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ³');
   Writeln('³ ³  0   ³ ³  .   ³          ³       =       ³ ³');
   Writeln('³ ÀÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÙ          ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ³');
   Writeln('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');

end;
{                                             
============================================================================
                      MAIN  BODY
============================================================================
}
begin
{
 Make sure the Touch screen driver is loaded otherwise we'll crash
 the machine calling int 66 pointing to address 0000:0000
}
	GETINTVEC($66, TBdintvec);
	IF TBdintvec = NIL THEN
		BEGIN
		WRITELN('Touchscreen driver not loaded on int 66');
		HALT(1);
		END;
{
 This application won't run on matrix touchscreens
}
   reg.AL := $03;                      { get parameters function }
   INTR($66,reg);                      { call the driver }
   if reg.BL = 16 then                 { Mors capacitive matrix ? }
      begin
      writeln('This application requires an analogue touchscreen');
      halt(1);
      end;
{
 Initialise variables
}
   padhi := 0;
   opnum := 0;                { ready for initial entry }
{
 Hide the cursor and display the calculator screen
}
   HiddenCursor;
   showcalc;
{
 Window into the calculator display area
}
   window(26,5,66,6);
{
 Flush the touch buffer and de-activate any pads which might be active
}
   reg.AL := $07;             { flush buffer }
   Intr($66,reg);             { call the driver }
   reg.AL := $14;             { de-activate pad }
   reg.AH := 0;               { .. all pads }
   Intr($66,reg);             { call the driver }
{
 Set driver to 80 x 25 scale
}
   reg.bx := 80;
   reg.cx := 25;              { set scale to 80 x 25 }
   reg.dl := 0;               { don't change Z scale }
   reg.ah := 1;               { origin to 1 }
   reg.AL := $02;             { set scale function }
   INTR($66,reg);             { call the driver }
{
 Define and activate the pads
}
   FOR i := 1 to 18 DO
      WITH padtable[i] DO
         BEGIN
         reg.AL := $12;             { define pad }
         reg.AH := i;               { pad number }
         reg.BX := X1;
         reg.CX := Y1;
         reg.DX := X2;
         reg.ES := Y2;
         INTR($66,reg);             { call the driver }
         reg.AL := $13;             { activate pad }
         reg.AH := i;               { pad number }
         INTR($66,reg);             { call the driver }
         END;
{
 Process key touches
}
   While true do                                 { loop forever }
        begin
        keyfunction := padtable[readpad].key;    { get a touch }
        Case keyfunction of       
   '.'..'9' : begin                              { point or digit entered }
              if opnum = 0 then                  { initial entry }
                 begin                        
                 clrscr;                         
                 opnum := 1;                     { entering operand 1 }
                 numstring := '';
                 pointused := FALSE;
                 operand1 := 0;
                 operand2 := 0;
                 operator := ' ';
                 end;
              if length(numstring) = 12 then      { max allowed is 12 }
                     lowbeep
                 else
                     begin
                     if (keyfunction = '.') AND pointused THEN
                              lowbeep            { multiple decimal point }
                         else
                              begin
                              if keyfunction = '.' then
                                    pointused := TRUE;
                              numstring := numstring + keyfunction; 
                              gotoxy(36-length(numstring),opnum);
                              write(numstring);
                              end;
                     end;
              end;

    'x','-',
    'ö','+',
        '=' : begin                              { operators and equals }
              operand2 := str2real(numstring);   { get operand 2 from display}
              Case operator of                   { evaluate previous operator}
              ' ' : operand1 := operand2;        { no previous operand }
              '+' : operand1 := operand1 + operand2;
              '-' : operand1 := operand1 - operand2;
              'x' : operand1 := operand1 * operand2;
              'ö' : if operand2 = 0 then
                           begin                 { handle divide by 0 }
                           lowbeep;
                           clrscr;
                           Gotoxy(32,1);
                           Write('Error');
                           delay(1000);
                           opnum := 0;           { prepare for operand 1 }
                           operator := ' ';
                           keyfunction := ' ';   { skip further processing }
                           end
                       else
                           operand1 := operand1 / operand2;
              end;
              clrscr;                            { clear window }
              numstring := Real2Str(operand1);   { convert result to string }
              gotoxy(36-length(numstring),1);
              write(numstring);                  { display result as new op1 }
              if keyfunction IN ['x','-','ö','+'] THEN
                   begin                              { operators only }
                   gotoxy(39,1);
                   write(keyfunction);                { display new operator }
                   operator := keyfunction;           { and save it }
                   opnum := 2;                        { prepare for operand 2 }
                   pointused := FALSE;
                   numstring := '';
                   operand2 := 0;
                   end;
              if keyfunction = '=' THEN               { equals only }
                   begin
                   operator := ' ';
                   opnum := 0;                        { ready for operand 1 }
                   end;
              end;

        'C' : begin                              { Clear key }
              clrscr;
              opnum := 0;
              end;

        'X' : begin                              { Exit key }
              window(1,1,80,25);
              textbackground(black);
              textcolor(lightgray);
              clrscr;
              NormalCursor;
              {
               De-activate the pads
              }
              FOR i := 1 to 18 DO
                 WITH padtable[i] DO
                    BEGIN
                    reg.AL := $14;             { De-Activate pad }
                    reg.AH := i;               { pad number }
                    INTR($66,reg);             { call the driver }
                    END;
              halt;
              end;

        ' ' : ;                        { no pad - do nothing }

        end; {case}
        end; {while }
end.
                                  
                                  





