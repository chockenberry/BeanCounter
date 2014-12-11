//
//  RegionSalesChartViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/2/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "RegionSalesChartViewController.h"

#import "CPTCalendarFormatter.h"

#import "Product.h"
#import "InternationalInfo.h"
#import "NSMutableDictionary+Settings.h"

#import "DebugLog.h"


@interface RegionSalesChartViewController ()

@end

@implementation RegionSalesChartViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
	}
	
	return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[super dealloc];
}

#pragma mark - Overrides

- (BOOL)usesRegion
{
	return YES;
}

- (NSOperation *)operationForChartCategory:(NSUInteger)category usingObject:(NSManagedObject *)object inRegion:(Region *)region asTotal:(BOOL)total withPeriod:(NSUInteger)period count:(NSUInteger)count from:(NSDate *)fromDate
{
	return [[[RegionSalesChartOperation alloc] initWithPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator] forCategory:category usingObject:object inRegion:region asTotal:total withPeriod:period count:count from:fromDate delegate:self] autorelease];
}

- (NSNumberFormatter *)numberFormatterInRegion:(Region *)region
{
	InternationalInfo *internationalInfoManager = [InternationalInfo sharedInternationalInfo];
	NSNumberFormatter *result = [[[NSNumberFormatter alloc] init] autorelease];
	result.numberStyle = NSNumberFormatterCurrencyStyle;
	result.currencySymbol = [internationalInfoManager regionCurrencySymbolForId:region.id];
	result.maximumFractionDigits = 0;
	result.minimumFractionDigits = 0;
	
	return result;
}

- (NSString *)chartTitleInRegion:(Region *)region
{
	return [@"Region Sales for " stringByAppendingString:region.name];
}

#pragma mark - Operation callback

- (void)regionSalesChartOperationCompleted:(RegionSalesChartOperation *)regionSalesChartOperation;
{
	NSManagedObject *object = [regionSalesChartOperation chartObject];
	NSArray *variables = [regionSalesChartOperation chartVariables];
	NSNumber *maximum = [regionSalesChartOperation chartMaximum];
	NSUInteger category = [regionSalesChartOperation chartCategory];
	BOOL total = [regionSalesChartOperation chartTotal];
	
	[self updatePlotWithOperationObject:object variables:variables maximum:maximum category:category total:total];
}

@end
