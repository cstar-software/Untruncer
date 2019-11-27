{$mode objfpc}
{$modeswitch objectivec1}
{$modeswitch cblocks}
{$assertions on}

unit CocoaUtils;
interface
uses
  SysUtils, CocoaAll;

function ShowAlert(messageText: ansistring; informativeText: ansistring = ''; sheetWindow: NSWindow = nil): NSModalResponse;

operator = (left: NSString; right: string): boolean;
operator explicit (right: NSObject): string;
operator := (const right: array of const): NSMutableArray;

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

operator := (const right: array of const): NSMutableArray;
var
  i: integer;
begin
  result := NSMutableArray.array_;
  for i := 0 to high(right) do
    begin
      case right[i].vtype of
        vtInteger:
          result.addObject(NSNumber.numberWithInt(right[i].vinteger));
        vtExtended:
          result.addObject(NSNumber.numberWithDouble(right[i].vextended^));
        vtString:
          result.addObject(NSSTR(right[i].vstring^));
        vtPointer:
          result.addObject(NSObject(right[i].vpointer));
        vtAnsiString:
          result.addObject(NSSTR(right[i].vansistring));
        vtChar:
          result.addObject(NSSTR(right[i].vchar));
        otherwise
          Assert(false, 'variable argument value type '+IntToStr(right[i].vtype)+' is invalid.');
      end;
    end;
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