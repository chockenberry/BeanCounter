//
//  PurchaseWindowController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/18/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "PurchaseWindowController.h"

#import "RegistrationManager.h"
//#import "BeanCounterAppDelegate.h"

#import "DebugLog.h"

@implementation PurchaseWindowController

@synthesize registrationTabView;
@synthesize registrationName;
@synthesize registrationNumber;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

    self = [super initWithWindowNibName:windowNibName];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	self.registrationTabView = nil;
	self.registrationName = nil;
	self.registrationNumber = nil;

	[super dealloc];
}

- (void)awakeFromNib
{
	if ([[RegistrationManager sharedRegistrationManager] registrationState] != RegistrationEmpty) {
		[registrationTabView selectLastTabViewItem:self];
	}
	else {
		[registrationTabView selectFirstTabViewItem:self];
	}
}

#pragma mark Overrides

- (void)windowDidLoad
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	// center window the first time it's loaded
	if (! [self.window setFrameUsingName:@"__purchase"]) {
		[self.window center];
	}
	[self.window setFrameAutosaveName:@"__purchase"];
}

#pragma mark NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	// grab any pending editing changes in the text fields
	[self.window makeFirstResponder:self.window];

	return YES;
}

#pragma mark Actions


#pragma mark General Actions

- (NSString *)registrationStatus
{
	//[[NSApp delegate] updateReminder];

	switch ([[RegistrationManager sharedRegistrationManager] registrationState]) {
		default:
		case RegistrationEmpty:
			return NSLocalizedString(@"RegistrationEmpty", nil);
			break;
		case RegistrationInvalid:
			return NSLocalizedString(@"RegistrationInvalid", nil);
			break;
		case RegistrationValid:
			{
				int licenseCount = [[RegistrationManager sharedRegistrationManager] licenseCount];
				if (licenseCount > 1) {
					return [NSString stringWithFormat:NSLocalizedString(@"RegistrationValidMultiple",nil), licenseCount];
				}
				else {
					return NSLocalizedString(@"RegistrationValid", nil);
				}
			}
			break;
	}
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	//DebugLog(@"%s called", __PRETTY_FUNCTION__);

	id object = [notification object];
	if ([object isEqual:registrationName] || [object isEqual:registrationNumber])
	{
		[self willChangeValueForKey:@"registrationStatus"];
		
		[[RegistrationManager sharedRegistrationManager] updateRegistration];

		[self didChangeValueForKey:@"registrationStatus"];
	}
}

#pragma mark Registration Actions

// TODO: update URL to point to BeanCounter website
- (IBAction)purchaseLicense:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://flareapp.com"]];
}

// TODO: update URL to point to BeanCounter product in iTunes
- (IBAction)openAppStore:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/flare/id419917767?mt=12"]];
}

@end
