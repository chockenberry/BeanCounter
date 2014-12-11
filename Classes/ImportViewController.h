//
//  ImportViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/1/12.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OutputViewController.h"

#import "ReportParser.h"
#import "ReportImporter.h"


@interface ImportViewController : OutputViewController <NSTableViewDelegate, NSTableViewDataSource, ReportParserObserver, ReportImporterObserver>
{
	ReportParser *_reportParser;
	ReportImporter *_reportImporter;
	NSNumberFormatter *_countFormatter;

	NSTextField *resultsTextField;

	NSWindow *importProgressWindow;
	NSProgressIndicator *importProgressIndicator;
	NSTextField *importProgressTextField;
	
	NSUInteger importCount;
	NSUInteger importTotal;
	NSUInteger importStartSalesCount;
	NSMutableArray *importReportData;
	NSMutableArray *importErrors;
	NSString *importStatus;
	BOOL importInProgress;

	NSWindow *deleteReportWindow;	
}

@property (nonatomic, retain) IBOutlet NSTextField *resultsTextField;

@property (nonatomic, retain) IBOutlet NSWindow *importProgressWindow;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *importProgressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField *importProgressTextField;

@property (nonatomic, assign) NSUInteger importCount;
@property (nonatomic, assign) NSUInteger importTotal;
@property (nonatomic, assign) NSUInteger importFileCount;
@property (nonatomic, assign) NSUInteger importStartSalesCount;
@property (nonatomic, retain) NSMutableArray *importReportData;
@property (nonatomic, retain) NSMutableArray *importErrors;
@property (nonatomic, retain) NSString *importStatus;
@property (nonatomic, assign) BOOL importInProgress;

@property (nonatomic, retain) IBOutlet NSWindow *deleteReportWindow;

@property (nonatomic, readonly) NSArray *yearChoices;

- (IBAction)parseReports:(id)sender;
- (IBAction)clearResults:(id)sender;

- (IBAction)deleteReports:(id)sender;
- (IBAction)deleteProcess:(id)sender;
- (IBAction)deleteCancel:(id)sender;

@end
