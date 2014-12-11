//
//  AccountDocument.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/16/11.
//  Copyright The Iconfactory 2011 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SourceListViewController.h"
#import "OutputViewController.h"
#import "ProductsWindowController.h"

@interface AccountDocument : NSPersistentDocument
{
	NSDictionary *_outputViewConfiguration;

	SourceListViewController *_sourceListViewController;
	OutputViewController *_outputViewController;
	
	NSView *sourceListView;
	NSView *outputView;
	
	NSMutableDictionary *settings;
	
	NSWindow *importProgressWindow;
	NSProgressIndicator *importProgressIndicator;
	NSTextField *importProgressTextField;
	
	NSUInteger importCount;
	NSUInteger importTotal;
}

@property (nonatomic, retain) IBOutlet NSView *sourceListView;
@property (nonatomic, retain) IBOutlet NSView *outputView;

@property (nonatomic, retain) NSMutableDictionary *settings;

- (IBAction)printDocument:(id)sender;

@end

