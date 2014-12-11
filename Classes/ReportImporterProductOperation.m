//
//  ReportImporterProductOperation.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/23/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ReportImporterProductOperation.h"

#import "ReportData.h"
#import "Sale.h"
#import "Region.h"
#import "Product.h"
#import "InternationalInfo.h"

#import "DebugLog.h"


@implementation ReportImporterProductOperation

@synthesize reportError;
@synthesize reportData;
@synthesize reportPath;

- (id)initWithReportData:(NSArray *)initialData fromPath:(NSString *)initialReportPath mergingWith:(id)theParent delegate:(NSObject *)theDelegate
{
	if ((self = [super init])) {
		reportData = [initialData copy];
		reportPath = [initialReportPath copy];

		_parent = theParent;
		_persistentStoreCoordinator = [[_parent managedObjectContext] persistentStoreCoordinator]; // TODO: rename reference to _mainPersistentStoreCoordinator

		_delegate = theDelegate;
	}
	
	return self;
}

- (void)dealloc
{
	[reportError release];
	[reportData release];
	[reportPath release];

	_parent = nil;
	_persistentStoreCoordinator = nil;

	_delegate = nil;

	[super dealloc];
}

- (NSManagedObjectContext *)managedObjectContext
{
	if (!_managedObjectContext) {
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		[_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
		[_managedObjectContext setUndoManager:nil];
//		[_managedObjectContext setUndoManager:[[_parent managedObjectContext] undoManager]];
	}
	return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
	return [_persistentStoreCoordinator managedObjectModel];
}


/*
ReportData
{
	NSDate *periodDate;
	NSDate *startDate;
	NSDate *endDate;
	NSString *vendorIdentifier;
	NSNumber *quantity;
	NSNumber *partnerShare;
	NSNumber *extendedPartnerShare;
	NSString *currency;
	BOOL isReturn;
	NSString *appleIdentifier;
	NSString *developerName;
	NSString *productName;
	NSString *productType;
	NSString *countryOfSale;
}
*/

- (void)main
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	NSManagedObjectModel *managedObjectModel = [self managedObjectModel];
	NSManagedObjectContext *managedObjectContext = [self managedObjectContext];

	for (ReportData *reportDatum in reportData) {
		// check that the report data hasn't already been imported
		NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
				reportDatum.vendorIdentifier, @"vendorId",
				reportDatum.periodDate, @"date",
				reportDatum.partnerShare, @"amount",
				reportDatum.quantity, @"quantity",
				reportDatum.countryOfSale, @"country",
				nil];
		NSFetchRequest *existingSaleFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingSale" substitutionVariables:variables];
		// TODO: use [managedObjectContext countForFetchRequest:existingSaleFetchRequest error:NULL];
		NSArray *existingSales = [managedObjectContext executeFetchRequest:existingSaleFetchRequest error:NULL];
		if ([existingSales count] == 0) {
			// create the Product entity if needed
			{
				NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
						reportDatum.appleIdentifier, @"appleId",
						reportDatum.vendorIdentifier, @"vendorId",
						nil];
				NSFetchRequest *existingProductFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingProduct" substitutionVariables:variables];
				// TODO: use [managedObjectContext countForFetchRequest:existingProductFetchRequest error:NULL];
				NSArray *existingProducts = [managedObjectContext executeFetchRequest:existingProductFetchRequest error:NULL];
				if ([existingProducts count] == 0) {
					[_parent performSelectorOnMainThread:@selector(createProductWithReportData:) withObject:reportDatum waitUntilDone:YES];
				}
			}
		}
	}

	SEL selector = @selector(reportImporterProductOperationDidSucceed:);
	[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];

	[pool drain];
}

@end
