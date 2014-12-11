//
//  ReconcileViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 12/20/11.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OutputViewController.h"

#import "DepositParser.h"
#import "DepositImporter.h"


@interface ReconcileViewController : OutputViewController <NSTableViewDelegate, NSTableViewDataSource, DepositParserObserver, DepositImporterObserver>
{
	DepositParser *_depositParser;
	DepositImporter *_depositImporter;

	NSNumberFormatter *_countFormatter;
	NSNumberFormatter *_inputFormatter;
	NSDateFormatter *_dateFormatter;

	NSMutableArray *reconcileData;
	NSDecimalNumber *reconcileTotal;
	
	NSTableView *tableView;
	NSTextView *totalTextField;

	NSWindow *importProgressWindow;
	NSProgressIndicator *importProgressIndicator;
	NSTextField *importProgressTextField;
	
	NSUInteger importCount;
	NSUInteger importTotal;

	NSString *reconcileStatus;
	
	BOOL modified;
}

@property (nonatomic, retain) NSMutableArray *reconcileData;
@property (nonatomic, retain) NSDecimalNumber *reconcileTotal;

@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, retain) IBOutlet NSTextView *totalTextField;

@property (nonatomic, retain) IBOutlet NSWindow *importProgressWindow;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *importProgressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField *importProgressTextField;

@property (nonatomic, retain) IBOutlet NSPopUpButton *monthPopUpButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton *yearPopUpButton;

@property (nonatomic, assign) NSUInteger importCount;
@property (nonatomic, assign) NSUInteger importTotal;

@property (nonatomic, retain) NSString *reconcileStatus;

@property (nonatomic, readonly, getter = isModified) BOOL modified;

@property (nonatomic, readonly) NSArray *yearChoices;

- (IBAction)resetInput:(id)sender;
- (IBAction)reconcileInput:(id)sender;

- (IBAction)importDeposits:(id)sender;
- (IBAction)importDeposits:(id)sender;

- (IBAction)changeMonth:(id)sender;
- (IBAction)firstMonth:(id)sender;
- (IBAction)previousMonth:(id)sender;
- (IBAction)nextMonth:(id)sender;
- (IBAction)lastMonth:(id)sender;

@end
