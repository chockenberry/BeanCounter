//
//  ReportImporterOperation.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/23/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ReportImporterOperation.h"

#import "ReportData.h"
#import "Sale.h"
#import "Region.h"
#import "Product.h"
#import "InternationalInfo.h"
#import "NSError+Reporting.h"
#import "ColorPalette.h"

#import "DebugLog.h"

@interface ReportImporterOperation ()

@property (nonatomic, assign) NSUInteger importProgress;

@end

@implementation ReportImporterOperation

@synthesize importError;
@synthesize reportData;
@synthesize importProgress;

- (id)initWithReportData:(NSArray *)theReportData intoManagedObjectContext:(NSManagedObjectContext *)theManagedObjectContext delegate:(NSObject <ReportImporterDelegate>*)theDelegate;
{
	if ((self = [super init])) {
		reportData = [theReportData copy];

		_managedObjectContext = theManagedObjectContext;
		_delegate = theDelegate;
	}
	
	return self;
}

- (void)dealloc
{
	[importError release];
	[reportData release];

	_managedObjectContext = nil;
	_delegate = nil;

	[super dealloc];
}

#define DO_UNDO 1

- (void)main
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	InternationalInfo *internationalInfo = [InternationalInfo sharedInternationalInfo];

#if DEBUG
	DebugLog(@"%s report import started", __PRETTY_FUNCTION__);
	NSDate *importStart = [NSDate date];
#endif
	
	NSManagedObjectContext *managedObjectContext = _managedObjectContext;

#if DO_UNDO
	NSUndoManager *undoManager = [managedObjectContext undoManager];
	[undoManager beginUndoGrouping];
#endif
	
	importProgress = 0;
	NSUInteger progressThreshold = 1;
	NSUInteger progressCount = [reportData count];
	if (progressCount > 100) {
		progressThreshold = progressCount / 100;
	}

	for (ReportData *reportDatum in reportData) {
		// there's no way to determine if a report has already been imported (see refunds for Twitterrific Premium in November 2009 for an example)
		// so the check for duplicates happens during report parsing now
		
		NSAutoreleasePool *pool = [NSAutoreleasePool new];

		// create the Region entity if needed
		NSString *reportRegionId = reportDatum.regionId;
		NSString *regionName = [internationalInfo regionNameForId:reportRegionId];
		if (regionName) {
			Region *region = [Region fetchInManagedObjectContext:managedObjectContext withId:reportRegionId];
			if (! region) {
				
				region = [NSEntityDescription insertNewObjectForEntityForName:@"Region" inManagedObjectContext:managedObjectContext];
				region.id = reportRegionId;
				region.name = regionName;
				region.currency = [internationalInfo regionCurrencyForId:reportRegionId];
				
				NSString *errorDescription = [NSString stringWithFormat:@"Created new region: %@", region.name];
				self.importError = [NSError errorWithCode:ReportImporterOperationInfo filePath:nil description:errorDescription];
				
				SEL selector = @selector(reportImporterOperationDidNote:);
				[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
			}
			
			// create the Product entity if needed
			Product *product = [Product fetchInManagedObjectContext:managedObjectContext withAppleId:reportDatum.appleIdentifier];
			if (! product) {
				product = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:managedObjectContext];
				product.appleId = reportDatum.appleIdentifier;
				product.color = [[ColorPalette sharedColorPalette] nextColor];
				product.name = reportDatum.productName;
				product.vendorId = reportDatum.vendorIdentifier;
				
				{
					NSString *errorDescription = [NSString stringWithFormat:@"Created new product: %@", product.name];
					self.importError = [NSError errorWithCode:ReportImporterOperationInfo filePath:nil description:errorDescription];
					
					SEL selector = @selector(reportImporterOperationDidNote:);
					[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
				}
			}
			
			// add the Sale entity
			Sale *sale = [NSEntityDescription insertNewObjectForEntityForName:@"Sale" inManagedObjectContext:managedObjectContext];
			sale.date = reportDatum.periodDate;
			sale.amount = reportDatum.partnerShare;
			sale.quantity = reportDatum.quantity;
			sale.total = [sale computedTotal];
			sale.country = reportDatum.countryOfSale;
			sale.Region = region;
			sale.Product = product;
			
			//DebugLog(@"%s created sale for %@ at %@ in %@", __PRETTY_FUNCTION__, sale.quantity, sale.amount, sale.country);
			
#if 0
			NSError *error;
			BOOL valid = [sale validateForInsert:&error];
			if (! valid) {
				DebugLog(@"%s validation error = %@", __PRETTY_FUNCTION__, error);
			}
#endif
		}
		else {
			NSString *errorDescription = [NSString stringWithFormat:@"Cannot import sales for %@ in region '%@', update application to get latest regions", reportDatum.productName, reportRegionId];
			self.importError = [NSError errorWithCode:ReportImporterOperationError filePath:nil description:errorDescription];
			
			SEL selector = @selector(reportImporterOperationDidNote:);
			[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		}
		
		importProgress += 1;
		if (importProgress % progressThreshold == 0) {
			[_delegate performSelectorOnMainThread:@selector(reportImporterOperationProcessedItem:) withObject:self waitUntilDone:YES];
		}
		
		[pool drain];
	}

	[_delegate performSelectorOnMainThread:@selector(reportImporterOperationProcessedItem:) withObject:self waitUntilDone:YES];

#if DO_UNDO
	[managedObjectContext processPendingChanges];
	[undoManager endUndoGrouping];
	[undoManager setActionName:@"Import Report"];
#endif
	
	[_delegate performSelectorOnMainThread:@selector(reportImporterOperationDidSucceed:) withObject:self waitUntilDone:YES];

#if DEBUG
	NSDate *importEnd = [NSDate date];
	DebugLog(@"%s report import completed in %f seconds", __PRETTY_FUNCTION__, [importEnd timeIntervalSinceDate:importStart]);
#endif
	
	[pool drain];
}

@end
