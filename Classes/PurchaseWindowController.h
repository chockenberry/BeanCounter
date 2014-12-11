//
//  PurchaseWindowController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/18/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *PurchaseChangedNotification;

@interface PurchaseWindowController : NSWindowController
{
	NSTabView *registrationTabView;
	NSTextField *registrationName;
	NSTextField *registrationNumber;
}

@property (nonatomic, retain) IBOutlet NSTabView *registrationTabView;
@property (nonatomic, retain) IBOutlet NSTextField *registrationName;
@property (nonatomic, retain) IBOutlet NSTextField *registrationNumber;

- (NSString *)registrationStatus;

// registration actions

- (IBAction)purchaseLicense:(id)sender;
- (IBAction)openAppStore:(id)sender;

@end


