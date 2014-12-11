//
//  ImportViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/1/12.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import "ImportViewController.h"

#import "NSManagedObjectContext+FetchAdditions.h"
#import "NSMutableDictionary+Settings.h"
#import "NSError+Reporting.h"

#import "DebugLog.h"


@interface ImportViewController ()

@end


@implementation ImportViewController

@synthesize resultsTextField;
@synthesize importProgressWindow, importProgressIndicator, importProgressTextField;
@synthesize importCount, importTotal, importFileCount, importStartSalesCount, importReportData, importErrors, importStatus, importInProgress;
@synthesize deleteReportWindow;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		_reportParser = [[ReportParser alloc] initWithParserObserver:self];
		_reportImporter = [[ReportImporter alloc] initWithImporterObserver:self];

		_countFormatter = [[NSNumberFormatter alloc] init];
		_countFormatter.numberStyle = NSNumberFormatterDecimalStyle;
	}
    
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	self.importReportData = nil;
	self.importErrors = nil;
	self.importStatus = nil;

	[_reportParser release], _reportParser = nil;
	[_reportImporter release], _reportImporter = nil;
	
	[_countFormatter release], _countFormatter = nil;

	[super dealloc];
}	

- (void)awakeFromNib
{
	[importProgressIndicator setUsesThreadedAnimation:YES];
}

#pragma mark - Utility

- (void)updateImportStatus
{
	if (self.importInProgress) {
		self.importStatus = @"Importing new financial reports…";
	}
	else {
		NSDate *earliestDate = [Sale minimumDateInManagedObjectContext:self.managedObjectContext];
		NSDate *latestDate = [Sale maximumDateInManagedObjectContext:self.managedObjectContext];
		
		if (earliestDate && latestDate) {
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			dateFormatter.dateFormat = @"MMMM yyyy";
			NSString *earliestDateFormatted = [dateFormatter stringFromDate:earliestDate];
			NSString *latestDateFormatted = [dateFormatter stringFromDate:latestDate];
			
			self.importStatus = [NSString stringWithFormat:@"Financial reports from %@ to %@ have been imported", earliestDateFormatted, latestDateFormatted];
		}
		else {
			self.importStatus = @"No financial reports have been imported";
		}
	}
}

#pragma mark - Accessors

- (void)setManagedObjectContext:(NSManagedObjectContext *)newManagedObjectContext
{
	if (newManagedObjectContext != managedObjectContext) {
		[managedObjectContext release];
		managedObjectContext = [newManagedObjectContext retain];

		[self updateImportStatus];
	}
}

- (void)setSettings:(NSMutableDictionary *)newSettings
{
	if (newSettings != settings) {
		[settings release];
		settings = [newSettings retain];

		
		NSData *archivedImportErrors = [settings objectForKey:@"importErrors"];
		if (archivedImportErrors) {
			self.importErrors = [NSUnarchiver unarchiveObjectWithData:archivedImportErrors];
		}
	}
}

- (NSArray *)yearChoices
{
	NSDate *date = [NSDate date];
	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear) fromDate:date];
	
	NSUInteger startYear = 2008;
	if ([self.settings integerForKey:@"accountEarningsStart"] == 0) {
		startYear = 2010;
	}
	
	NSMutableArray *result = [NSMutableArray array];
	for (NSUInteger year = startYear; year <= dateComponents.year; year++) {
		[result addObject:[NSNumber numberWithInteger:year]];
	}
	
	return result;
}

#pragma mark - Methods

#pragma mark - Actions

- (IBAction)deleteReports:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSWindow *window = [[self view] window];
	[window makeFirstResponder:deleteReportWindow];
	[NSApp beginSheet:deleteReportWindow modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (void)deleteDismiss
{
	[NSApp endSheet:deleteReportWindow returnCode:0];
	[deleteReportWindow orderOut:self];
	
	NSWindow *window = [[self view] window];
	[window makeFirstResponder:self.view];
}

- (IBAction)deleteProcess:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[self deleteDismiss];
	
	NSUInteger reconcileReportMonth = [self.settings integerForKey:@"importDeleteReportMonth"];
	NSUInteger reconcileReportYear = [self.settings integerForKey:@"importDeleteReportYear"];
	
	NSDateComponents *targetDateComponents = [[[NSDateComponents alloc] init] autorelease];
	targetDateComponents.year = reconcileReportYear;
	targetDateComponents.month = reconcileReportMonth;
	NSDate *targetStartDate = [[NSCalendar currentCalendar] dateFromComponents:targetDateComponents];
	
	NSDateComponents *targetEndDateComponents = [[[NSDateComponents alloc] init] autorelease];
	targetEndDateComponents.month = 1;
	targetEndDateComponents.second = -1; // the range does not include the exact end date
	NSDate *targetEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:targetEndDateComponents toDate:targetStartDate options:0];
	
	DebugLog(@"%s targetStartDate = %@, targetEndDate = %@", __PRETTY_FUNCTION__, targetStartDate, targetEndDate);
	
	NSUndoManager *undoManager = [managedObjectContext undoManager];
	[undoManager beginUndoGrouping];
	
	NSArray *regions = [Region fetchAllInManagedObjectContext:managedObjectContext];
	for (Region *region in regions) {
		NSArray *salesInRegion = [Sale fetchAllInManagedObjectContext:managedObjectContext forRegion:region startDate:targetStartDate endDate:targetEndDate];
		//DebugLog(@"%s salesInRegion = %@", __PRETTY_FUNCTION__, salesInRegion);
		for (Sale *sale in salesInRegion) {
			[managedObjectContext deleteObject:sale];
		}
	}
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	dateFormatter.dateFormat = @"MMMM yyyy";
	NSString *dateFormatted = [dateFormatter stringFromDate:targetStartDate];

	[managedObjectContext processPendingChanges];
	[undoManager endUndoGrouping];
	[undoManager setActionName:[NSString stringWithFormat:@"Remove Report Data for %@", dateFormatted]];
}

- (IBAction)deleteCancel:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[self deleteDismiss];
}

- (void)presentImportProgressSheet
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSWindow *window = [[self view] window];
	[NSApp beginSheet:importProgressWindow modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	//[NSApp runModalForWindow:window];
}

- (void)updateImportProgressSheetWithKey:(NSString *)key
{
	[importProgressIndicator setMaxValue:importTotal];
	[importProgressIndicator setDoubleValue:importCount];
	
	NSString *importCountFormatted = [_countFormatter stringFromNumber:[NSNumber numberWithInteger:importCount]];
	NSString *importTotalFormatted = [_countFormatter stringFromNumber:[NSNumber numberWithInteger:importTotal]];
									  
	NSString *message = [NSString stringWithFormat:NSLocalizedString(key, nil), importCountFormatted, importTotalFormatted];
	[importProgressTextField setStringValue:message];
	
	// since Core Data hogs the main thread, the run loop won't update the window as needed
	[importProgressWindow display];
}

- (void)dismissImportProgressSheet
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[NSApp endSheet:importProgressWindow];
	[importProgressWindow orderOut:nil];
	
	NSUInteger importEndSalesCount = [Sale countAllInManagedObjectContext:self.managedObjectContext];

	NSString *reportCountFormatted = [_countFormatter stringFromNumber:[NSNumber numberWithInteger:self.importFileCount]];
	NSString *salesCountFormatted = [_countFormatter stringFromNumber:[NSNumber numberWithInteger:(importEndSalesCount - self.importStartSalesCount)]];

	[self willChangeValueForKey:@"importErrors"];
	NSString *errorDescription = [NSString stringWithFormat:@"Processed %@ financial reports and created %@ sales records", reportCountFormatted, salesCountFormatted];
	NSError *completeError = [NSError errorWithCode:0 filePath:nil description:errorDescription];
	[self.importErrors addObject:completeError];
	[self didChangeValueForKey:@"importErrors"];

	NSData *archivedImportErrors = [NSArchiver archivedDataWithRootObject:importErrors];
	[self.settings setObject:archivedImportErrors forKey:@"importErrors"];
	
	self.importInProgress = NO;
	[self updateImportStatus];
}

- (IBAction)parseReports:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSWindow *window = [[self view] window];

	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
	//[openPanel setDirectoryURL:[NSURL URLWithString:[basePath stringByExpandingTildeInPath]]];
	[openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSString *accountNumber = [self.settings objectForKey:@"accountNumber"];

			NSMutableSet *filePaths = [NSMutableSet set];

			NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
			for (NSURL *openURL in [openPanel URLs]) {
				NSString *openPath = [openURL path];
				BOOL isDirectory;
				if ([fileManager fileExistsAtPath:openPath isDirectory:&isDirectory]) {
					if (isDirectory) {
						NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath:openPath];
						NSString *fileName = nil;
						while ((fileName = [directoryEnumerator nextObject])) {
							if ([[fileName pathExtension] isEqualToString:@"txt"]) {
								NSString *filePath = [openPath stringByAppendingPathComponent:fileName];
								if (! [filePaths containsObject:filePath]) {
									//DebugLog(@"%s filePath = %@", __PRETTY_FUNCTION__, filePath);
									[filePaths addObject:filePath];
								}
							}
						}
					}
					else {
						if (! [filePaths containsObject:openPath]) {
							//DebugLog(@"%s openPath = %@", __PRETTY_FUNCTION__, openPath);
							[filePaths addObject:openPath];
						}
					}
				}
			}
			
			for (NSString *filePath in filePaths) {
				[_reportParser parseReportAtPath:filePath checkingAccountNumber:accountNumber withManagedObjectContext:self.managedObjectContext];
			}

			self.importCount = 0;
			self.importTotal = [filePaths count];
			self.importFileCount = [filePaths count];
			self.importStartSalesCount = [Sale countAllInManagedObjectContext:self.managedObjectContext];
			self.importReportData = [NSMutableArray arrayWithCapacity:0];
			self.importErrors = [NSMutableArray arrayWithCapacity:0];
			self.importInProgress = YES;
			[self updateImportStatus];
			[self updateImportProgressSheetWithKey:@"ParseReportProgress"];
			
			[self performSelector:@selector(presentImportProgressSheet) withObject:nil afterDelay:0.0];
		}
	}];
}

- (IBAction)clearResults:(id)sender
{
	self.importErrors = nil;
	[self.settings removeObjectForKey:@"importErrors"];
}

#pragma mark - Utility

#pragma mark - Operation callbacks

- (void)reportParsedAtPath:(NSString *)path succeededWithResults:(NSArray *)results
{
	//DebugLog(@"%s path = %@, results = %@", __PRETTY_FUNCTION__, path, results);

	[importReportData addObjectsFromArray:results];

	self.importCount = importCount + 1;
	//DebugLog(@"%s importCount = %lu of %lu for %@", __PRETTY_FUNCTION__, importCount, importTotal, [path lastPathComponent]);
	[self updateImportProgressSheetWithKey:@"ParseReportProgress"];

	if (importCount == importTotal) {
		self.importCount = 0;
		self.importTotal = [importReportData count];
		[_reportImporter importReports:importReportData intoManagedObjectContext:self.managedObjectContext];
		self.importReportData = nil;
	}
}

- (void)reportParsedAtPath:(NSString *)path failedWithError:(NSError *)error
{
	//DebugLog(@"%s path = %@, error = %@", __PRETTY_FUNCTION__, path, error);
	
	[self willChangeValueForKey:@"importErrors"];
	[self.importErrors addObject:error];
	[self didChangeValueForKey:@"importErrors"];

	self.importCount = importCount + 1;
	//DebugLog(@"%s importCount = %lu of %lu for %@", __PRETTY_FUNCTION__, importCount, importTotal, [path lastPathComponent]);
	[self updateImportProgressSheetWithKey:@"ParseReportProgress"];
	
	if (importCount == importTotal) {
		self.importCount = 0;
		self.importTotal = [importReportData count];
		[_reportImporter importReports:importReportData intoManagedObjectContext:self.managedObjectContext];
		self.importReportData = nil;
	}
}

- (void)reportsImportProcessedItem:(NSUInteger)importProgress
{
	self.importCount = importProgress;
	//DebugLog(@"%s importCount = %lu of %lu", __PRETTY_FUNCTION__, importCount, importTotal);
	[self updateImportProgressSheetWithKey:@"ImportReportProgress"];
}

- (void)reportsImportSucceeded
{
	//DebugLog(@"%s path = %@", __PRETTY_FUNCTION__, path);

	[self dismissImportProgressSheet];
}

- (void)reportsImportFailedWithError:(NSError *)error
{
	//DebugLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
	
	[self willChangeValueForKey:@"importErrors"];
	[self.importErrors addObject:error];
	[self didChangeValueForKey:@"importErrors"];

	[self dismissImportProgressSheet];
}

- (void)reportsImportNotedWithError:(NSError *)error
{
	//DebugLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
	
	[self willChangeValueForKey:@"importErrors"];
	[self.importErrors addObject:error];
	[self didChangeValueForKey:@"importErrors"];
}

@end
