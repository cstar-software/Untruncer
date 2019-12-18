{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch objectivec2}
{$modeswitch autoderef}

unit AppDelegate;
interface
uses
	CThreads, Classes, FGL, CocoaAll;

type
  TDropImageView = objcclass (NSImageView, NSDraggingDestinationProtocol)        
    public
      procedure mouseDown (theEvent: NSEvent); override;

      { NSDraggingDestinationProtocol }
      function draggingEntered (sender: NSDraggingInfoProtocol): NSDragOperation; override;
      function performDragOperation (sender: NSDraggingInfoProtocol): objcbool; override;
  end;

type
  TMovieItem = record
    path: ansistring;
    class operator = (left: TMovieItem; right: TMovieItem): boolean;
  end;
  PMovieItem = ^TMovieItem;
  TMovieItemList = specialize TFPGList<TMovieItem>;

type
  TWorkerThread = class (TThread)
    procedure Execute; override;
  end;

type
	TAppDelegate = objcclass(NSObject, NSApplicationDelegateProtocol, NSTableViewDataSourceProtocol)
    private
      window: NSWindow;
      moviesTableView: NSTableView;
      startButton: NSButton;
      workingMovie: NSString;
      brokenMovies: TMovieItemList;
      dropImageView: TDropImageView;
      workerThread: TWorkerThread;
      processIndicator: NSProgressIndicator;
      progressLabel: NSTextField;
  	public
      procedure awakeFromNib; override;
      procedure start(sender: id); message 'start:';
      procedure finished(sender: id); message 'finished:';
      procedure startedProcessing(filePath: NSString); message 'startedProcessing:';
      procedure finishedProcessing(filePath: NSString); message 'finishedProcessing:';
        
      { NSApplicationDelegateProtocol }
      procedure applicationDidFinishLaunching(notification: NSNotification); message 'applicationDidFinishLaunching:';
      function applicationShouldTerminateAfterLastWindowClosed (sender: NSApplication): boolean; message 'applicationShouldTerminateAfterLastWindowClosed:';

      { NSTableViewDataSourceProtocol }
      function numberOfRowsInTableView (tableView: NSTableView): NSInteger; message 'numberOfRowsInTableView:';
      function tableView_objectValueForTableColumn_row (tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): id; message 'tableView:objectValueForTableColumn:row:';
      function tableView_acceptDrop_row_dropOperation (tableView: NSTableView; info: NSDraggingInfoProtocol; row: NSInteger; dropOperation: NSTableViewDropOperation): boolean; message 'tableView:acceptDrop:row:dropOperation:';
      function tableView_validateDrop_proposedRow_proposedDropOperation(tableView: NSTableView; info: id; row: NSInteger; dropOperation: NSTableViewDropOperation): NSDragOperation; message 'tableView:validateDrop:proposedRow:proposedDropOperation:';
 	end;

implementation
uses
  CocoaUtils, Process, SysUtils, MacOSAll;

var
  App: TAppDelegate;

type
  TMovieDetailsViewController = objcclass (NSViewController, NSPopoverDelegateProtocol)
    textField: NSTextField;
    popover: NSPopover;
    procedure popoverDidClose (notification: NSNotification); message 'popoverDidClose:';
  end;

var
  movieDetailsPopover: TMovieDetailsViewController = nil;

class operator TMovieItem.= (left: TMovieItem; right: TMovieItem): boolean;
begin
  result := (left.path = right.path);
end;

procedure TMovieDetailsViewController.popoverDidClose (notification: NSNotification);
begin
  popover.release;
  popover := nil;
  movieDetailsPopover := nil;
end;

function ShowPopover (title: string; positioningRect: NSRect; positioningView: NSView; preferredEdge: NSRectEdge = 0): id;
var
  popover: NSPopover;
  controller: TMovieDetailsViewController;
begin
  controller := TMovieDetailsViewController.alloc.initWithNibName_bundle(NSSTR('TMovieDetailsViewController'), nil).autorelease;

  popover := NSPopover.alloc.init;
  popover.setDelegate(controller);
  popover.setAnimates(true);
  popover.setBehavior(NSPopoverBehaviorTransient);

  popover.setContentViewController(controller);
  popover.setContentSize(controller.view.frame.size);
  popover.showRelativeToRect_ofView_preferredEdge(positioningRect, positioningView, preferredEdge);  
    
  { keep a reference we can release later }
  controller.popover := popover;
  controller.textField.setStringValue(NSSTR(title));

  result := controller;
end;

procedure TDropImageView.mouseDown (theEvent: NSEvent);
begin
  if assigned(movieDetailsPopover) then
    exit;
  if App.workingMovie <> nil then
    movieDetailsPopover := ShowPopover(string(App.workingMovie), bounds, self)
  else
    movieDetailsPopover := ShowPopover('Drop working video here', bounds, self)
end;

function TDropImageView.draggingEntered (sender: NSDraggingInfoProtocol): NSDragOperation;
begin
  if not App.processIndicator.isHidden then
    exit(NSDragOperationNone)
  else
    result := NSDragOperationCopy;
end;

function TDropImageView.performDragOperation (sender: NSDraggingInfoProtocol): objcbool;
var
  pasteboardItem: NSPasteboardItem;
  urlString: NSString;
  url: NSURL;
  fileImage: NSImage;
begin
  for pasteboardItem in sender.draggingPasteboard.pasteboardItems do
    begin
      urlString := pasteboardItem.stringForType(NSString(kUTTypeFileURL));
      writeln(urlString.UTF8String);
      url := NSURL.URLWithString(urlString);
      App.workingMovie := url.path.retain;

      fileImage := NSWorkspace.sharedWorkspace.iconForFile(App.workingMovie);
      setImage(fileImage);
    end;
  result := true;
end;

{$define EXECUTE_COCOA}

procedure TWorkerThread.Execute;
var
  untruncPath: ansistring;
  movie: TMovieItem;
  {$ifdef EXECUTE_COCOA}
  task: NSTask;
  {$else}
  process: TProcess;
  {$endif}
begin
  untruncPath := NSBundle.mainBundle.resourcePath.UTF8String+'/untrunc';
  while App.brokenMovies.Count > 0 do
    begin
      movie := App.brokenMovies[App.brokenMovies.Count - 1];
      writeln('processing ',movie.path);
      App.performSelectorOnMainThread_withObject_waitUntilDone(objcselector('startedProcessing:'), NSSTR(movie.path), true);

      {$ifdef EXECUTE_COCOA}
      task := NSTask.alloc.init;
      task.setLaunchPath(NSSTR(untruncPath));
      task.setArguments(NSMutableArray([App.workingMovie, movie.path]));      
      task.launch;
      task.waitUntilExit;
      task.release;
      {$else}
      // https://wiki.freepascal.org/Executing_External_Programs
      process := TProcess.Create(nil);
      process.Executable := untruncPath;
      with process.Parameters do
        begin
          Add(string(App.workingMovie));
          Add(movie.path);
        end;
      process.Options := process.Options + [poWaitOnExit];
      process.Execute;
      process.Free;
      {$endif}

      writeln('finished');

      App.brokenMovies.Remove(movie);
      App.performSelectorOnMainThread_withObject_waitUntilDone(objcselector('finishedProcessing:'), NSSTR(movie.path), true);
      writeln('next video');
    end;
  writeln('processed all');
  App.performSelectorOnMainThread_withObject_waitUntilDone(objcselector('finished:'), nil, true);
end;

function TAppDelegate.tableView_validateDrop_proposedRow_proposedDropOperation(tableView: NSTableView; info: id; row: NSInteger; dropOperation: NSTableViewDropOperation): NSDragOperation;
begin
  if not processIndicator.isHidden then
    exit(NSDragOperationNone)
  else
    result := NSDragOperationCopy;
end;

function TAppDelegate.tableView_acceptDrop_row_dropOperation (tableView: NSTableView; info: NSDraggingInfoProtocol; row: NSInteger; dropOperation: NSTableViewDropOperation): boolean;
var
  pboard: NSPasteboard;
  pasteboardItem: NSPasteboardItem;
  urlString: NSString;
  url: NSURL;
  item: TMovieItem;
begin
  pboard := NSDraggingInfoProtocol(info).draggingPasteboard;
  result := false;

  for pasteboardItem in pboard.pasteboardItems do
    begin
      urlString := pasteboardItem.stringForType(NSString(kUTTypeFileURL));
      url := NSURL.URLWithString(urlString);

      item.path := url.path.UTF8String;
      brokenMovies.Add(item);
      result :=true;
    end;
  
  if result then
    tableView.reloadData;
end;

function TAppDelegate.numberOfRowsInTableView (tableView: NSTableView): NSInteger;
begin
   result := brokenMovies.Count;
end;

function TAppDelegate.tableView_objectValueForTableColumn_row (tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): id;
begin
  result := NSSTR(ExtractFileName(brokenMovies[row].path));
end;

procedure TAppDelegate.startedProcessing(filePath: NSString);
begin
  progressLabel.setStringValue(NSSTR('Processing '+filePath.stringByAbbreviatingWithTildeInPath.UTF8String+'...'));
end;

procedure TAppDelegate.finishedProcessing(filePath: NSString);
begin
  moviesTableView.reloadData;
end;

procedure TAppDelegate.start(sender: id);
begin
  if brokenMovies.Count = 0 then
    begin
      ShowAlert('Add broken movies to the list first.', '', window);
      exit;
    end;
    
  if workingMovie = nil then
    begin
      ShowAlert('Choose a working movie first.', '', window);
      exit;
    end;

  workerThread := TWorkerThread.Create(false);

  startButton.setEnabled(false);
  processIndicator.setHidden(false);
  processIndicator.startAnimation(self);
  progressLabel.setHidden(false);
end;

procedure TAppDelegate.finished(sender: id);
begin
  startButton.setEnabled(true);
  processIndicator.setHidden(true);
  processIndicator.stopAnimation(self);
  progressLabel.setHidden(true);

  workingMovie.release;
  workingMovie := nil;

  dropImageView.setImage(nil);
end;

procedure TAppDelegate.awakeFromNib;
begin
  App := self;
  brokenMovies := TMovieItemList.Create;
  moviesTableView.registerForDraggedTypes(NSArray.arrayWithObjects(NSString(kUTTypeFileURL), nil));
end;

function TAppDelegate.applicationShouldTerminateAfterLastWindowClosed (sender: NSApplication): boolean;
begin
  result := true;
end;

procedure TAppDelegate.applicationDidFinishLaunching(notification: NSNotification);
begin
  processIndicator.setHidden(true);
  progressLabel.setHidden(true);
end;

end.