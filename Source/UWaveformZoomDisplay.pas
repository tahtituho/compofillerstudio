unit UWaveformZoomDisplay;
{ Compofiller Studio by Yzi

  The waveform zoom display doesn't really "zoom", but maybe once it will.

  This thing is a bit messy.
  There are integer variables describing time-dimensional positions in different "domains":
       - horizontal pixel positions, and display value cache slots
       - audio time positions, in "stereo samples", e.g. 44100 samples per second
       - audio time positions, in "mono samples" e.g. 2*44100=88200 samples per second
       - 0-based slot index values
       - length values, for length 1 you only have slot index 0

}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Controls,
  Graphics, Math;


type
  { TWaveformDisplayCache }
  TWaveformDisplayCacheValue = record
    MinPeak, MaxPeak : Integer;
  end;
  PWaveformDisplayCacheValue = ^TWaveformDisplayCacheValue;

  TWaveformDisplayCache = class(TObject)
  private
    FAllocatedLengthPixelPositions : Integer;
    FValues : PWaveformDisplayCacheValue;
    FCachedLengthPixelPositions: Integer;
    FLengthPixelPositions: Integer;
    function GetValues(APixelPosition : Integer): TWaveformDisplayCacheValue;
    procedure SetCachedLengthPixelPositions(AValue: Integer);
    procedure SetLengthPixelPositions(AValue: Integer);
    procedure SetValues(APixelPosition : Integer; AValue: TWaveformDisplayCacheValue);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure CalculateValueForPixelPosition(ACacheIdxPixelPosition: Integer;
      AAudioBuffer: PSmallInt; AAudioBufferLengthMonoSamples,
  AStartOfsMonoSamples, ANumMonoSamples: Integer);
    procedure Reallocate(ANewAllocatedLength: Integer); // resets CachedLength to zero
    property LengthPixelPositions : Integer read FLengthPixelPositions write SetLengthPixelPositions; // total audio length
    property CachedLengthPixelPositions : Integer read FCachedLengthPixelPositions write SetCachedLengthPixelPositions; // how far from the beginning is the cache filled
    property Values[APixelPosition : Integer] : TWaveformDisplayCacheValue read GetValues write SetValues;
  end;


  { TWaveformZoomDisplay }
  TWaveformZoomDisplay = class(TObject)
  private
    FAudioBuffer: Pointer;
    FAudioBufferLengthInMonoSamples: Integer;
    FAudioRenderingIsFinished: Boolean;
    FCurrentPlaybackPosition: Integer;
    FLastDrawnPlaybackPosition : Integer;

    FHeight: Integer;
    FLeftLoopLocatorPos: Integer;
    FMouseIsDown: Boolean;
    FRightLoopLocatorPos: Integer;
    FSamplesPerSecond: Integer;
    FWidth: Integer;

    FRulerHeight : Integer;
    FRulerMajorUnitDuration : Single;
    FRulerMinorUnitDuration : Single;

    FRuler2Height : Integer; // ruler 2 is always in minutes:seconds

    FCache : TWaveformDisplayCache;
    FCacheCanBeFilledUpToAtLeastPixelPosition : Integer;

    function GetDisplayXForAudioPosition(AAudioPos: Integer): Integer;
    function GetFullyCached: Boolean;
    function GetMajorTickNumber(ATime: Integer): Integer;
    function GetMinorTickNumber(ATime: Integer): Integer;
    function GetRuler2MajorTickNumber(ATime: Integer): Integer;
    function GetRuler2MinorTickNumber(ATime: Integer): Integer;

    procedure SetAudioBuffer(AValue: Pointer);
    procedure SetAudioRenderingIsFinished(AValue: Boolean);
    procedure SetBufferLength(AValue: Integer);
    procedure SetCurrentPlaybackPosition(AValue: Integer);
    procedure SetHeight(AValue: Integer);
    procedure SetLeftLoopLocatorPos(AValue: Integer);
    procedure SetMouseIsDown(AValue: Boolean);
    procedure SetRightLoopLocatorPos(AValue: Integer);
    procedure SetRulerHeight(AValue: Integer);
    procedure SetRulerMajorUnitDuration(AValue: Single);
    procedure SetRulerMinorUnitDuration(AValue: Single);
    procedure SetSamplesPerSecond(AValue: Integer);
    procedure SetWidth(AValue: Integer);

  public
    FullyInvalidatedInFullyCachedState : Boolean; // why does this feel like a kludge

    constructor Create; virtual;
    destructor Destroy; override;

    procedure Reset;

    function GetAudioPositionForDisplayPoint(X, Y : Integer) : Integer;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    // Returns a rect that can be used to invalidate only the portion of the waveform display
    // that (probably) needs updating after the last DrawWaveformBitmap() call, if current time
    // position is ANewPlaybackPosition. The rect's coordinates are local to the waveform display
    // i.e. top-left is (0,0).
    function GetRectForDrawing(ANewPlaybackPosition: Integer): TRect;

    procedure DrawWaveformBitmap(ACanvas : TCanvas; const ADestRect : TRect);
    procedure DrawBottomRuler(ACanvas: TCanvas; const ADestRect: TRect);
    procedure DrawTopRuler(ACanvas: TCanvas; const ADestRect: TRect);

    property MouseIsDown : Boolean read FMouseIsDown write SetMouseIsDown;

    property AudioBuffer : Pointer read FAudioBuffer write SetAudioBuffer;
    property AudioBufferLengthInMonoSamples : Integer read FAudioBufferLengthInMonoSamples write SetBufferLength;
    property CurrentPlaybackPosition : Integer read FCurrentPlaybackPosition write SetCurrentPlaybackPosition;

    property Width : Integer read FWidth write SetWidth;
    property Height : Integer read FHeight write SetHeight;

    property RulerHeight : Integer read FRulerHeight write SetRulerHeight;
    property RulerMajorUnitDuration : Single read FRulerMajorUnitDuration write SetRulerMajorUnitDuration;
    property RulerMinorUnitDuration : Single read FRulerMinorUnitDuration write SetRulerMinorUnitDuration;

    property LeftLoopLocatorPos : Integer read FLeftLoopLocatorPos write SetLeftLoopLocatorPos;
    property RightLoopLocatorPos : Integer read FRightLoopLocatorPos write SetRightLoopLocatorPos;

    property SamplesPerSecond : Integer read FSamplesPerSecond write SetSamplesPerSecond;
    property AudioRenderingIsFinished : Boolean read FAudioRenderingIsFinished write SetAudioRenderingIsFinished;

    property FullyCached : Boolean read GetFullyCached;
  end;


implementation

const
  ZERO_DISPLAY_CACHE_VALUE : TWaveformDisplayCacheValue = (MinPeak:0; MaxPeak:0);

{ TWaveformDisplayCache }

procedure TWaveformDisplayCache.SetCachedLengthPixelPositions(AValue: Integer);
begin
  if FCachedLengthPixelPositions=AValue then Exit;
  FCachedLengthPixelPositions:=AValue;
end;

function TWaveformDisplayCache.GetValues(APixelPosition : Integer): TWaveformDisplayCacheValue;
begin
  if (APixelPosition < 0) or (APixelPosition >= FAllocatedLengthPixelPositions) or (FValues = nil) then
  begin
    Result := ZERO_DISPLAY_CACHE_VALUE;
  end
  else
  begin
    if APixelPosition >= FCachedLengthPixelPositions then
      Result := ZERO_DISPLAY_CACHE_VALUE
    else
      Result := FValues[APixelPosition];
  end;
end;

procedure TWaveformDisplayCache.SetLengthPixelPositions(AValue: Integer);
begin
  if FLengthPixelPositions=AValue then Exit;
  if AValue > FAllocatedLengthPixelPositions then
    Reallocate(AValue);
  FLengthPixelPositions:=AValue;
  FCachedLengthPixelPositions:=0;
end;

procedure TWaveformDisplayCache.SetValues(APixelPosition : Integer; AValue: TWaveformDisplayCacheValue);
begin
  if (APixelPosition < 0) or (APixelPosition >= FAllocatedLengthPixelPositions) or (FValues = nil) then Exit;
  FValues[APixelPosition] := AValue;
  if FCachedLengthPixelPositions < APixelPosition then FCachedLengthPixelPositions := APixelPosition + 1;
end;

procedure TWaveformDisplayCache.Reallocate(ANewAllocatedLength : Integer);
begin
  if FValues <> nil then
    FreeMem(FValues);
  GetMem(FValues, ANewAllocatedLength * SizeOf(TWaveformDisplayCacheValue));
  if FValues = nil then
    raise Exception.Create('memory allocation ouch panic');
  FAllocatedLengthPixelPositions := ANewAllocatedLength;
  FCachedLengthPixelPositions := 0;
end;

constructor TWaveformDisplayCache.Create;
begin
  Reallocate(2000);
end;

destructor TWaveformDisplayCache.Destroy;
begin
  if FValues <> nil then
    FreeMem(FValues);
  FValues := nil;

  inherited Destroy;
end;

procedure TWaveformDisplayCache.CalculateValueForPixelPosition(ACacheIdxPixelPosition: Integer;
  AAudioBuffer: PSmallInt; AAudioBufferLengthMonoSamples, AStartOfsMonoSamples, ANumMonoSamples: Integer);
var
  i, s : Integer;
  a : TWaveformDisplayCacheValue;
  minval, maxval : Integer;
begin
  if AAudioBuffer = nil then Exit;
  if AStartOfsMonoSamples >= AAudioBufferLengthMonoSamples then Exit;
  if AStartOfsMonoSamples + ANumMonoSamples >= AAudioBufferLengthMonoSamples then
    ANumMonoSamples := AAudioBufferLengthMonoSamples - AStartOfsMonoSamples;
  minval := 0;
  maxval := 0;
  for i := 0 to ANumMonoSamples - 1 do
  begin
    s := AAudioBuffer[AStartOfsMonoSamples + i];
    if s < minval then minval := s;
    if s > maxval then maxval := s;
  end;
  a.MaxPeak := maxval;
  a.MinPeak := minval;
  SetValues(ACacheIdxPixelPosition, a);
end;

procedure TWaveformZoomDisplay.SetAudioBuffer(AValue: Pointer);
begin
  if FAudioBuffer=AValue then Exit;
  FAudioBuffer:=AValue;
end;

procedure TWaveformZoomDisplay.SetAudioRenderingIsFinished(AValue: Boolean);
begin
  if FAudioRenderingIsFinished=AValue then Exit;
  FAudioRenderingIsFinished:=AValue;
  // If audio rendering finished, then the cache can be filled to the end,
  // (which might have happened already anyway)
  if AValue then
    FCacheCanBeFilledUpToAtLeastPixelPosition := Self.Width-1;
end;

procedure TWaveformZoomDisplay.SetBufferLength(AValue: Integer);
begin
  if FAudioBufferLengthInMonoSamples=AValue then Exit;
  FAudioBufferLengthInMonoSamples:=AValue;
end;

procedure TWaveformZoomDisplay.SetCurrentPlaybackPosition(AValue: Integer);
begin
  if FCurrentPlaybackPosition=AValue then Exit;
  FCurrentPlaybackPosition:=AValue;
end;

procedure TWaveformZoomDisplay.SetHeight(AValue: Integer);
begin
  if FHeight=AValue then Exit;
  FHeight:=AValue;
end;

procedure TWaveformZoomDisplay.SetLeftLoopLocatorPos(AValue: Integer);
begin
  if FLeftLoopLocatorPos=AValue then Exit;
  FLeftLoopLocatorPos:=AValue;
end;

procedure TWaveformZoomDisplay.SetMouseIsDown(AValue: Boolean);
begin
  if FMouseIsDown=AValue then Exit;
  FMouseIsDown:=AValue;
end;

procedure TWaveformZoomDisplay.SetRightLoopLocatorPos(AValue: Integer);
begin
  if FRightLoopLocatorPos=AValue then Exit;
  FRightLoopLocatorPos:=AValue;
end;

procedure TWaveformZoomDisplay.SetRulerHeight(AValue: Integer);
begin
  if FRulerHeight=AValue then Exit;
  FRulerHeight:=AValue;
end;

procedure TWaveformZoomDisplay.SetRulerMajorUnitDuration(AValue: Single);
begin
  if FRulerMajorUnitDuration=AValue then Exit;
  FRulerMajorUnitDuration:=AValue;
end;

procedure TWaveformZoomDisplay.SetRulerMinorUnitDuration(AValue: Single);
begin
  if FRulerMinorUnitDuration=AValue then Exit;
  FRulerMinorUnitDuration:=AValue;
end;

procedure TWaveformZoomDisplay.SetSamplesPerSecond(AValue: Integer);
begin
  if FSamplesPerSecond=AValue then Exit;
  FSamplesPerSecond:=AValue;
end;

procedure TWaveformZoomDisplay.SetWidth(AValue: Integer);
begin
  if FWidth=AValue then Exit;
  FWidth:=AValue;
  FCache.SetLengthPixelPositions(AValue);
  Self.Reset;
end;

constructor TWaveformZoomDisplay.Create;
begin
  inherited;

  FRulerHeight := 18;
  FRuler2Height := 18;
  FCache := TWaveformDisplayCache.Create;
  FLastDrawnPlaybackPosition:=-1;
end;

destructor TWaveformZoomDisplay.Destroy;
begin
  FreeAndNil(FCache);

  inherited Destroy;
end;

procedure TWaveformZoomDisplay.Reset;
begin
  FCache.SetCachedLengthPixelPositions(0);
  FCacheCanBeFilledUpToAtLeastPixelPosition := 0;
  FLastDrawnPlaybackPosition:=-1;
  FullyInvalidatedInFullyCachedState := false;
end;

function TWaveformZoomDisplay.GetAudioPositionForDisplayPoint(X, Y: Integer): Integer;
begin
  if FWidth <= 0 then
    raise Exception.Create('No can do zero width display what');

  Result := Trunc((x * (FAudioBufferLengthInMonoSamples / 2.0)) / FWidth);
end;

function TWaveformZoomDisplay.GetDisplayXForAudioPosition(AAudioPos : Integer): Integer;
begin
  if FWidth <= 0 then
    raise Exception.Create('No can do zero width display what');

  Result := Trunc(FWidth * ((AAudioPos * 2.0) / FAudioBufferLengthInMonoSamples) + 1);
end;

function TWaveformZoomDisplay.GetFullyCached: Boolean;
begin
  Result := (FAudioBuffer <> nil) and (FCache.CachedLengthPixelPositions >= Self.Width);
end;

procedure TWaveformZoomDisplay.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FMouseIsDown := true;
end;

procedure TWaveformZoomDisplay.MouseMove(Shift: TShiftState; X, Y: Integer);
begin

end;

procedure TWaveformZoomDisplay.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FMouseIsDown := false;
end;

function TWaveformZoomDisplay.GetMajorTickNumber(ATime : Integer) : Integer;
begin
  if FRulerMajorUnitDuration < 0.0001 then
    Result := 0
  else
    Result := Trunc(ATime / FRulerMajorUnitDuration);
end;

function TWaveformZoomDisplay.GetMinorTickNumber(ATime : Integer) : Integer;
begin
  if FRulerMinorUnitDuration < 0.0001 then
    Result := 0
  else
    Result := Trunc(ATime / FRulerMinorUnitDuration);
end;


function TWaveformZoomDisplay.GetRuler2MajorTickNumber(ATime : Integer) : Integer;
begin
  if FSamplesPerSecond = 0 then
    Result := 0
  else
    Result := Trunc(Trunc(ATime / (FSamplesPerSecond * 10)) * 10);
end;

function TWaveformZoomDisplay.GetRuler2MinorTickNumber(ATime : Integer) : Integer;
begin
  if FSamplesPerSecond = 0 then
    Result := 0
  else
    Result := Trunc(ATime / FSamplesPerSecond);
end;


procedure TWaveformZoomDisplay.DrawWaveformBitmap(ACanvas : TCanvas; const ADestRect : TRect);
// Messy routine! The cache thingy was added later, so the waveform display would be
// more accurate with longer tunes, where 32 samples per pixel position isn't enough.
const
  NUM_SAMPLES_PER_X_POSITION = 32;

var
  i, pix_idx, x, audiopos, buffer_length, current_play_position, display_position : Integer;
  sampleval_l, sampleval_r : SmallInt;

  audio_buffer : PSmallInt;
  cached_value : TWaveformDisplayCacheValue;
  drawval_low, drawval_high,
  drawval_low_y, drawval_high_y,
  bm_top, bm_height, bm_width : Integer;
  addtocacheblocksize : Integer;

begin
  ACanvas.Font.Size := 8;

  bm_top := ADestRect.Top;
  bm_height := ADestRect.Bottom - ADestRect.Top + 1;
  bm_width := ADestRect.Right - ADestRect.Left + 1;

  buffer_length := FAudioBufferLengthInMonoSamples; // FEngine.GetFullAudioLengthSamples();
  if (buffer_length = 0) then Exit;
  audio_buffer := FAudioBuffer; // FEngine.FullAudioBuffer;
//  if (audio_buffer = nil) then Exit;

  sampleval_l := 0;
  sampleval_r := 0;

  // The current playback position is in stereo samples.
  current_play_position := FCurrentPlaybackPosition; // FEngine.GetCurrentAudioPosition();
  if current_play_position < 0 then
    display_position := 0
  else
  // Convert to mono samples and add a little bit to the actual position to compensate for display update lateness.
    display_position := current_play_position * 2 + 8000;

  // Fill cache with more stuff that the coarse loop considered as having been touched by the audio renderer
  if (FCache.CachedLengthPixelPositions <= FCacheCanBeFilledUpToAtLeastPixelPosition) and (FAudioBuffer <> nil) then
  begin
    for pix_idx := Max(FCache.CachedLengthPixelPositions-1, 0) to FCacheCanBeFilledUpToAtLeastPixelPosition do
    begin
      audiopos := (Trunc((Double(FAudioBufferLengthInMonoSamples div 2) / FCache.LengthPixelPositions) * pix_idx)) * 2;
      addtocacheblocksize := Trunc(Double(FAudioBufferLengthInMonoSamples div 2) / FCache.LengthPixelPositions) * 2;
      if audiopos + addtocacheblocksize >= FAudioBufferLengthInMonoSamples then // clip so cache calculation doesnt overshoot audio buffer
        addtocacheblocksize := FAudioBufferLengthInMonoSamples - audiopos;

      if addtocacheblocksize > 0 then
        FCache.CalculateValueForPixelPosition(pix_idx, PSmallInt(FAudioBuffer), FAudioBufferLengthInMonoSamples, audiopos, addtocacheblocksize);
    end;
    FCache.CachedLengthPixelPositions := FCacheCanBeFilledUpToAtLeastPixelPosition + 1;
  end;

  for x := 0 to (bm_width - 1) do
  begin
    drawval_low := MaxInt;
    drawval_high := -MaxInt;

    if x < FCache.CachedLengthPixelPositions then
    begin
      cached_value := FCache.GetValues(x);
      drawval_low := cached_value.MinPeak;
      drawval_high := cached_value.MaxPeak;
      audiopos := GetAudioPositionForDisplayPoint(x, 0) * 2;
    end
    else
    begin
      // Waveform
      i := 0;
      while i < NUM_SAMPLES_PER_X_POSITION do
      begin
        audiopos := Trunc(Double(buffer_length div 2) * Double(x * NUM_SAMPLES_PER_X_POSITION + i) / Double(bm_width * NUM_SAMPLES_PER_X_POSITION)) * 2;
        if audio_buffer <> nil then
          sampleval_l := audio_buffer[audiopos];
        drawval_low := Min(drawval_low, sampleval_l);
        drawval_high := Max(drawval_high, sampleval_l);
        if audio_buffer <> nil then
          sampleval_r := audio_buffer[audiopos + 1];
        drawval_low := Min(drawval_low, sampleval_r);
        drawval_high := Max(drawval_high, sampleval_r);

        Inc(i);
      end;
    end; // not cached yet

    if (drawval_low <> 0) and (drawval_high <> 0) and (x >= FCache.CachedLengthPixelPositions) then
    begin // If there's non-zero samples at the display's pixel position x, then we can assume
          // that the audio is completely done up to at least the previous position (x-1).
      if FCacheCanBeFilledUpToAtLeastPixelPosition < x-1 then
        FCacheCanBeFilledUpToAtLeastPixelPosition := x-1;
    end;

    ACanvas.Brush.Style := bsSolid;

    drawval_low_y := (bm_height * (drawval_low + 32768)) div 65536;
    drawval_high_y := (bm_height * (drawval_high + 32768)) div 65536;
    ACanvas.Brush.Color := clBlack;
    ACanvas.FillRect(x, bm_top, x+1, bm_top + drawval_low_y);
    if audiopos <= display_position then
      ACanvas.Brush.Color := clLime
    else
      ACanvas.Brush.Color := clGreen;
    ACanvas.FillRect(x, bm_top + drawval_low_y, x+1, bm_top + drawval_high_y+1);
    ACanvas.Brush.Color := clBlack;
    ACanvas.FillRect(x, bm_top + drawval_high_y+1, x+1, bm_top + bm_height);
  end; // for waveform bitmap width

  FLastDrawnPlaybackPosition := FCurrentPlaybackPosition;
end; // TWaveformZoomDisplay.RedrawWaveformBitmap

procedure TWaveformZoomDisplay.DrawTopRuler(ACanvas : TCanvas; const ADestRect : TRect);
const
  MAJOR_TICK_HEIGHT = 7;
  MINOR_TICK_HEIGHT = 4;
  MAJOR_TICK_COLOR = $546480;
  MINOR_TICK_COLOR = $344860;
  RULER_BACKGROUND_COLOR = $101620;
  RULER_LOOP_BACKGROUND_COLOR = $602040;

var
  display_start_time, display_end_time : Integer;
  x, buffer_length : Integer;
  left_loop_locator_x, right_loop_locator_x : Integer;

  ruler_top : Integer;
  rx0, rx1, rx2, rx3 : Integer;
  xtime,
  prevtickxtime : Integer;
  t : String;

begin
  ACanvas.Font.Size := 8;

  ruler_top := ADestRect.Top;

  left_loop_locator_x := GetDisplayXForAudioPosition(LeftLoopLocatorPos);
  right_loop_locator_x := GetDisplayXForAudioPosition(RightLoopLocatorPos);

  // Top ruler background
  if (left_loop_locator_x >= 0) and (right_loop_locator_x > left_loop_locator_x)
     and (left_loop_locator_x < Self.Width)
  then
  begin // loop locators are sensible/drawable
    rx0 := 0;
    rx1 := left_loop_locator_x;
    rx2 := Min(right_loop_locator_x, Self.Width);
    rx3 := Self.Width;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := RULER_BACKGROUND_COLOR;
    ACanvas.FillRect(rx0, ruler_top, rx1+1, FRulerHeight+1);
    ACanvas.Brush.Color := RULER_LOOP_BACKGROUND_COLOR;
    ACanvas.FillRect(rx1, ruler_top, rx2+1, FRulerHeight+1);
    if (rx3 > rx2) then
    begin
      ACanvas.Brush.Color := RULER_BACKGROUND_COLOR;
      ACanvas.FillRect(rx2, ruler_top, rx3+1, FRulerHeight+1);
    end;
  end
  else
  begin // if the loop locator positions are messed up, draw the top ruler without loop
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := RULER_BACKGROUND_COLOR;
    ACanvas.FillRect(0, ruler_top, Self.Width+1, FRulerHeight+1);
  end;

  buffer_length := FAudioBufferLengthInMonoSamples; // FEngine.GetFullAudioLengthSamples();
  if (buffer_length = 0) then Exit;

  display_start_time := 0;
  display_end_time := (buffer_length div 2) - 1;

  prevtickxtime := - 1;

  for x := 0 to (Self.Width - 1) do
  begin
    xtime := Trunc(display_start_time + (x * Double(display_end_time - display_start_time)) / Self.Width);

    ACanvas.Brush.Style := bsSolid;

    // Ruler 1 (selected time base) ticks and numbers
    if GetMajorTickNumber(xtime) > GetMajorTickNumber(prevtickxtime) then
    begin
      ACanvas.Font.Color := MAJOR_TICK_COLOR;
      ACanvas.Brush.Color := MAJOR_TICK_COLOR;
      ACanvas.FillRect(x, ruler_top, x+1, ruler_top + MAJOR_TICK_HEIGHT);
      t := IntToStr(GetMajorTickNumber(xtime));
      ACanvas.Brush.Style := bsClear;
      ACanvas.TextOut(x - ACanvas.TextWidth(t) div 2, ruler_top + MAJOR_TICK_HEIGHT, t);

      prevtickxtime := xtime;
    end
    else if GetMinorTickNumber(xtime) > GetMinorTickNumber(prevtickxtime) then
    begin // minor/smaller tick
      ACanvas.Brush.Color := MINOR_TICK_COLOR;
      ACanvas.FillRect(x, ruler_top, x+1, ruler_top + MINOR_TICK_HEIGHT);

      prevtickxtime := xtime;
    end;
  end; // for waveform bitmap width
end; // TWaveformZoomDisplay.RedrawTopRuler

procedure TWaveformZoomDisplay.DrawBottomRuler(ACanvas : TCanvas; const ADestRect : TRect);
// Messy routine! The cache thingy was added later, so the waveform display would be
// more accurate with longer tunes, where 32 samples per pixel position isn't enough.
const
  RULER2_MAJOR_TICK_HEIGHT = 6;
  RULER2_MINOR_TICK_HEIGHT = 3;
  RULER2_MAJOR_TICK_COLOR = $746480;
  RULER2_MINOR_TICK_COLOR = $404850;
  RULER2_BACKGROUND_COLOR = $281618;

var
  display_start_time, display_end_time : Integer;
  x, buffer_length : Integer;

  ruler2_top : Integer;
  xtime, ruler2_prevtickxtime : Integer;
  r2tn : Integer;
  t : String;

begin
  ACanvas.Font.Size := 8;

  ruler2_top := ADestRect.Bottom - FRuler2Height;

  // Bottom ruler background
  ACanvas.Brush.Color := RULER2_BACKGROUND_COLOR;
  ACanvas.FillRect(0, ruler2_top, Self.Width+1, ADestRect.Bottom + 1);

  buffer_length := FAudioBufferLengthInMonoSamples; // FEngine.GetFullAudioLengthSamples();
  if (buffer_length = 0) then Exit;

  display_start_time := 0;
  display_end_time := (buffer_length div 2) - 1;

  ruler2_prevtickxtime := - 1;

  for x := 0 to (Self.Width - 1) do
  begin
    xtime := Trunc(display_start_time + (x * Double(display_end_time - display_start_time)) / Self.Width);
    ACanvas.Brush.Style := bsSolid;
    // Ruler 2, minutes:seconds
    if GetRuler2MajorTickNumber(xtime) > GetRuler2MajorTickNumber(ruler2_prevtickxtime) then
    begin
      ACanvas.Font.Color := RULER2_MAJOR_TICK_COLOR;
      ACanvas.Brush.Color := RULER2_MAJOR_TICK_COLOR;
      ACanvas.FillRect(x, ruler2_top, x+1, ruler2_top + RULER2_MAJOR_TICK_HEIGHT);
      r2tn := GetRuler2MajorTickNumber(xtime);
      t := IntToStr(r2tn div 60) + ':' + IntToStr((r2tn mod 60) div 10) + IntToStr(r2tn mod 10);
      ACanvas.Brush.Style := bsClear;
      ACanvas.TextOut(x - ACanvas.TextWidth(t) div 2, ruler2_top + RULER2_MAJOR_TICK_HEIGHT, t);

      ruler2_prevtickxtime := xtime;
    end
    else if GetRuler2MinorTickNumber(xtime) > GetRuler2MinorTickNumber(ruler2_prevtickxtime) then
    begin
      ACanvas.Brush.Color := RULER2_MINOR_TICK_COLOR;
      ACanvas.FillRect(x, ruler2_top, x+1, ruler2_top + RULER2_MINOR_TICK_HEIGHT);

      ruler2_prevtickxtime := xtime;
    end;
  end; // for x
end; // TWaveformZoomDisplay.RedrawBottomRuler



function TWaveformZoomDisplay.GetRectForDrawing(ANewPlaybackPosition : Integer) : TRect;
var
  t0, t1 : Integer;
  x0, x1 : Integer;
begin
//  Result.Top := 0;
//  Result.Bottom := Self.Height+1;

  Result.Top := 0; // FRulerHeight;
  Result.Bottom := Self.Height;

  if (Self.FullyCached) then
  begin
    t0 := Min(FLastDrawnPlaybackPosition, ANewPlaybackPosition);
    t1 := Max(FLastDrawnPlaybackPosition, ANewPlaybackPosition);
    x0 := GetDisplayXForAudioPosition(t0) - 10;
    x1 := GetDisplayXForAudioPosition(t1) + 10;
    Result.Left := Max(x0, 0);
    Result.Right := Min(x1, Self.Width+1);
  end
  else
  begin
    Result.Left := 0;
    Result.Right := Self.Width+1;
  end;
end;


end.

