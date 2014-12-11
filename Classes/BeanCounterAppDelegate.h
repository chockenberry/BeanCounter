//
//  BeanCounterAppDelegate.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/8/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PurchaseWindowController.h"

@interface BeanCounterAppDelegate : NSObject
{
	PurchaseWindowController *purchaseWindowController;

	NSMenuItem *checkForUpdatesMenuItem;
	NSMenuItem *purchaseMenuItem;
}

@property (retain) PurchaseWindowController *purchaseWindowController;

@property (assign) IBOutlet NSMenuItem *checkForUpdatesMenuItem;
@property (assign) IBOutlet NSMenuItem *purchaseMenuItem;

#ifndef MAC_APP_STORE
- (IBAction)checkForUpdates:(id)sender;
- (IBAction)purchaseApplication:(id)sender;
#endif

@end
