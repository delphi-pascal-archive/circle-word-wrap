// efg, April 1999, www.efg2.com

program CircleWordWrap;

uses
  Forms,
  ScreenCircleWordWrap in 'ScreenCircleWordWrap.pas' {FormCircleWordWrap};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormCircleWordWrap, FormCircleWordWrap);
  Application.Run;
end.
