unit UWAVFile;
// Compofiller Studio
// by Yzi 2017-2018

// WAV file writing routines.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;


// Write 16 bit stereo WAV file
// Returns 0, until someone writes error checking.
function write_wav_stereo_16bit(name : String; data : Pointer; total_size_bytes, freq : Integer) : Integer;

implementation

// WAV writing converted from C routines written by Marq a long time ago.

type TNumBytes = 1..4;

// (this will be massively useful when porting Compofiller Studio to a big-endian platform)
procedure write_lsb(val : Cardinal; numbytes : TNumBytes; var f : file);
var
  n : Integer;
  b : Byte;
begin
  for n := 1 to numbytes do
  begin
    b := val and 255;
    BlockWrite(f, b, 1);
    val := val shr 8;
  end;
end;

// Write LSB 32 bits to a file
procedure lsb32(val : Cardinal; var f : file);
begin
  write_lsb(val, 4, f);
end;

// Write LSB 16 bits to a file
procedure lsb16(val : Cardinal; var f : file);
begin
  write_lsb(val, 2, f);
end;


procedure fwrite_bytes(data : Pointer; recsize, reccount : Integer; var f : File);
begin
  BlockWrite(f, data^, recsize*reccount);
end;


function write_wav_stereo_16bit(name : String; data : Pointer; total_size_bytes, freq : Integer) : Integer;
const
  NUM_CHANNELS = 2;
  NUM_BYTES_PER_SAMPLE_FOR_SINGLE_CHANNEL = 2;
var
  f : file;
begin
  Result := -1; // this would be the return value, if there was error checking

  AssignFile(f, name);
  ReWrite(f, 1);

  try
    // RIFF chunk
    fwrite_bytes(PChar('RIFF'),1,4,f);
    lsb32(total_size_bytes+36,f);
    fwrite_bytes(PChar('WAVE'),1,4,f);

    // fmt subchunk
    fwrite_bytes(PChar('fmt '),1,4,f);
    lsb32(16,f);
    lsb16(1,f);
  //    lsb16(1,f); // mono
    lsb16(NUM_CHANNELS,f);
    lsb32(freq,f); // samples per second (SampleRate)
    lsb32(freq*2,f); // bytes per second (ByteRate)
    lsb16(NUM_CHANNELS * NUM_BYTES_PER_SAMPLE_FOR_SINGLE_CHANNEL ,f); // total bytes per sample (BlockAlign)
    lsb16(NUM_BYTES_PER_SAMPLE_FOR_SINGLE_CHANNEL * 8,f); // bits per sample

    // data subchunk
    fwrite_bytes(PChar('data'),1,4,f);
    lsb32(total_size_bytes,f);
    fwrite_bytes(data,1,total_size_bytes,f);
  finally
    CloseFile(f);
  end;

  Result := 0;
end; // write_wav_stereo_16bit



end.

