program VerificaExtra;

uses
  Forms,
  VerificaExtraU in 'VerificaExtraU.pas' {VerificaExtraF};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TVerificaExtraF, VerificaExtraF);
  Application.Run;
end.
