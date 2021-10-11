// efg, April 1999, www.efg2.com

unit ScreenCircleWordWrap;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Spin;

type
  TFormCircleWordWrap = class(TForm)
    Image: TImage;
    Memo: TMemo;
    SpinEditFontHeight: TSpinEdit;
    LabelFontHeight: TLabel;
    LabelDiameter: TLabel;
    SpinEditDiameter: TSpinEdit;
    CheckBoxCircle: TCheckBox;
    CheckBoxLines: TCheckBox;
    ComboBoxFont: TComboBox;
    LabelFont: TLabel;
    LabelLabURL1: TLabel;
    LabelLabURL2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure MemoChange(Sender: TObject);
    procedure SpinEditFontHeightChange(Sender: TObject);
    procedure CheckBoxCircleClick(Sender: TObject);
    procedure ComboBoxFontChange(Sender: TObject);
    procedure LabelLabURL2Click(Sender: TObject);
  private
    PROCEDURE UpdateDisplay;
  public
    { Public declarations }
  end;

var
  FormCircleWordWrap: TFormCircleWordWrap;

implementation
{$R *.DFM}

  USES
    ShellAPI;   //  ShellExecute

// When anything is changed, update everything on the display
PROCEDURE TFormCircleWordWrap.UpdateDisplay;
  VAR
    Diameter     :  INTEGER;
    Bitmap       :  TBitmap;
    Index        :  INTEGER;
    Line         :  INTEGER;
    LineCount    :  INTEGER;
    LineHeight   :  INTEGER;
    Radius       :  INTEGER;
    s            :  STRING;
    TextLine     :  STRING;
    x            :  INTEGER;
    xLow         :  INTEGER;
    xMiddle      :  INTEGER;
    y            :  INTEGER;
    yMiddle      :  INTEGER;
    yRemaining   :  INTEGER;
    yTopAndBottom:  INTEGER;

  // Extract string with current font of specified width from
  // "Remaining" string.  "Remaining" is updated to exclude
  // any part of the returned string.
  FUNCTION GetStringThatFits(VAR Remaining:  STRING;
                             CONST Width:  INTEGER):  STRING;
    VAR
      PixelCount:  INTEGER;
      Index     :  INTEGER;
      OK        :  BOOLEAN;
      NextWord  :  STRING;
  BEGIN
    Remaining := Trim(Remaining);  // Get rid of leading/trailing blanks
    RESULT := '';
    OK := TRUE;

    PixelCount := 0;

    WHILE (LENGTH(Remaining) > 0) AND OK
    DO BEGIN
      Index := POS(' ',Remaining);  // Find first blank (fix for multiple blanks)
      IF   Index > 0
      THEN BEGIN
        // try next word
        NextWord := COPY(Remaining, 1, Index-1);
        IF  PixelCount + Bitmap.Canvas.TextWidth(' ' + NextWord) < Width
        THEN BEGIN
          RESULT := RESULT + ' ' + NextWord;
          INC(PixelCount, Bitmap.Canvas.TextWidth(' ' + NextWord));
          Delete(Remaining,1,index)
        END
        ELSE OK := FALSE
      END
      ELSE BEGIN
        // If the LENGTH(RESULT) > 0, then do nothing this time
        // since text will be on next line.  If no text is on this line
        // then consider one character at a time so text will be
        // displayed even when there is no convenient way to break it up.
        IF   LENGTH(RESULT) = 0
        THEN BEGIN
          // Will not fit.  Consider one character at at time.
          WHILE (LENGTH(Remaining) > 0) AND
                (PixelCount + Bitmap.Canvas.TextWidth(Remaining[1]) < Width)
          DO BEGIN
            RESULT := RESULT + Remaining[1];
            INC(PixelCount, Bitmap.Canvas.TextWidth(Remaining[1]));
            Delete(Remaining, 1, 1)
          END
        END
        ELSE BEGIN
          // Will Remaining fit on current line?
          IF   PixelCount + Bitmap.Canvas.TextWidth(' ' + Remaining) < Width
          THEN BEGIN
            RESULT := RESULT + ' ' + Remaining;
            Remaining := ''
          END
        END;

        OK := FALSE;
      END
    END;

    RESULT := Trim(RESULT);  // Just in case.  Is this necessary?
  END {GetFit};

begin
  TextLine := Memo.Text;
  Index := POS(#$0D, TextLine);
  WHILE  Index > 0 DO
  BEGIN
    Delete(TextLine, Index, 2);     // Get rid of CR ($0D) + LF ($0A)
    Insert(' ', TextLine, Index);   // Separate lines by single blank
    Index := POS(#$0D, TextLine);
  END;

  Diameter := SpinEditDiameter.Value;

  // Adjust size of TImage to reduce flicker
  Image.Width  := Diameter;
  Image.Height := Diameter;

  Radius   := Diameter DIV 2;
  xMiddle  := Radius;
  yMiddle  := Radius;;
  Bitmap := TBitmap.Create;
  Bitmap.Width  := Diameter;
  Bitmap.Height := Diameter;
  Bitmap.Canvas.Pen.Color := clRed;
  Bitmap.Canvas.Brush.Style := bsClear;

  IF   CheckBoxCircle.Checked
  THEN Bitmap.Canvas.Ellipse (0,0, Diameter,Diameter);

  Bitmap.Canvas.Font.Name := ComboBoxFont.Text;
  Bitmap.Canvas.Font.Height := SpinEditFontHeight.Value;   // pixels

  LineHeight := Bitmap.Canvas.Font.Height;

  // Subtract 1 to make sure approx. half blank line is at top and bottom.
  LineCount := Diameter DIV LineHeight - 1;

  yTopAndBottom := Diameter - LineCount*LineHeight;
  yRemaining := Diameter - YTopAndBottom;

  FOR Line := 0 TO LineCount-1 DO
  BEGIN
    y := yTopAndBottom DIV 2 +
         MulDiv(yRemaining, Line, LineCount);

    // Use equation of circle:  x^2 + y^2 = R^2
    x    := ROUND(SQRT(SQR(Radius) - SQR(y-yMiddle)));
    xLow := ROUND(SQRT(SQR(Radius) - SQR(y+LineHeight-yMiddle)));

    IF   y > yMiddle
    THEN x := xLow;

    // Draw whole rectangle -- really only need 3 sides except for the
    // bottom row, but it's easier just to always draw the complete
    // rectangle.
    IF   CheckBoxLines.Checked
    THEN BEGIN
      Bitmap.Canvas.MoveTo(xMiddle-x, y);
      Bitmap.Canvas.LineTo(xMiddle+x, y);
      Bitmap.Canvas.LineTo(xMiddle+x, y+LineHeight);
      Bitmap.Canvas.LineTo(xMiddle-x, y+LineHeight);
      Bitmap.Canvas.LineTo(xMiddle-x, y)
    END;

    s := GetStringThatFits(TextLine, 2*x);
    Bitmap.Canvas.TextOut(xMiddle-x +
                          (2*x - Bitmap.Canvas.TextWidth(s)) DIV 2,
                          y, s);
  END;

  // Assume TImage is Diameter+2*Margin square (or larger)
  Image.Picture.Graphic := Bitmap;
end;


procedure TFormCircleWordWrap.FormCreate(Sender: TObject);
begin
  ComboBoxFont.Items := Screen.Fonts;
  UpdateDisplay
end;


procedure TFormCircleWordWrap.MemoChange(Sender: TObject);
begin
  UpdateDisplay
end;


procedure TFormCircleWordWrap.SpinEditFontHeightChange(Sender: TObject);
begin
  UpdateDisplay
end;


procedure TFormCircleWordWrap.CheckBoxCircleClick(Sender: TObject);
begin
  UpdateDisplay
end;


procedure TFormCircleWordWrap.ComboBoxFontChange(Sender: TObject);
begin
  UpdateDisplay
end;


procedure TFormCircleWordWrap.LabelLabURL2Click(Sender: TObject);
begin
  ShellExecute(0, 'open', pchar('http://www.efg2.com/lab'),
               NIL, NIL, SW_NORMAL)
end;

end.
