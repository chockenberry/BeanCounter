//
//  DepositImporterOperation.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/23/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "DepositImporterOperation.h"

#import "DepositData.h"
#import "Region.h"
#import "Earning.h"
#import "Sale.h"

#import "DebugLog.h"


@implementation DepositImporterOperation

@synthesize importError;
@synthesize depositData;

- (id)initWithDepositData:(NSArray *)theDepositData allDates:(BOOL)allDates intoManagedObjectContext:(NSManagedObjectContext *)theManagedObjectContext delegate:(NSObject <DepositImporterDelegate>*)theDelegate;
{
	if ((self = [super init])) {
		depositData = [theDepositData copy];
		importAllDates = allDates;

		_managedObjectContext = theManagedObjectContext;
		_delegate = theDelegate;
	}
	
	return self;
}

- (void)dealloc
{
	[importError release];
	[depositData release];

	_managedObjectContext = nil;
	_delegate = nil;

	[super dealloc];
}

#define DO_UNDO 1

#define LOG_RESULTS 0

- (void)main
{
#if DEBUG
	DebugLog(@"%s deposit import started", __PRETTY_FUNCTION__);
	NSDate *importStart = [NSDate date];
#endif
	
#if DO_UNDO
	NSUndoManager *undoManager = [_managedObjectContext undoManager];
	[undoManager beginUndoGrouping];
#endif

	NSDateComponents *earningsStartDateComponents = [[[NSDateComponents alloc] init] autorelease];
	earningsStartDateComponents.month = 7;
	if (! importAllDates) {
		// July 2010 is the first date to reconcile
		earningsStartDateComponents.year = 2010;
	}
	else {
		// July 2008 is the first date to reconcile
		earningsStartDateComponents.year = 2008;
	}
	NSDate *earningsStartDate = [[NSCalendar currentCalendar] dateFromComponents:earningsStartDateComponents];

	for (DepositData *depositDatum in depositData) {
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		NSDate *targetDate = depositDatum.date;
		if ([targetDate timeIntervalSinceDate:earningsStartDate] >= 0) {
//			NSDateComponents *targetDateComponents = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:targetDate];
			
			NSString *regionId = depositDatum.regionId;
			
			Region *region = [Region fetchInManagedObjectContext:_managedObjectContext withId:regionId];
			
			NSDateComponents *salesEndDateComponents = [[[NSDateComponents alloc] init] autorelease];
			salesEndDateComponents.month = 1;
			NSDate *salesEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:salesEndDateComponents toDate:targetDate options:0];
			
			NSArray *sales = [Sale fetchAllInManagedObjectContext:_managedObjectContext forRegion:region startDate:targetDate endDate:salesEndDate];
			NSDecimalNumber *salesTotal = [sales valueForKeyPath:@"@sum.total"];
			
			BOOL importData = NO;
			NSDecimalNumber *balanceTotal = [NSDecimalNumber zero];
			if (!importAllDates && [targetDate isEqualToDate:earningsStartDate]) {
				if (depositDatum.balance) {
					balanceTotal = depositDatum.balance;
				}
				importData = YES;
			}
			else {
				NSDateComponents *balanceEndDateComponents = [[[NSDateComponents alloc] init] autorelease];
				balanceEndDateComponents.month = -1;
				NSDate *balanceEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:balanceEndDateComponents toDate:targetDate options:0];
				
				NSDate *balanceStartDate = earningsStartDate;
				NSArray *earnings = [Earning fetchAllInManagedObjectContext:_managedObjectContext forRegion:region fromDate:balanceStartDate toDate:balanceEndDate];
				if (earnings && [earnings count] > 0) {
					NSDate *maxToDate = [earnings valueForKeyPath:@"@max.toDate"];
					
					NSDateComponents *balanceStartDateComponents = [[[NSDateComponents alloc] init] autorelease];
					balanceStartDateComponents.month = 1;
					balanceStartDate = [[NSCalendar currentCalendar] dateByAddingComponents:balanceStartDateComponents toDate:maxToDate options:0];
				}
				
				NSArray *balanceSales = [Sale fetchAllInManagedObjectContext:_managedObjectContext forRegion:region startDate:balanceStartDate endDate:targetDate];
				if ([balanceSales count] > 0) {
					balanceTotal = [balanceSales valueForKeyPath:@"@sum.total"];
				}
				
				if (([balanceTotal compare:[NSDecimalNumber zero]] != NSOrderedSame) || ([salesTotal compare:[NSDecimalNumber zero]] != NSOrderedSame)) {
					importData = YES;
				}
			}
			
			if (importData) {
				
				NSDecimalNumber *adjustments = depositDatum.adjustments;

				/*
				NSDecimalNumber *deposit = [NSDecimalNumber zero];
				NSDecimalNumber *rate = [NSDecimalNumber zero];
				NSDecimalNumber *adjustments = [NSDecimalNumber zero];
				Earning *earning = [Earning fetchInManagedObjectContext:managedObjectContext forRegion:region toDate:targetDate];
				if (earning) {
					deposit = earning.deposit;
					rate = earning.rate;
					adjustments = earning.adjustments;
				}
				*/
				
				NSDecimalNumber *subtotal = [balanceTotal decimalNumberByAdding:[salesTotal decimalNumberByAdding:adjustments]];
				
				
#if LOG_RESULTS
				NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
				dateFormatter.dateFormat = @"MMMM yyyy";
				DebugLog(@"%s loaded earning of %@ at %@ in %@ (%@ to %@)", __PRETTY_FUNCTION__, deposit, rate, region.id, [dateFormatter stringFromDate:balanceStartDate], [dateFormatter stringFromDate:targetDate]);
#endif
				
				NSDecimalNumber *deposit = depositDatum.deposit;
				
				if ([deposit compare:[NSDecimalNumber zero]] != NSOrderedSame) {
					// deposit is not zero, create a new earning or edit an existing one
					
					Region *region = [Region fetchInManagedObjectContext:_managedObjectContext withId:regionId];
					
					NSDateComponents *balanceEndDateComponents = [[[NSDateComponents alloc] init] autorelease];
					balanceEndDateComponents.month = -1;
					NSDate *balanceEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:balanceEndDateComponents toDate:targetDate options:0];
					
					NSDate *balanceStartDate = earningsStartDate;
					
					NSArray *earnings = [Earning fetchAllInManagedObjectContext:_managedObjectContext forRegion:region fromDate:[NSDate distantPast] toDate:balanceEndDate];
					if (earnings && [earnings count] > 0) {
						NSDate *maxToDate = [earnings valueForKeyPath:@"@max.toDate"];
						
						NSDateComponents *balanceStartDateComponents = [[[NSDateComponents alloc] init] autorelease];
						balanceStartDateComponents.month = 1;
						balanceStartDate = [[NSCalendar currentCalendar] dateByAddingComponents:balanceStartDateComponents toDate:maxToDate options:0];
					}
					
					NSDecimalNumber *rate = [NSDecimalNumber zero];
					if ([subtotal compare:[NSDecimalNumber zero]] != NSOrderedSame) {
						rate = [deposit decimalNumberByDividingBy:subtotal];
					}
					
					Earning *earning = [Earning fetchInManagedObjectContext:_managedObjectContext forRegion:region onDate:targetDate];
					if (! earning) {
						// create new earning
						earning = [NSEntityDescription insertNewObjectForEntityForName:@"Earning" inManagedObjectContext:_managedObjectContext];
					}
					
					earning.Region = region;
					earning.fromDate = balanceStartDate;
					earning.toDate = targetDate;
					if (!importAllDates && [targetDate isEqualToDate:earningsStartDate]) {
						earning.balance = balanceTotal;
					}
					earning.deposit = deposit;
					earning.rate = rate;
					earning.adjustments = adjustments;
					
#if LOG_RESULTS
					NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
					dateFormatter.dateFormat = @"MMMM yyyy";
					DebugLog(@"%s reconciled earning of %@ at %@ in %@ (%@ to %@)", __PRETTY_FUNCTION__, deposit, rate, region.id, [dateFormatter stringFromDate:balanceStartDate], [dateFormatter stringFromDate:targetDate]);
#endif
				}
				else {
					// deposit is zero, remove any existing earnings
					Region *region = [Region fetchInManagedObjectContext:_managedObjectContext withId:regionId];
					Earning *earning = [Earning fetchInManagedObjectContext:_managedObjectContext forRegion:region onDate:targetDate];
					if (earning) {
						[_managedObjectContext deleteObject:earning];
						DebugLog(@"%s removed earning in %@", __PRETTY_FUNCTION__, region.id);
					}
				}
			}
		}
		
		SEL selector = @selector(depositImporterOperationProcessedItem:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];

		[pool drain];
	}
	
#if DO_UNDO
	[_managedObjectContext processPendingChanges];
	[undoManager endUndoGrouping];
	[undoManager setActionName:@"Import Deposits"];
#endif
	
	SEL selector = @selector(depositImporterOperationDidSucceed:);
	[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];

#if DEBUG
	NSDate *importEnd = [NSDate date];
	DebugLog(@"%s deposit import completed in %f seconds", __PRETTY_FUNCTION__, [importEnd timeIntervalSinceDate:importStart]);
#endif
}

@end
