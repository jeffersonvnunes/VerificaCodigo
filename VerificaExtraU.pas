unit VerificaExtraU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Mask, DB1ToolEdit, Buttons, ComCtrls,
  BtnListB;

type
  TVerificaExtraF = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    edRamoAnalise: TEdit;
    edRepositorio: TEdit;
    Label3: TLabel;
    edPastaDestino: TEdit;
    btListarArquivos: TButton;
    btCopiar: TButton;
    btLimparLista: TButton;
    btPastaRepositorio: TBitBtn;
    btPastaDestino: TBitBtn;
    Label4: TLabel;
    edRevisaoBase: TEdit;
    lbArquivos: TListBox;
    edtProgramCompar: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    edtProgramEdit: TEdit;
    Label7: TLabel;
    procedure btLimparListaClick(Sender: TObject);
    procedure btListarArquivosClick(Sender: TObject);
    procedure btCopiarClick(Sender: TObject);
    procedure btPastaRepositorioClick(Sender: TObject);
    procedure btPastaDestinoClick(Sender: TObject);
    procedure lbArquivosDblClick(Sender: TObject);
  private
    procedure ExecutaComando(const AComando: String);
  public
    { Public declarations }
  end;

var
  VerificaExtraF: TVerificaExtraF;

implementation

uses Shellapi, FileCtrl;

{$R *.dfm}

procedure TVerificaExtraF.btLimparListaClick(Sender: TObject);
begin
  lbArquivos.Clear;
end;

procedure TVerificaExtraF.ExecutaComando(const AComando: String);
var
    SHE: SHELLEXECUTEINFO;
begin
  FillChar(SHE, SizeOf(SHE), 0);
  SHE.cbSize := SizeOf(SHE);
  SHE.fMask  := See_Mask_NoCloseProcess;
  SHE.Wnd    := Handle;
  SHE.lpVerb := 'Open';
  SHE.lpFile := 'cmd';
  SHE.lpParameters := PChar('/c '+AComando);
  SHE.nShow  := SW_NORMAL;
  ShellExecuteEx(@SHE);
  WaitForSingleObject(SHE.hProcess, Infinite);
end;

procedure TVerificaExtraF.btListarArquivosClick(Sender: TObject);
var
  vArquivo: TStringList;
  vComando: String;
  SHE: SHELLEXECUTEINFO;
  vIndex: Integer;
  vPos: Integer;
  vTexto: String;
begin
  vComando := 'hg status -R '+edRepositorio.Text+
    ' --no-status --rev "branch('+edRamoAnalise.Text+')" > listaCommite.txt';

  ExecutaComando(vComando);

  vArquivo := TStringList.Create;
  try
    if FileExists(ExtractFilePath(ParamStr(0))+'\listaCommite.txt') then
    begin
      vArquivo.LoadFromFile(ExtractFilePath(ParamStr(0))+'\listaCommite.txt');

      lbArquivos.Clear;

      for vIndex := 0 to vArquivo.Count -1 do
      begin
        lbArquivos.Items.Insert(vIndex,edRepositorio.Text+'\'+vArquivo.Strings[vIndex]);
      end;
    end;

    vComando := 'hg log -R '+edRepositorio.Text+
    ' --rev "parents(min(branch('+edRamoAnalise.Text+')))" > ramoBase.txt';

    ExecutaComando(vComando);

    if FileExists(ExtractFilePath(ParamStr(0))+'\ramoBase.txt') then
    begin
      vArquivo.LoadFromFile(ExtractFilePath(ParamStr(0))+'\ramoBase.txt');

      for vIndex := 0 to vArquivo.Count -1 do
      begin
        vTexto := vArquivo.Strings[vIndex];
        if(Pos('revisão',vTexto) <> -1) then
        begin  
          vTexto := Trim(StringReplace(vTexto,'revisão:', '',[rfReplaceAll,rfIgnoreCase]));
          vPos := Pos(':',vTexto);
          edRevisaoBase.Text := Copy(vTexto, 0, vPos -1);
          Break;
        end;
      end;
    end;
    
  finally
    vArquivo.Free;
  end;
end;

procedure TVerificaExtraF.btCopiarClick(Sender: TObject);
var
  vListaArquivos: TStringList;
  vNomeArquivo, vNomeArquivoOriginal: String;
  vExtensao: String;

  procedure CopiarArquivos(const ASufixo: String);
  var
    i: Integer;
  begin
    for i := 0 to vListaArquivos.Count -1 do
    begin
      if(FileExists(vListaArquivos.Strings[i]))then
      begin
        vExtensao := ExtractFileExt(vListaArquivos.Strings[i]);
        vNomeArquivo := ExtractFileName(vListaArquivos.Strings[i]);
        vNomeArquivo := StringReplace(vNomeArquivo,vExtensao,'_'+ASufixo+vExtensao,[rfReplaceAll,rfIgnoreCase]);
        CopyFile(PAnsiChar(vListaArquivos.Strings[i]),PAnsiChar(edPastaDestino.Text+'/'+vNomeArquivo),false);

      end;
    end;
  end;
begin
  if not DirectoryExists(edPastaDestino.Text) then
  begin
    CreateDir(edPastaDestino.Text);
  end;

  vListaArquivos := TStringList.Create;
  vListaArquivos.Sorted := True;
  vListaArquivos.Duplicates := dupIgnore;
  vListaArquivos.Text := lbArquivos.Items.Text;

  CopiarArquivos('ALTERADO');
  ExecutaComando('hg update -R '+edRepositorio.Text+' --rev '+edRevisaoBase.Text+' --clean --quiet');
  CopiarArquivos('ORIGINAL');
  ExecutaComando('hg update -R '+edRepositorio.Text+' --rev '+edRamoAnalise.Text+' --clean --quiet');
end;

procedure TVerificaExtraF.btPastaRepositorioClick(Sender: TObject);
var
  vDiretorio: String;
  vRoot: WideString;
begin
  vRoot := 'C:\';

  if SelectDirectory('Selecione o repositório',vRoot, vDiretorio) then
  begin
    edRepositorio.Text := vDiretorio;
  end;
end;

procedure TVerificaExtraF.btPastaDestinoClick(Sender: TObject);
var
  vDiretorio: String;
  vRoot: WideString;
begin
  vRoot := 'C:\';

  if SelectDirectory('Selecione a pasta de destino',vRoot, vDiretorio) then
  begin
    edPastaDestino.Text := vDiretorio;
  end;
end;

procedure TVerificaExtraF.lbArquivosDblClick(Sender: TObject);
var
    vNomeArquivo
    ,filename
    ,vExtensao
    ,vNomeArquivoOriginal
    ,vNomeArquivoAlterado: string;
begin
    if lbArquivos.ItemIndex = -1 then
      Exit;

    vExtensao := ExtractFileExt(lbArquivos.Items[lbArquivos.ItemIndex]);
    vNomeArquivo := ExtractFileName(lbArquivos.Items[lbArquivos.ItemIndex]);

    vNomeArquivoOriginal := edPastaDestino.text+'\'+StringReplace(vNomeArquivo,vExtensao,'_ORIGINAL'+vExtensao,[rfReplaceAll,rfIgnoreCase]);
    vNomeArquivoAlterado := edPastaDestino.text+'\'+StringReplace(vNomeArquivo,vExtensao,'_ALTERADO'+vExtensao,[rfReplaceAll,rfIgnoreCase]);;

     if ((FileExists(vNomeArquivoOriginal)) and (FileExists(vNomeArquivoAlterado)))then
     begin
        filename := edtProgramCompar.Text;
        ShellExecute(handle,'open',PChar(filename),PChar(vNomeArquivoOriginal+' '+vNomeArquivoAlterado),'',SW_SHOWNORMAL);
     end
     else if (FileExists(vNomeArquivoOriginal)) then
     begin
        filename := edtProgramEdit.text;
        ShellExecute(handle,'open',PChar(filename),PChar(vNomeArquivoOriginal),'',SW_SHOWNORMAL);
     end
     else
     begin if (FileExists(vNomeArquivoAlterado)) then
       filename := edtProgramEdit.text;
       ShellExecute(handle,'open',PChar(filename),PChar(vNomeArquivoAlterado),'',SW_SHOWNORMAL);
     end;
end;

end.
