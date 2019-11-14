{$mode objfpc}
{$modeswitch objectivec1}
{$modeswitch cblocks}

unit CocoaUtils;
interface
uses
  SysUtils, CocoaAll;

function ShowAlert(messageText: ansistring; informativeText: ansistring = ''; sheetWindow: NSWindow = nil): NSModalResponse;

operator = (left: NSString; right: string): boolean;
operator explicit (right: NSObject): string;

implementation

type
  NSAlertCompletionBlock = reference to procedure(response: NSModalResponse); cdecl;

procedure AlertCompleted(response: NSModalResponse);
begin
  writeln('response: ', response);
end;

function ShowAlert(messageText: ansistring; informativeText: ansistring = ''; sheetWindow: NSWindow = nil): NSModalResponse;
var
  alert: NSAlert;
  completionHandler: NSAlertCompletionBlock;
begin
  alert := NSAlert.alloc.init;
  alert.setMessageText(NSSTR(messageText));
  if informativeText <> '' then
    alert.setInformativeText(NSSTR(informativeText));
  alert.addButtonWithTitle(NSSTR('Ok'));
  if sheetWindow <> nil then
    begin
      completionHandler := @AlertCompleted;
      alert.beginSheetModalForWindow_completionHandler(sheetWindow, OpaqueCBlock(completionHandler));
      result := -1;
    end
  else
    result := alert.runModal;
end;

operator = (left: NSString; right: string): boolean;
begin
  result := (left.UTF8String = right);
end;

operator explicit (right: NSObject): string;
begin
  result := right.description.UTF8String;
end;

end.