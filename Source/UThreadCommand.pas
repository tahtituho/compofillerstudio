unit UThreadCommand;
// Compofiller Studio
// by Yzi 2017

{
  So what is this thread and command proxy nonsense?
  - OpenGL is meant to be run in one thread. And in this case I don't want
    that thread to be the main thread, which runs the Win32/GDI based GUI.
  - I wanted to have all OpenGL stuff running in a separate thread, because it
    was to be expected that the stuff will crash and jam regularly, and we'd
    need some facilities to terminate and re-start it somewhat cleanly without
    bringing down the whole application.
  - Lazarus/FPC has TThread.Synchronize, but... as far as I understand, it runs
    things in the _main_ thread, but we want to run things in a non-main thread.
  - TThread.Synchronize doesn't have a timeout option. And I want to have a
    timeout, because this OpenGL stuff will be jamming.
  - An entirely separate process might be even better, but I'll try threads first.
  - I wanted to try writing a contraption like this.

  The command proxy has a command queue, and whenever the visuals thread
  is ready to execute a command (i.e. when it has finished drawing a frame),
  it will get one from the proxy's queue and run the given method with the
  given parameter (which might be a pointer to a struct/record).

  In "batch mode", the proxy will keep holding the queue mutex, until batch mode
  turned off. The dequeue operation (which the visuals thread uses for retrieving
  its commands) will block until batch mode is ended.
  This could be used to give an entire set of commands, which the visuals thread
  doesn't start executing before the whole set has been queued.

  The actual TRunThreadCommandProxy derives from TThreadCommandProxy and is
  implemented in URunThread.pas. This TThreadCommandProxy is kind of generic
  and could be used in any application needing a thread synchronization and
  commanding/messaging facility.

}


{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Windows;

const
  COMMAND_QUEUE_TIMEOUT_MILLISECONDS = 15000; // lower this when not debugging
  QUEUE_ARRAY_SIZE = 64;
  QUEUE_MAX_COMMANDS = QUEUE_ARRAY_SIZE - 1;

type
  TThreadCommandFunc = procedure(AData : Pointer) of object;

  { TThreadCommandRec }

  TThreadCommandRec = object
    Func : TThreadCommandFunc;
    Data : Pointer;
    EventHandle : THandle;
    procedure Initialize; // clears the whole thing
  end;
  PThreadCommandRec = ^TThreadCommandRec;

  // The thread command queue should be owned by the main/GUI thread,
  // so that a runner thread can be terminated without losing the
  // commands as well.

  TThreadCommadQueueResult = (
    tcqOk, // command pushed/popped and executed successfully
    tcqQueueEmpty, // queue was empty, nothing to execute
    tcqTimeout, // could not get lock, timed out
    tcqThreadCrashed,
    tcqSomeUnknownThing
  );

  { TThreadCommandRecQueue }

  TThreadCommandRecQueue = object
    Head : Integer;
    Tail : Integer;
    Items : array[0..QUEUE_MAX_COMMANDS] of TThreadCommandRec;
    procedure Push(AFunc : TThreadCommandFunc; AData : Pointer; AEventHandle : THandle);
    procedure PushRec(const ARec : TThreadCommandRec);
    function Pop : TThreadCommandRec;
    function Full : Boolean;
    function Empty : Boolean;
    procedure Init;
  end;

  { TThreadCommandProxy }

  TThreadCommandProxy = class(TObject)
  private
    FQueueMutex : THandle;
    FQueue : TThreadCommandRecQueue;
    FBatchMode : Boolean;

  protected
    FThreadCrashed : Boolean;
    FCrashInfo : String;

  public
    constructor Create; virtual;
    destructor Destroy; override;


    // Command issuer calls these functions
    function ExecuteCommandFuncSync(AFunc : TThreadCommandFunc; AData : Pointer) : TThreadCommadQueueResult; // Synchronous

    function Enqueue(const AThreadCommandRec : TThreadCommandRec) : TThreadCommadQueueResult; // Asynchronous
    function EnqueueFunc(AFunc: TThreadCommandFunc; AData: Pointer): TThreadCommadQueueResult; // Asynchronous
    function StartBatch : TThreadCommadQueueResult;
    function EndBatch : TThreadCommadQueueResult;

    // Runner thread calls this
    function DequeueAndExecute : TThreadCommadQueueResult;

    procedure MarkThreadAsCrashed(ACrashInfo : String);

    property ThreadCrashed : Boolean read FThreadCrashed;
    property ThreadCrashInfo : String read FCrashInfo;
  end;


implementation

const
  WAIT_ABANDONED = $80;

{ TThreadCommandRecQueue }

procedure TThreadCommandRecQueue.Push(AFunc: TThreadCommandFunc;
  AData: Pointer; AEventHandle: THandle);
var
  newitem : PThreadCommandRec;
begin
  if Self.Full then
    raise Exception.Create('COMMAND QUEUE FULL!');

  newitem := @Items[Head];
  newitem^.Func := AFunc;
  newitem^.Data := AData;
  newitem^.EventHandle := AEventHandle;

  Head := (Head + 1) mod QUEUE_ARRAY_SIZE;
end;

procedure TThreadCommandRecQueue.PushRec(const ARec : TThreadCommandRec);
var
  newitem : PThreadCommandRec;
begin
  if Self.Full then
    raise Exception.Create('COMMAND QUEUE FULL!');

  newitem := @Items[Head];
  newitem^ := ARec;

  Head := (Head + 1) mod QUEUE_ARRAY_SIZE;
end;

function TThreadCommandRecQueue.Pop: TThreadCommandRec;
begin
  if Self.Empty then
    raise Exception.Create('COMMAND QUEUE EMPTY!');

  Result := Items[Tail];
  Tail := (Tail + 1) mod QUEUE_ARRAY_SIZE;
end;

function TThreadCommandRecQueue.Full: Boolean;
begin
  Result := (((Head + 1) mod QUEUE_ARRAY_SIZE) = Tail);
end;

function TThreadCommandRecQueue.Empty: Boolean;
begin
  Result := (Head = Tail);
end;

procedure TThreadCommandRecQueue.Init;
begin
  Head := 0;
  Tail := 0;
end;

{ TThreadCommandRec }

procedure TThreadCommandRec.Initialize;
begin
  FillChar(Self, SizeOf(Self), 0);
end;

{ TThreadCommandProxy }

constructor TThreadCommandProxy.Create;
begin
  FQueue.Init;
  FQueueMutex := Windows.CreateMutex(nil, false, nil);
//  InitCriticalSection(FQueueLock);
end;

destructor TThreadCommandProxy.Destroy;
begin
  Windows.CloseHandle(FQueueMutex);
//  DoneCriticalsection(FQueueLock);
//  FreeAndNil(FQueue);

  inherited Destroy;
end;

function TThreadCommandProxy.ExecuteCommandFuncSync(
  AFunc: TThreadCommandFunc; AData: Pointer
  ): TThreadCommadQueueResult;
var
  rec : TThreadCommandRec;
  wait_result : DWORD;
begin
  if FThreadCrashed then
  begin
    Result := tcqThreadCrashed;
    Exit;
  end;

  rec.Func := AFunc;
  rec.Data := AData;
  rec.EventHandle := Windows.CreateEvent(nil, True, False, nil);
  try
    Result := Enqueue(rec);
    if Result = tcqOk then
    begin // to make this synchronous, we wait for the command's execution to finish
      wait_result := Windows.WaitForSingleObject(rec.EventHandle, COMMAND_QUEUE_TIMEOUT_MILLISECONDS);
      if FThreadCrashed then
        Result := tcqThreadCrashed
      else if wait_result <> WAIT_OBJECT_0 then
        Result := tcqTimeout;
//        raise Exception.Create('timeout');
      //  Windows.MessageBox(0, 'A thread might be jammed or something.', 'Is this normal?', Windows.MB_OK);
    end;
  finally
    CloseHandle(rec.EventHandle);
  end;
end;

function TThreadCommandProxy.EnqueueFunc(
  AFunc: TThreadCommandFunc; AData: Pointer
  ): TThreadCommadQueueResult;
var
  rec : TThreadCommandRec;
begin
  rec.Func := AFunc;
  rec.Data := AData;
  rec.EventHandle := 0;
  Result := Enqueue(rec);
end;

function TThreadCommandProxy.StartBatch: TThreadCommadQueueResult;
var
  wait_result : DWORD;
begin
  Result := tcqSomeUnknownThing;
  wait_result := Windows.WaitForSingleObject(FQueueMutex, COMMAND_QUEUE_TIMEOUT_MILLISECONDS);
  case wait_result of
    WAIT_OBJECT_0 : begin Result := tcqOk; FBatchMode := true; end;
    WAIT_ABANDONED : Result := tcqTimeout;
  end; // case wait_result
end;

function TThreadCommandProxy.EndBatch: TThreadCommadQueueResult;
begin
  FBatchMode := false;
  Windows.ReleaseMutex(FQueueMutex);
  Result := tcqOk;
end;

procedure TThreadCommandProxy.MarkThreadAsCrashed(ACrashInfo : String);
begin
  if FBatchMode then
  begin
    // this should not happen?
    FThreadCrashed := true;
  end
  else
  begin
    Windows.WaitForSingleObject(FQueueMutex, COMMAND_QUEUE_TIMEOUT_MILLISECONDS);
    // Regardless of whether the wait timed out, we just set the thread crashed flag.
    // Something went wrong anyway.
    FThreadCrashed := true;
    FCrashInfo := ACrashInfo;
  end;
end; // TThreadCommandProxy.MarThreadAsCrashed

function TThreadCommandProxy.Enqueue(const AThreadCommandRec : TThreadCommandRec) : TThreadCommadQueueResult;
var
  wait_result : DWORD; // Windows.TWait
begin
  if FThreadCrashed then
  begin
    Result := tcqThreadCrashed;
    Exit;
  end;

  if FBatchMode then
  begin
    if FThreadCrashed then
      Result := tcqThreadCrashed
    else
    begin
      FQueue.PushRec(AThreadCommandRec);
      Result := tcqOk;
    end;
  end
  else
  begin
    Result := tcqSomeUnknownThing;
    wait_result := Windows.WaitForSingleObject(FQueueMutex, COMMAND_QUEUE_TIMEOUT_MILLISECONDS);
    if FThreadCrashed then
      Result := tcqThreadCrashed
    else
    begin
      case wait_result of
        WAIT_OBJECT_0 :
          try
            FQueue.PushRec(AThreadCommandRec);
            Result := tcqOk;
          finally
            Windows.ReleaseMutex(FQueueMutex);
          end;
        WAIT_ABANDONED : Result := tcqTimeout;
      end; // case wait_result
    end;
  end;
end; // TThreadCommandProxy.Enqueue

// function TThreadCommandProxy.DequeueAndExecute(AThread: TThread) : TThreadCommadQueueResult;
function TThreadCommandProxy.DequeueAndExecute : TThreadCommadQueueResult;
var
  wait_result : DWORD;
  cmd : TThreadCommandRec;
begin
  if FThreadCrashed then
    Result := tcqThreadCrashed
  else
  begin
    Result := tcqSomeUnknownThing;
    wait_result := Windows.WaitForSingleObject(FQueueMutex, COMMAND_QUEUE_TIMEOUT_MILLISECONDS);
    case wait_result of
      WAIT_OBJECT_0 :
        try
          if FQueue.Empty then
            Result := tcqQueueEmpty
          else
          begin
            cmd := FQueue.Pop;             // get command
            cmd.Func(cmd.Data); // call its function with the given data
            if cmd.EventHandle > 0 then   // and set event to signaled state, if event handle given
            begin
              if not Windows.SetEvent(cmd.EventHandle) then
                raise Exception.Create('Could not SetEvent()!');
              // now it's the caller's duty to CloseHandle the event
            end;

            Result := tcqOk;
          end;
        finally
          Windows.ReleaseMutex(FQueueMutex);
        end;
      WAIT_ABANDONED : Result := tcqTimeout;
    end; // case wait_result
  end;
end; // TThreadCommandProxy.DequeueAndExecute

end.

