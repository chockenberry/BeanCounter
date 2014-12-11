//
//  ReconcileViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 12/20/11.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import "ReconcileViewController.h"

#import "InternationalInfo.h"
#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"
#import "DepositData.h"
#import "NSMutableDictionary+Settings.h"
#import "NSError+Reporting.h"

#import "DebugLog.h"


@interface ReconcileViewController ()

@property (nonatomic, assign, getter = isModified) BOOL modified;

@end


@implementation ReconcileViewController

@synthesize reconcileData, reconcileTotal;
@synthesize tableView, totalTextField;
@synthesize importProgressWindow, importProgressIndicator, importProgressTextField;
@synthesize monthPopUpButton, yearPopUpButton;
@synthesize importCount, importTotal;
@synthesize reconcileStatus;
@synthesize modified;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		_depositParser = [[DepositParser alloc] initWithParserObserver:self];
		_depositImporter = [[DepositImporter alloc] initWithImporterObserver:self];

		_countFormatter = [[NSNumberFormatter alloc] init];
		_countFormatter.numberStyle = NSNumberFormatterDecimalStyle;

		_inputFormatter = [[NSNumberFormatter alloc] init];
		_inputFormatter.format = @"¤#,##0.00;-¤#,##0.00";
		_inputFormatter.lenient = YES;
		_inputFormatter.generatesDecimalNumbers = YES;
		
		_dateFormatter = [[NSDateFormatter alloc] init];
		_dateFormatter.dateFormat = @"MMMM yyyy";
	}
    
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[_depositParser release], _depositParser = nil;
	[_depositImporter release], _depositImporter = nil;
	
	[_countFormatter release], _countFormatter = nil;
	[_inputFormatter release], _inputFormatter = nil;
	[_dateFormatter release], _dateFormatter = nil;

	[super dealloc];
}	

#pragma mark - Utility

- (void)updateReconcileStatus
{
	NSDate *latestDate = [Earning maximumToDateInManagedObjectContext:self.managedObjectContext];
	
	if (latestDate) {
		NSString *latestDateFormatted = [_dateFormatter stringFromDate:latestDate];
		self.reconcileStatus = [NSString stringWithFormat:@"Deposits from %@ have been reconciled", latestDateFormatted];
	}
	else {
		self.reconcileStatus = @"No deposits have been reconciled";
	}
}

- (BOOL)balanceSetManually
{
	BOOL result = NO;
	
	if ([self.settings integerForKey:@"accountEarningsStart"] == 0) {
		// account is configured to start on July 2010, check if that's the current month and year for reconciliation
		NSUInteger reconcileReportMonth = [self.settings integerForKey:@"reconcileReportMonth"];
		NSUInteger reconcileReportYear = [self.settings integerForKey:@"reconcileReportYear"];
		if (reconcileReportMonth == 7 && reconcileReportYear == 2010) {
			result = YES;
		}
	}
	
	return result;
}

#pragma mark - Accessors

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

- (void)saveSettings
{
	if (modified) {
		NSData *archivedReconcileData = [NSKeyedArchiver archivedDataWithRootObject:reconcileData];
		[self.settings setObject:archivedReconcileData forKey:@"reconcileData"];
	}
	else {
		[self.settings removeObjectForKey:@"reconcileData"];
	}
}

- (void)loadReconcileData
{
	NSUInteger reconcileReportMonth = [self.settings integerForKey:@"reconcileReportMonth"];
	NSUInteger reconcileReportYear = [self.settings integerForKey:@"reconcileReportYear"];

	NSDateComponents *targetDateComponents = [[[NSDateComponents alloc] init] autorelease];
	targetDateComponents.year = reconcileReportYear;
	targetDateComponents.month = reconcileReportMonth;
	NSDate *targetDate = [[NSCalendar currentCalendar] dateFromComponents:targetDateComponents];

	DebugLog(@"%s targetDate = %@, defaultTimeZone = %@", __PRETTY_FUNCTION__, targetDate, [NSTimeZone defaultTimeZone]);

	NSDateComponents *salesEndDateComponents = [[[NSDateComponents alloc] init] autorelease];
	salesEndDateComponents.month = 1;
	NSDate *salesEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:salesEndDateComponents toDate:targetDate options:0];
	
	NSDateComponents *earningsStartDateComponents = [[[NSDateComponents alloc] init] autorelease];
	earningsStartDateComponents.month = 7;
	if ([self.settings integerForKey:@"accountEarningsStart"] == 0) {
		// July 2010 is the first date to reconcile
		earningsStartDateComponents.year = 2010;
	}
	else {
		// July 2008 is the first date to reconcile
		earningsStartDateComponents.year = 2008;
	}
	NSDate *earningsStartDate = [[NSCalendar currentCalendar] dateFromComponents:earningsStartDateComponents];
	
	NSArray *allRegions = [Region fetchAllInManagedObjectContextByCurrency:managedObjectContext];
	
	self.reconcileData = [NSMutableArray array];
	if ([targetDate timeIntervalSinceDate:earningsStartDate] >= 0) {
		for (Region *region in allRegions) {
			NSArray *sales = [Sale fetchAllInManagedObjectContext:managedObjectContext forRegion:region startDate:targetDate endDate:salesEndDate];
			NSDecimalNumber *salesTotal = [sales valueForKeyPath:@"@sum.total"];
			
			NSDateComponents *balanceEndDateComponents = [[[NSDateComponents alloc] init] autorelease];
			balanceEndDateComponents.month = -1;
			NSDate *balanceEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:balanceEndDateComponents toDate:targetDate options:0];
			
			BOOL showRegion = NO;
			NSDecimalNumber *balanceTotal = [NSDecimalNumber zero];
			if ([self balanceSetManually]) {
				Earning *earning = [Earning fetchInManagedObjectContext:self.managedObjectContext forRegion:region onDate:targetDate];
				if (earning.balance) {
					balanceTotal = earning.balance;
				}
				
				NSUInteger previousSalesCount = [Sale countAllInManagedObjectContext:managedObjectContext forRegion:region startDate:[NSDate distantPast] endDate:salesEndDate];
				if (previousSalesCount > 0) {
					showRegion = YES;
				}
				
				DebugLog(@"%s loaded balance of %@ (%@)", __PRETTY_FUNCTION__, balanceTotal, [_dateFormatter stringFromDate:targetDate]);
			}
			else {
				NSDate *balanceStartDate = earningsStartDate;
				
				NSArray *earnings = [Earning fetchAllInManagedObjectContext:managedObjectContext forRegion:region fromDate:balanceStartDate toDate:balanceEndDate];
				if (earnings && [earnings count] > 0) {
					NSDate *maxToDate = [earnings valueForKeyPath:@"@max.toDate"];
					
					NSDateComponents *balanceStartDateComponents = [[[NSDateComponents alloc] init] autorelease];
					balanceStartDateComponents.month = 1;
					balanceStartDate = [[NSCalendar currentCalendar] dateByAddingComponents:balanceStartDateComponents toDate:maxToDate options:0];
				}
				
				NSArray *balanceSales = [Sale fetchAllInManagedObjectContext:managedObjectContext forRegion:region startDate:balanceStartDate endDate:targetDate];
				if ([balanceSales count] > 0) {
					balanceTotal = [balanceSales valueForKeyPath:@"@sum.total"];
				}
				
				if (([balanceTotal compare:[NSDecimalNumber zero]] != NSOrderedSame) || ([salesTotal compare:[NSDecimalNumber zero]] != NSOrderedSame)) {
					showRegion = YES;
				}
				
				DebugLog(@"%s computed balance of %@ (%@ to %@)", __PRETTY_FUNCTION__, balanceTotal, [_dateFormatter stringFromDate:balanceStartDate], [_dateFormatter stringFromDate:targetDate]);
			}
			
			if (showRegion)
			{
				DepositData *regionDepositData = [[[DepositData alloc] init] autorelease];
				regionDepositData.regionId = region.id;
				regionDepositData.balance = balanceTotal;
				regionDepositData.sales = salesTotal;
				
				NSDecimalNumber *deposit = [NSDecimalNumber zero];
				NSDecimalNumber *rate = [NSDecimalNumber zero];
				NSDecimalNumber *adjustments = [NSDecimalNumber zero];
				Earning *earning = [Earning fetchInManagedObjectContext:managedObjectContext forRegion:region toDate:targetDate];
				if (earning) {
					deposit = earning.deposit;
					rate = earning.rate;
					adjustments = earning.adjustments;
				}
				regionDepositData.deposit = deposit;
				regionDepositData.rate = rate;
				regionDepositData.adjustments = adjustments;
				
				DebugLog(@"%s --> loaded deposit of %@ (%@) at %@ in %@", __PRETTY_FUNCTION__, deposit, adjustments, rate, region.id);
				
				[reconcileData addObject:regionDepositData];
			}
		}
	}
}

- (void)updateReconcileTotal
{
	NSDecimalNumber *total = [NSDecimalNumber zero];
	for (DepositData *regionDepositData in reconcileData) {
		total = [total decimalNumberByAdding:regionDepositData.deposit];
	}

	self.reconcileTotal = total;
}

- (void)updateDateSelectorToMonth:(NSUInteger)month year:(NSUInteger)year
{
	[monthPopUpButton selectItemWithTag:month];
	[yearPopUpButton selectItemWithTitle:[[NSNumber numberWithInteger:year] stringValue]];

	[self.settings setInteger:month forKey:@"reconcileReportMonth"];
	[self.settings setInteger:year forKey:@"reconcileReportYear"];
}

// TODO: the logic for -updateDateSelectorToMonth:year: is convoluted, see if it can be streamlined

- (void)generateOutput
{
	NSData *archivedReconcileData = [self.settings objectForKey:@"reconcileData"];
	if (archivedReconcileData) {
		self.reconcileData = [NSKeyedUnarchiver unarchiveObjectWithData:archivedReconcileData];
		[self.settings removeObjectForKey:@"reconcileData"];
		[self willChangeValueForKey:@"isModified"];
		self.modified = YES;
		[self didChangeValueForKey:@"isModified"];
	}
	else {
		[self loadReconcileData];
	}

	NSUInteger reconcileReportMonth = [self.settings integerForKey:@"reconcileReportMonth"];
	NSUInteger reconcileReportYear = [self.settings integerForKey:@"reconcileReportYear"];
	[self updateDateSelectorToMonth:reconcileReportMonth year:reconcileReportYear];

	[self updateReconcileTotal];
	[self updateReconcileStatus];
	
	[tableView reloadData];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	DebugLog(@"%s returnCode = %ld", __PRETTY_FUNCTION__, (long)returnCode);

	NSDictionary *contextInfoDictionary = [(NSDictionary *)contextInfo autorelease];
	NSUInteger newMonth = [[contextInfoDictionary objectForKey:@"month"] integerValue];
	NSUInteger newYear = [[contextInfoDictionary objectForKey:@"year"] integerValue];
	
	NSUInteger oldMonth = [self.settings integerForKey:@"reconcileReportMonth"];
	NSUInteger oldYear = [self.settings integerForKey:@"reconcileReportYear"];
	
	switch (returnCode) {
		case NSAlertDefaultReturn:
			// reconcile
			[self reconcileInput:self];
			[self willChangeValueForKey:@"isModified"];
			self.modified = NO;
			[self didChangeValueForKey:@"isModified"];
			DebugLog(@"%s cleared modified", __PRETTY_FUNCTION__);

			[self updateDateSelectorToMonth:newMonth year:newYear];
			[self generateOutput];
			break;
		default:
		case NSAlertAlternateReturn:
			// don't reconcile
			[self willChangeValueForKey:@"isModified"];
			self.modified = NO;
			[self didChangeValueForKey:@"isModified"];
			DebugLog(@"%s cleared modified", __PRETTY_FUNCTION__);

			[self updateDateSelectorToMonth:newMonth year:newYear];
			[self generateOutput];
			break;
		case NSAlertOtherReturn:
			// cancel
			[self updateDateSelectorToMonth:oldMonth year:oldYear];
			break;
	}
}

- (void)confirmChangeToMonth:(NSInteger)newMonth year:(NSInteger)newYear
{
	if (self.isModified) {
		NSDictionary *contextInfo = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:newMonth], @"month", [NSNumber numberWithInteger:newYear], @"year", nil] retain];
		NSAlert *alert = [NSAlert alertWithMessageText:@"Do you want to reconcile the data for this month?" defaultButton:@"Reconcile" alternateButton:@"Don't Reconcile" otherButton:@"Cancel" informativeTextWithFormat:@"Your changes will be lost if you don't reconcile them."];
		[alert beginSheetModalForWindow:[self.view window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:contextInfo];
	}
	else {
		[self updateDateSelectorToMonth:newMonth year:newYear];
		[self generateOutput];
	}
}

#pragma mark - Actions

- (IBAction)resetInput:(id)sender
{
	[self willChangeValueForKey:@"isModified"];
	self.modified = NO;
	[self didChangeValueForKey:@"isModified"];
	DebugLog(@"%s cleared modified", __PRETTY_FUNCTION__);

	[self generateOutput];
}

- (IBAction)reconcileInput:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSDateComponents *earningsStartDateComponents = [[[NSDateComponents alloc] init] autorelease];
	earningsStartDateComponents.month = 7;
	if ([self.settings integerForKey:@"accountEarningsStart"] == 0) {
		// July 2010 is the first date to reconcile
		earningsStartDateComponents.year = 2010;
	}
	else {
		// July 2008 is the first date to reconcile
		earningsStartDateComponents.year = 2008;
	}
	NSDate *earningsStartDate = [[NSCalendar currentCalendar] dateFromComponents:earningsStartDateComponents];

	NSUInteger reconcileReportMonth = [self.settings integerForKey:@"reconcileReportMonth"];
	NSUInteger reconcileReportYear = [self.settings integerForKey:@"reconcileReportYear"];

	NSDateComponents *targetDateComponents = [[[NSDateComponents alloc] init] autorelease];
	targetDateComponents.year = reconcileReportYear;
	targetDateComponents.month = reconcileReportMonth;
	NSDate *targetDate = [[NSCalendar currentCalendar] dateFromComponents:targetDateComponents];

	if ([targetDate timeIntervalSinceDate:earningsStartDate] < 0) {
		NSString *earningsStartDateFormatted = [_dateFormatter stringFromDate:earningsStartDate];

		NSAlert *alert = nil;
		if ([self.settings integerForKey:@"accountEarningsStart"] == 0) {
			// July 2010 is the first date to reconcile
			alert = [NSAlert alertWithMessageText:@"Cannot Reconcile this Month" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"This account is not configured to reconcile deposits before %@.\n\nUse Account Settings to adjust the starting date where your earnings are computed.", earningsStartDateFormatted];
		}
		else {
			// July 2008 is the first date to reconcile
			alert = [NSAlert alertWithMessageText:@"Cannot Reconcile this Month" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The first deposits for the App Store were in %@.\n\nIt's time to double-check your records :-)", earningsStartDateFormatted];
		}
		[alert runModal];
		return;
	}
	
	NSUndoManager *undoManager = [self.managedObjectContext undoManager];
	[undoManager beginUndoGrouping];
	
	for (DepositData *regionDepositData in reconcileData) {
		Region *region = [Region fetchInManagedObjectContext:self.managedObjectContext withId:regionDepositData.regionId];

		NSDecimalNumber *deposit = regionDepositData.deposit;
		if ([deposit compare:[NSDecimalNumber zero]] != NSOrderedSame) {
			// deposit is not zero, create a new earning or edit an existing one
			
			NSDateComponents *balanceEndDateComponents = [[[NSDateComponents alloc] init] autorelease];
			balanceEndDateComponents.month = -1;
			NSDate *balanceEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:balanceEndDateComponents toDate:targetDate options:0];

			NSDate *balanceStartDate = earningsStartDate;

			NSArray *earnings = [Earning fetchAllInManagedObjectContext:self.managedObjectContext forRegion:region fromDate:[NSDate distantPast] toDate:balanceEndDate];
			if (earnings && [earnings count] > 0) {
				NSDate *maxToDate = [earnings valueForKeyPath:@"@max.toDate"];
				
				NSDateComponents *balanceStartDateComponents = [[[NSDateComponents alloc] init] autorelease];
				balanceStartDateComponents.month = 1;
				balanceStartDate = [[NSCalendar currentCalendar] dateByAddingComponents:balanceStartDateComponents toDate:maxToDate options:0];
			}
			
			NSDecimalNumber *adjustments = regionDepositData.adjustments;
			NSDecimalNumber *balance = regionDepositData.balance;
			NSDecimalNumber *rate = [NSDecimalNumber zero];
			NSDecimalNumber *subtotal = regionDepositData.subtotal;
			if ([subtotal compare:[NSDecimalNumber zero]] != NSOrderedSame) {
				rate = [deposit decimalNumberByDividingBy:subtotal];
			}
			
			Earning *earning = [Earning fetchInManagedObjectContext:self.managedObjectContext forRegion:region onDate:targetDate];
			if (! earning) {
				// create new earning
				earning = [NSEntityDescription insertNewObjectForEntityForName:@"Earning" inManagedObjectContext:self.managedObjectContext];
			}
			
			earning.Region = region;
			earning.fromDate = balanceStartDate;
			earning.toDate = targetDate;
			if ([self balanceSetManually]) {
				earning.balance = balance;
			}
			earning.adjustments = adjustments;
			earning.deposit = deposit;
			earning.rate = rate;

			DebugLog(@"%s reconciled earning of %@ at %@ in %@ (%@ to %@)", __PRETTY_FUNCTION__, deposit, rate, region.id, [_dateFormatter stringFromDate:balanceStartDate], [_dateFormatter stringFromDate:targetDate]);
		}
		else {
			// deposit is zero, remove any existing earnings
			Earning *earning = [Earning fetchInManagedObjectContext:self.managedObjectContext forRegion:region onDate:targetDate];
			if (earning) {
				[self.managedObjectContext deleteObject:earning];
				DebugLog(@"%s removed earning in %@", __PRETTY_FUNCTION__, region.id);
			}
		}
	}
	
	[self.managedObjectContext processPendingChanges];
	
	[undoManager endUndoGrouping];
	NSString *dateFormatted = [_dateFormatter stringFromDate:targetDate];
	[undoManager setActionName:[NSString stringWithFormat:@"Reconcile for %@", dateFormatted]];

	[self willChangeValueForKey:@"isModified"];
	self.modified = NO;
	[self didChangeValueForKey:@"isModified"];
	DebugLog(@"%s cleared modified", __PRETTY_FUNCTION__);
}


- (IBAction)exportDeposits:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSWindow *window = [[self view] window];

	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setNameFieldStringValue:@"Deposits.txt"];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setExtensionHidden:NO];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
	[savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			
			NSURL *exportURL = [savePanel URL];
			
			NSMutableString *outputString = [NSMutableString string];
			[outputString appendString:@"Year\tMonth\tRegion\tBalance\tDeposit\tAdjustments\n"];
			
			NSArray *earnings = [Earning fetchAllSortedInManagedObjectContext:self.managedObjectContext];
			for (Earning *earning in earnings) {
				NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
				NSDateComponents *dateComponents = [gregorianCalendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:earning.toDate];
				NSInteger year = [dateComponents year];
				NSInteger month = [dateComponents month];
				
				NSDecimalNumber *balance = [NSDecimalNumber zero];
				if (earning.balance) {
					balance = earning.balance;
				}

				[outputString appendFormat:@"%ld\t%ld\t%@\t%@\t%@\t%@\n", (long)year, (long)month, earning.Region.id, balance, earning.deposit, earning.adjustments];
			}
			
			[outputString writeToURL:exportURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		}
	}];
}

- (void)presentImportProgressSheet
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSWindow *window = [[self view] window];
	[NSApp beginSheet:importProgressWindow modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	//[NSApp runModalForWindow:window];
}

- (void)updateImportProgressSheet
{
	if (importCount == 0 && importTotal == 0) {
		[importProgressIndicator setIndeterminate:YES];
		[importProgressIndicator startAnimation:self];
	}
	else {
		[importProgressIndicator setIndeterminate:NO];
		[importProgressIndicator setMaxValue:importTotal];
		[importProgressIndicator setDoubleValue:importCount];
	}

	NSString *importCountFormatted = [_countFormatter stringFromNumber:[NSNumber numberWithInteger:importCount]];
	NSString *importTotalFormatted = [_countFormatter stringFromNumber:[NSNumber numberWithInteger:importTotal]];
	
	NSString *message = [NSString stringWithFormat:NSLocalizedString(@"ImportDepositProgress", nil), importCountFormatted, importTotalFormatted];
	[importProgressTextField setStringValue:message];
	
	// since Core Data hogs the main thread, the run loop won't update the window as needed
	[importProgressWindow display];
}

- (void)dismissImportProgressSheet
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	//[NSApp stopModalWithCode:0];
	[NSApp endSheet:importProgressWindow];
	[importProgressWindow orderOut:nil];
}

- (IBAction)importDeposits:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSWindow *window = [[self view] window];
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
	[openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {			
			NSUInteger importFileCount = 0;
			
			NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
			for (NSURL *openURL in [openPanel URLs]) {
				NSString *openPath = [openURL path];
				BOOL isDirectory;
				if ([fileManager fileExistsAtPath:openPath isDirectory:&isDirectory]) {
					//DebugLog(@"%s openPath = %@", __PRETTY_FUNCTION__, openPath);
					NSString *fileName = [openPath lastPathComponent];
					NSRange range = [fileName rangeOfString:@"PYMT"];
					if (range.location == NSNotFound) {
						[_depositParser parseDepositsAtPath:openPath];
						importFileCount += 1;
					}
				}
			}
			
			self.importCount = 0;
			self.importTotal = 0;
			[self updateImportProgressSheet];
			
			[self performSelector:@selector(presentImportProgressSheet) withObject:nil afterDelay:0.0];
		}
	}];
}

#pragma mark -

- (IBAction)changeMonth:(id)sender
{
	NSInteger monthSelection = [[monthPopUpButton selectedItem] tag];
	NSInteger yearSelection = [[[yearPopUpButton selectedItem] title] integerValue];

#if DEBUG
	NSDateComponents *targetDateComponents = [[[NSDateComponents alloc] init] autorelease];
	targetDateComponents.month = monthSelection;
	targetDateComponents.year = yearSelection;
	NSDate *targetDate = [[NSCalendar currentCalendar] dateFromComponents:targetDateComponents];
	
	DebugLog(@"%s targetDate = %@", __PRETTY_FUNCTION__, targetDate);
#endif
	
	[self confirmChangeToMonth:monthSelection year:yearSelection];
}

- (NSDateComponents *)adjustReconcileMonthBy:(NSInteger)delta
{
	NSUInteger reconcileReportMonth = [self.settings integerForKey:@"reconcileReportMonth"];
	NSUInteger reconcileReportYear = [self.settings integerForKey:@"reconcileReportYear"];
	
	NSDateComponents *targetDateComponents = [[[NSDateComponents alloc] init] autorelease];
	targetDateComponents.year = reconcileReportYear;
	targetDateComponents.month = reconcileReportMonth;
	NSDate *targetDate = [[NSCalendar currentCalendar] dateFromComponents:targetDateComponents];
	
	NSDateComponents *newDateComponents = [[[NSDateComponents alloc] init] autorelease];
	newDateComponents.month = delta;
	NSDate *newDate = [[NSCalendar currentCalendar] dateByAddingComponents:newDateComponents toDate:targetDate options:0];
	
	NSDateComponents *resultComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:newDate];
	return resultComponents;
}

- (IBAction)firstMonth:(id)sender
{
	NSDate *earliestDate = [Earning minimumToDateInManagedObjectContext:self.managedObjectContext];
	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:earliestDate];
	[self confirmChangeToMonth:dateComponents.month year:dateComponents.year];
}

- (IBAction)previousMonth:(id)sender
{
	NSDateComponents *dateComponents = [self adjustReconcileMonthBy:-1];
	[self confirmChangeToMonth:dateComponents.month year:dateComponents.year];
}

- (IBAction)nextMonth:(id)sender
{
	NSDateComponents *dateComponents = [self adjustReconcileMonthBy:1];
	[self confirmChangeToMonth:dateComponents.month year:dateComponents.year];
}

- (IBAction)lastMonth:(id)sender
{
	NSDate *latestDate = [Earning maximumToDateInManagedObjectContext:self.managedObjectContext];
	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:latestDate];
	[self confirmChangeToMonth:dateComponents.month year:dateComponents.year];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [reconcileData count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	id result = nil;
	
	DepositData *regionDepositData = [reconcileData objectAtIndex:rowIndex];
	InternationalInfo *internationalInfo = [InternationalInfo sharedInternationalInfo];

	NSString *tableColumnIdentifier = [aTableColumn identifier];
	if ([tableColumnIdentifier isEqualToString:@"subtotal"]) {
		result = regionDepositData.subtotal;
	}
	else if ([tableColumnIdentifier isEqualToString:@"currency"]) {
		result = [internationalInfo regionCurrencyForId:regionDepositData.regionId];
	}
	else if ([tableColumnIdentifier isEqualToString:@"region"]) {
		result = [internationalInfo regionNameForId:regionDepositData.regionId];
	}
	else {
		result = [regionDepositData valueForKey:tableColumnIdentifier];
	}
	
	return result;
}

#pragma mark - NSTableViewDelegate

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *tableColumnIdentifier = [aTableColumn identifier];
	if ([tableColumnIdentifier isEqualToString:@"balance"] ||
		[tableColumnIdentifier isEqualToString:@"sales"] || 
		[tableColumnIdentifier isEqualToString:@"adjustments"] ||
		[tableColumnIdentifier isEqualToString:@"subtotal"]) {
		DepositData *regionDepositData = [reconcileData objectAtIndex:rowIndex];
		NSString *regionId = regionDepositData.regionId;

		NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		InternationalInfo *internationalInfoManager = [InternationalInfo sharedInternationalInfo];
		numberFormatter.currencySymbol = [internationalInfoManager regionCurrencySymbolForId:regionId];
		if ([internationalInfoManager regionCurrencyDigitsForId:regionId] == 2) {
			numberFormatter.format = @"¤#,##0.00;-¤#,##0.00";
		}
		else {
			numberFormatter.format = @"¤#,##0;-¤#,##0";
		}
		numberFormatter.lenient = YES;
		
		[aCell setFormatter:numberFormatter];
	}
}

// TODO: keep track of reconciled state and disable -editColumn:row:withEvent:select: if the month is already reconciled

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger selectedRow = [tableView selectedRow];
	//DebugLog(@"%s selectedRow = %ld", __PRETTY_FUNCTION__, (long)selectedRow);
	
	NSUInteger tableColumnCount = [[tableView tableColumns] count];
	[tableView editColumn:(tableColumnCount - 1) row:selectedRow withEvent:nil select:YES];
}

// TODO: keep track of reconciled state and return NO for -control:textShouldBeginEditing: if the month is already reconciled
/*
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	//DebugLog(@"%s control = %@, fieldEditor = %@", __PRETTY_FUNCTION__, control, fieldEditor);
	
	return YES;
}
*/
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	NSInteger selectedRow = [tableView selectedRow];
	NSInteger editedColumn = [tableView editedColumn];

	DebugLog(@"%s control = %@, fieldEditor = %@, selectedRow = %ld, editedColumn = %ld", __PRETTY_FUNCTION__, control, fieldEditor, selectedRow, editedColumn);

	BOOL result = NO;
	
	if (editedColumn == 1) {
		// the first column contains the balance
		if ([self balanceSetManually]) {
			result = YES;
		}
	}
	else {
		// the adjustments and deposit columns can always be edited
		result = YES;
	}

	return result;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	//DebugLog(@"%s control = %@, fieldEditor = %@", __PRETTY_FUNCTION__, control, fieldEditor);

	if (reconcileData && [reconcileData count] > 0) {
		// get the field editor string and convert it to a decimal number with two decimal places
		NSString *valueString = [fieldEditor string];
		NSDecimalNumber *valueUnformatted = (NSDecimalNumber *)[_inputFormatter numberFromString:valueString];
		NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:2 raiseOnExactness:FALSE raiseOnOverflow:TRUE raiseOnUnderflow:TRUE raiseOnDivideByZero:TRUE];
		NSDecimalNumber *value = [valueUnformatted decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
		
		// save the value in the data model
		if (value) {
			NSInteger selectedRow = [tableView selectedRow];
			DepositData *regionDepositData = [reconcileData objectAtIndex:selectedRow];

			NSInteger column = [tableView editedColumn];
			DebugLog(@"%s column = %ld, adjustment = %@", __PRETTY_FUNCTION__, column, value);
			switch (column) {
				case 7:
					// update deposit
					regionDepositData.deposit = value;
					break;
				case 4:
					// update adjustment
					regionDepositData.adjustments = value;
					break;
				case 2:
					// update balance
					regionDepositData.balance = value;
					break;
					
				default:
					break;
			}
			
			NSDecimalNumber *rate = [NSDecimalNumber zero];
			NSDecimalNumber *subtotal = regionDepositData.subtotal;
			if ([subtotal compare:[NSDecimalNumber zero]] != NSOrderedSame) {
				rate = [regionDepositData.deposit decimalNumberByDividingBy:subtotal];
			}
			regionDepositData.rate = rate;

			[self willChangeValueForKey:@"isModified"];
			self.modified = YES;
			[self didChangeValueForKey:@"isModified"];
			DebugLog(@"%s set modified", __PRETTY_FUNCTION__);

			[self updateReconcileTotal];
		}
	}
	
	return YES;
}

- (void)selectPreviousTableRow
{
	NSInteger selectedRow = [tableView selectedRow] - 1;
	if (selectedRow < 0) {
		selectedRow = 0;
	}
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
}

- (void)selectNextTableRow
{
	NSInteger selectedRow = [tableView selectedRow] + 1;
	if (selectedRow > ([reconcileData count] - 1)) {
		selectedRow = [reconcileData count] - 1;
	}
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	DebugLog(@"%s command = %@", __PRETTY_FUNCTION__, NSStringFromSelector(command));

	BOOL result = NO;
	
	if (command == @selector(cancelOperation:)) {
		// the escape key will abort editing on the current row
		[control abortEditing];
		result = YES;
	}
	else if (command == @selector(insertNewline:)) {
		// the return key will commit the edit and move to the next row
		[[[self view] window] endEditingFor:control];
		[self performSelector:@selector(selectNextTableRow) withObject:nil afterDelay:0.0];
		result = YES;
	}
	else if (command == @selector(moveUp:)) {
		NSInteger selectedRow = [tableView selectedRow];
		if (selectedRow != 0) {
			// the up arrow key will abort editing and move to the next row
			[control abortEditing];
			[self performSelector:@selector(selectPreviousTableRow) withObject:nil afterDelay:0.0];
		}
		result = YES;
	}
	else if (command == @selector(moveDown:)) {			
		NSInteger selectedRow = [tableView selectedRow];
		if (selectedRow != ([reconcileData count] - 1)) {
			// the down arrow key will abort editing and move to the next row
			[control abortEditing];
			[self performSelector:@selector(selectNextTableRow) withObject:nil afterDelay:0.0];
		}
		result = YES;
	}

	return result;
}

#pragma mark - Operation callbacks

- (void)depositsParsedAtPath:(NSString *)path succeededWithResults:(NSArray *)results
{
	//DebugLog(@"%s path = %@, results = %@", __PRETTY_FUNCTION__, path, results);
	
	BOOL allDates = ([self.settings integerForKey:@"accountEarningsStart"] != 0); // the earnings start date is not July 2010
	[_depositImporter importDeposits:results allDates:allDates intoManagedObjectContext:self.managedObjectContext];
	
	self.importCount = 0;
	self.importTotal = [results count];
	[self updateImportProgressSheet];
}

- (void)depositsParsedAtPath:(NSString *)path failedWithError:(NSError *)error
{
	//DebugLog(@"%s path = %@, error = %@", __PRETTY_FUNCTION__, path, error);
	
	NSAlert *alert = [NSAlert alertWithMessageText:@"Deposit Parsing Failed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The parsing of '%@' failed with the error '%@'.", [error errorFileName], [error localizedDescription]];
	[alert runModal];

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(presentImportProgressSheet) object:nil];
	[self dismissImportProgressSheet];
}


- (void)depositsImportProcessedItem
{
	self.importCount = importCount + 1;
	//DebugLog(@"%s importCount = %lu of %lu", __PRETTY_FUNCTION__, importCount, importTotal);
	[self updateImportProgressSheet];
}

- (void)depositsImportSucceeded
{	
	[self dismissImportProgressSheet];
}

- (void)depositsImportFailedWithError:(NSError *)error
{
	//DebugLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
	
	NSAlert *alert = [NSAlert alertWithMessageText:@"Deposit Import Failed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The import failed with the error '%@'.", [error localizedDescription]];
	[alert runModal];

	[self dismissImportProgressSheet];
}

@end
