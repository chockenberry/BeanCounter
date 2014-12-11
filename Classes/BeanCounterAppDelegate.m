//
//  BeanCounterAppDelegate.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/8/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "BeanCounterAppDelegate.h"

#import "DebugLog.h"

#ifndef MAC_APP_STORE
#import "Sparkle/SUUpdater.h"
#endif


@implementation BeanCounterAppDelegate

@synthesize purchaseWindowController;
@synthesize checkForUpdatesMenuItem, purchaseMenuItem;

#ifndef MAC_APP_STORE
static SUUpdater *sparkleUpdater = nil;
#endif

- (void)awakeFromNib
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

#ifdef MAC_APP_STORE
	[[checkForUpdatesMenuItem menu] removeItem:checkForUpdatesMenuItem];
	[[purchaseMenuItem menu] removeItem:purchaseMenuItem];
#else
	if (!sparkleUpdater) {
		sparkleUpdater = [[SUUpdater alloc] init];
	}
#endif

	// ensure that dates used by the application are all based in the same timezone
	[NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
//	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

- (void)applicationDidResignActive:(NSNotification *)notification;
{
//	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

#if 1
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)application
{
	NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
	NSArray *recentDocumentURLs = [documentController recentDocumentURLs];
	if ([recentDocumentURLs count] > 0) {
		NSURL *lastDocumentURL = [recentDocumentURLs objectAtIndex:0];
		if ([[NSFileManager defaultManager] fileExistsAtPath:[lastDocumentURL path]]) {
			NSError *error;
			[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:lastDocumentURL display:YES error:&error];
			return NO;
		}
	}
	
	return YES;
}
#endif

#pragma mark - Actions

#ifndef MAC_APP_STORE

- (IBAction)checkForUpdates:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[[SUUpdater sharedUpdater] checkForUpdates:sender];
}

- (IBAction)purchaseApplication:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	if (! purchaseWindowController) {
		self.purchaseWindowController = [[[PurchaseWindowController alloc] initWithWindowNibName:@"PurchaseWindow"] autorelease];
	}
	[purchaseWindowController showWindow:self];
}

#endif

@end
