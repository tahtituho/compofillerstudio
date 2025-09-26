unit UPreprocessShader;
// Compofiller Studio by Yzi 2017
// Shader source preprocessing functions.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

// Scan through AStrings and clear out all C comments
procedure RemoveCComments(AStrings : TStrings);

// Convert shader source code from .h file made by Shader Minifier into a single plain string.
// This is a semi-working kludge, but it'll do for the time being.
//
//   AStrings : input strings         Note: comments "in-place" from AStrings.
//   APlainString : plain single-string shader text (output)
//   AVariableNames : substituted variable names from #defines (output).
//                    You can give nil in AVariableNames, if you don't want the variable names.
procedure ShaderMinifierHToPlainString(AStrings: TStrings; var APlainString : String; AVariableNames : TStrings);

implementation

uses
  StrUtils;

procedure RemoveCComments(AStrings : TStrings);
var
  comment : Boolean;
  i, j : Integer;
  line : String;
begin
  comment := false;
  for i := 0 to AStrings.Count - 1 do
  begin
    line := AStrings[i];
    j := 1;
    while j <= Length(line) do
    begin
      if not comment then
      begin
        if (j < Length(line)) and (line[j] = '/') and (line[j+1] = '*') then
        begin
          comment := true;
          line[j] := ' ';
          line[j+1] := ' ';
          Inc(j, 2);
        end
        else if (j < Length(line)) and (line[j] = '/') and (line[j+1] = '/') then
        // beginning of single-line comment: clear until end of line
          while (j <= Length(line)) do
          begin
            line[j] := ' ';
            Inc(j);
          end
        else
          Inc(j);
      end
      else
      begin // we're inside a comment... the only thing we want to find is "*/"
        if (j < Length(line)) and (line[j] = '*') and (line[j+1] = '/') then
        begin
          line[j] := ' ';
          line[j+1] := ' ';
          comment := false;
          Inc(j, 2);
        end
        else
        begin
          line[j] := ' ';
          Inc(j);
        end;
      end;
    end; // while j
    AStrings[i] := line;
  end; // while i
end; // RemoveCComments

function ReplaceEscapeSequences(AString : String) : String;
begin
  // TODO!!!
  Result := AnsiReplaceStr(AString, '\n', #13#10);
end;

procedure ShaderMinifierHToPlainString(AStrings: TStrings; var APlainString : String; AVariableNames : TStrings);
const
  DEFINE_VAR_PREFIX = 'define VAR_';
var
  i, quotepos1, quotepos2, definevarpos, spacepos : Integer;
  line, def,
    s, t, u : String;
begin
  APlainString := '';
  RemoveCComments(AStrings); // don't have to care about comments now

  for i := 0 to AStrings.Count - 1 do
  begin
    line := Trim(AStrings[i]);
    definevarpos := Pos(DEFINE_VAR_PREFIX, line);
    quotepos1 := Pos('"', line);
    if (definevarpos > 0) and (definevarpos < quotepos1) then
    begin // something like # define VAR_RESOLUTION "d"
      def := Copy(line, definevarpos + Length(DEFINE_VAR_PREFIX), Length(line)-Length(DEFINE_VAR_PREFIX)-definevarpos+1);
      spacepos := Pos(' ', def);
      if spacepos > 0 then // there SHOULD be a space
      begin
        def[spacepos] := '='; // now it should be like, RESOLUTION="a" or something
        def := AnsiReplaceStr(def, '"', ''''); // we want the uniform names in hyphens
        if AVariableNames <> nil then
          AVariableNames.Add(def);
      end;
    end
    else
    begin
      if (quotepos1 > 0) then
      begin // there has to be a quote on the line, or otherwise it cannot contain anything we want
        s := Copy(line, quotepos1+1, Length(line)-quotepos1);
        if s <> '' then
        begin
          quotepos2 := Pos('"', s);
          if quotepos2 > 0 then
          begin
            t := Copy(s, 1, quotepos2-1);
            if t <> '' then
            begin
              u := ReplaceEscapeSequences(t);
              if u <> '' then
                APlainString := APlainString + u;
            end;
          end
          else
            raise Exception.CreateFmt('Error: ending quote missing on shader source line %d', [i]);
        end;
      end;
    end; // if quote...
  end; // for AStrings
end; // ShaderMinifierHToPlainString

end.

