//
//  ReportImporterRegionOperation.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/23/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ReportImporterRegionOperation.h"

#import "ReportData.h"
#import "Sale.h"
#import "Region.h"
#import "Product.h"
#import "InternationalInfo.h"

#import "DebugLog.h"


@implementation ReportImporterRegionOperation

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

- (void)refreshObjects:(NSNotification *)notification
{
//	DebugLog(@"%s notification = %@", __PRETTY_FUNCTION__, notification);
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[_parent performSelectorOnMainThread:@selector(refreshObjects:) withObject:notification waitUntilDone:YES];
}

- (void)main
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	NSManagedObjectModel *managedObjectModel = [self managedObjectModel];
	NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
	
	NSString *reportName = [[reportPath lastPathComponent] stringByDeletingPathExtension];
	NSArray *reportNameComponents = [reportName componentsSeparatedByString:@"_"];
	NSString *regionId = [reportNameComponents lastObject];

	// create the Region entity if needed
	{
		NSDictionary *variables = [NSDictionary dictionaryWithObject:regionId forKey:@"id"];
		NSFetchRequest *existingRegionFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingRegion" substitutionVariables:variables];
		// TODO: use [managedObjectContext countForFetchRequest:existingRegionFetchRequest error:NULL];
		NSArray *existingRegions = [managedObjectContext executeFetchRequest:existingRegionFetchRequest error:NULL];
		if ([existingRegions count] == 0) {
			[_parent performSelectorOnMainThread:@selector(createRegionWithId:) withObject:regionId waitUntilDone:YES];
		}
	}

	SEL selector = @selector(reportImporterRegionOperationDidSucceed:);
	[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];

	[pool drain];
}

@end
