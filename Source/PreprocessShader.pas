program PreprocessShader;
// Compofiller Studio by Yzi 2017
// Shader preprocessor command-line utility for running in build scripts.

{$mode objfpc}{$H+}

uses
  SysUtils,
  Classes,
  UPreprocessShader;


procedure AbortWithMessage(AMessage : String);
begin
  WriteLn(AMessage);
  HALT;
end;

var
  infilename, outfilename, outfilename2 : String;
  insl : TStringList;
  outstring : String;
  outvarnames : TStringList;
  outfile : File;
begin
  infilename := '';
  outfilename := '';
  if ParamCount < 2 then
    AbortWithMessage('Usage: PreprocessShader <input file> <shader text output file> [variable names output file]');
  
  infilename := ParamStr(1);
  outfilename := ParamStr(2);
  if ParamCount > 2 then
    outfilename2 := ParamStr(3)
  else
    outfilename2 := '';
  
  insl := TStringList.Create;
  outvarnames := nil;
  try
    outvarnames := TStringList.Create;
    insl.LoadFromFile(infilename);  
    if LowerCase(ExtractFileExt(infilename)) = '.h' then
    begin
      UPreprocessShader.ShaderMinifierHToPlainString(insl, outstring, outvarnames);
      AssignFile(outfile, outfilename);
      ReWrite(outfile, 1);
      BlockWrite(outfile, outstring[1], Length(outstring));
      CloseFile(outfile);    
      WriteLn('Wrote ', Length(outstring), ' bytes to ', outfilename, '.');	    
    end
    else
    begin
      insl.SaveToFile(outfilename);
      WriteLn('Wrote the text lines from ', infilename, ' to ', outfilename, ' without processing.');	    
    end;

    if outfilename2 <> '' then
    begin
      outvarnames.SaveToFile(outfilename2);
      WriteLn('Wrote ', outvarnames.Count, ' variable substitutions ', outfilename2, '.');
    end;

  finally
    outvarnames.Free;
    insl.Free;
  end;
end.
