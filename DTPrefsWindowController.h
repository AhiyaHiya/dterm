//  DTPrefsWindowController.h
//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

@class DTPrefsAXController;
@class MASShortcutView;

@interface DTPrefsWindowController : NSWindowController 

@property DTPrefsAXController* axPrefsController;

- (IBAction)showPrefs:(id)sender;

- (IBAction)showGeneral:(id)sender;
- (IBAction)showAccessibility:(id)sender;
- (IBAction)showUpdates:(id)sender;

- (IBAction)showFontPanel:(id)sender;
- (IBAction)resetColorAndFont:(id)sender;

- (IBAction)checkForUpdatesNow:(id)sender;

@end
