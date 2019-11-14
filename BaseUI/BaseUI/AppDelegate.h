#import <Cocoa/Cocoa.h>

@interface TAppDelegate : NSObject <NSApplicationDelegate>
@property (weak) IBOutlet NSTableView *moviesTableView;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSImageView *dropImageView;
@property (weak) IBOutlet NSProgressIndicator *processIndicator;
@property (weak) IBOutlet NSTextField *progressLabel;


@end

