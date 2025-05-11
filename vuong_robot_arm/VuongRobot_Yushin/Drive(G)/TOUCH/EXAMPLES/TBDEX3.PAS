program TBdex3;
{
******************************************************************************

  PROGRAM ID:  TBDEX3.PAS
  PURPOSE:     EXAMPLE TOUCH SCREEN DRIVER APPLICATION
  AUTHOR:      TOUCHBASE LTD
  DATE:        MARCH 1990
  VERSION:     1.00
  LANGUAGE:    TURBO PASCAL 5.0

  DESCRIPTION:
  Illustrates the User ISR feature with 2 touchscreens, 
  one with the driver in int 66, and one with the driver on int 65

  DISTRIBUTION:
  You may copy, use, or distribute this program in any way you like.
  However, it requires the driver to be loaded in order to run, and TouchBase's
  normal licencing arrangements always apply to the use of its drivers.
 
******************************************************************************
}
{$V-}
uses dos, crt;
type
   CursorDef = record                  { cursor definition }
      L1,L2,R,C,P: byte;               { start/end line, row, col, page }
      end;
var
   reg:        registers;              { processor registers }
   TBdintvec:  pointer;                { Initial value of int 66 }
   oldx1,oldy1:  integer;                { old coordinates }
   newx1,newy1:  integer;                { new coordinates }
   oldx2,oldy2:  integer;                { old coordinates }
   newx2,newy2:  integer;                { new coordinates }
   Ustack1:     array[1..2500] of byte; { Stack for User ISR to use }
   Ustack2:     array[1..2500] of byte; { Stack for User ISR to use }

{---------------------------------------------------------------------------
 Get Cursor position and size
}
procedure GetCursor(var Cursor: CursorDef);
var
   reg:        registers;              { processor registers }
begin
   reg.ah := $0F;                      { Get video mode }
   intr($10,reg);                      { BIOS video services }
   Cursor.P := reg.bh;                 { save current video page }
   reg.ah := $03;                      { Read cursor position and status }
   intr($10,reg);                      { BIOS video services }
   Cursor.L1 := reg.ch;                { start line }
   Cursor.L2 := reg.cl;                { end line }
   Cursor.R := reg.dh;                 { row }
   Cursor.C := reg.dl;                 { column }
end;

{---------------------------------------------------------------------------
 Set Cursor Position and size
}
procedure SetCursor(Cursor: CursorDef);
var
   reg:        registers;              { processor registers }
begin
   reg.ah := $02;                      { Set Cursor Position }
   reg.bh := Cursor.P;                 { video page }
   reg.dh := Cursor.R;                 { row }
   reg.dl := Cursor.C;                 { column }
   intr($10,reg);                      { BIOS video services }
   reg.ah := $01;                      { Set Cursor Size }
   reg.ch := Cursor.L1;                { start line }
   reg.cl := Cursor.L2;                { end line }
   intr($10,reg);                      { BIOS video services }
end;

{---------------------------------------------------------------------------
 This is the User Interrupt Service Routine for touchscreen 1
 It gets called by the driver whenever a touch event occurs
}
{$F+} { need a far return }
procedure UserISR1;
var
   reg: registers;
   CursorSave: CursorDef;              { buffer to store cursor definition }
begin
   reg.AL := $01;                      { read function }
   INTR($66,reg);                      { call the driver }
   oldx1 := newx1;                       { save old coordinates }
   oldy1 := newy1;
   newx1 := reg.bx;                     { update new coordinates }
   newy1 := reg.cx;
   GetCursor(CursorSave);              { save foreground cursor }
   if (oldx1 <> newx1) or (oldy1 <> newy1) then  { if location has changed }
      begin
      Gotoxy(oldx1,oldy1);                     { go clear old 'X' }
      write(' ');
      end;
   Gotoxy(newx1,newy1);                        { go to write new 'X' }
   write('1');
   SetCursor(CursorSave);              { re-instate foreground cursor }
end;
{$F-}

{---------------------------------------------------------------------------
 This is the User Interrupt Service Routine for touchscreen 2
 It gets called by the driver whenever a touch event occurs
}
{$F+} { need a far return }
procedure UserISR2;
var
   reg: registers;
   CursorSave: CursorDef;              { buffer to store cursor definition }
begin
   reg.AL := $01;                      { read function }
   INTR($65,reg);                      { call the driver }
   oldx2 := newx2;                       { save old coordinates }
   oldy2 := newy2;
   newx2 := reg.bx;                     { update new coordinates }
   newy2 := reg.cx;
   GetCursor(CursorSave);              { save foreground cursor }
   if (oldx2 <> newx2) or (oldy2 <> newy2) then  { if location has changed }
      begin
      Gotoxy(oldx2,oldy2);                     { go clear old 'X' }
      write(' ');
      end;
   Gotoxy(newx2,newy2);                        { go to write new 'X' }
   write('2');
   SetCursor(CursorSave);              { re-instate foreground cursor }
end;
{$F-}

{---------------------------------------------------------------------------
 Disconnect the UserISR's
 This procedure is connected as Turbo Pascal's exit procedure, so it gets
 called no matter how the program exits - even if it's by Control-Break.
}
{$F+} { need a far return }
procedure MyExit;
begin
   reg.al := $22;                            { set user ISR address }
   reg.es := 0;                              { disable User ISR }
   intr($66,reg);                            { call driver }
   reg.al := $22;                            { set user ISR address }
   reg.es := 0;                              { disable User ISR }
   intr($65,reg);                            { call driver }
end;
{$F-}


{                                             
============================================================================
                      MAIN  BODY
============================================================================
}
begin
   clrscr;
   oldx1 := 40;
   oldy1 := 12;
   newx1 := 40;
   newy1 := 12;
   oldx2 := 40;
   oldy2 := 12;
   newx2 := 40;
   newy2 := 12;
{
 Make sure the drivers are loaded otherwise we'll crash
 the machine calling int 65 or 66 pointing to address 0000:0000
}
   GETINTVEC($66, TBdintvec);
   IF TBdintvec = NIL THEN
      BEGIN
      WRITELN('Touchscreen driver not loaded on int 66');
      HALT(1);
      END;
   GETINTVEC($65, TBdintvec);
   IF TBdintvec = NIL THEN
      BEGIN
      WRITELN('Touchscreen driver not loaded on int 65');
      HALT(1);
      END;
{
 Set driver to 76 x 25 scale
}
   reg.bx := 80;
   reg.cx := 25;                             { set scale to 80 x 25 }
   reg.dl := 0;                              { don't change Z scale }
   reg.ah := 1;                              { origin to 1 }
   reg.AL := $02;                            { set scale function }
   intr($66,reg);                            { call driver }
{
 Connect our User ISR
}
   reg.al := $22;                            { set user ISR address }
   reg.es := Seg(UserISR1);
   reg.bx := Ofs(UserISR1);                   { es:bx -> User ISR }
   reg.di := Seg(Ustack1);
   reg.si := Ofs(Ustack1[SizeOf(Ustack1)]);    { di:si -> User Stack }
   reg.dx := Dseg;                           { our data segment address }
   reg.cl := 0;                              { no time axis events }
   reg.ch := 0;                              { no Z axis events }
   intr($66,reg);                            { call driver }
{
****************************************************
}
{
 Set driver to 76 x 25 scale
}
   reg.bx := 80;
   reg.cx := 25;                             { set scale to 80 x 25 }
   reg.dl := 0;                              { don't change Z scale }
   reg.ah := 1;                              { origin to 1 }
   reg.AL := $02;                            { set scale function }
   intr($65,reg);                            { call driver }
{
 Connect our User ISR
}
   reg.al := $22;                            { set user ISR address }
   reg.es := Seg(UserISR2);
   reg.bx := Ofs(UserISR2);                   { es:bx -> User ISR }
   reg.di := Seg(Ustack2);
   reg.si := Ofs(Ustack2[SizeOf(Ustack2)]);    { di:si -> User Stack }
   reg.dx := Dseg;                           { our data segment address }
   reg.cl := 0;                              { no time axis events }
   reg.ch := 0;                              { no Z axis events }
   intr($65,reg);                            { call driver }
{
*************************************************************
}
{
 Connect Turbo exit procedure
}
   ExitProc := @MyExit;
{
 The UserISR will run happily even while we're stuck inside Readln
}
   Writeln('Touch the screen, and type some text - Press Enter to exit');
   Readln;
{
 Enter pressed ...
}
   gotoxy(1,24);
   writeln('Program terminated');
end.
                                  
                                  





