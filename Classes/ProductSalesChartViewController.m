//
//  ProductSalesChartViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/2/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "ProductSalesChartViewController.h"

#import "Product.h"
//#import "CPTCalendarFormatter.h"
#import "NSMutableDictionary+Settings.h"

#import "DebugLog.h"


@interface ProductSalesChartViewController ()

@end

@implementation ProductSalesChartViewController

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

- (NSOperation *)operationForChartCategory:(NSUInteger)category usingObject:(NSManagedObject *)object inRegion:(Region *)region asTotal:(BOOL)total withPeriod:(NSUInteger)period count:(NSUInteger)count from:(NSDate *)fromDate
{
	return [[[ProductSalesChartOperation alloc] initWithPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator] forCategory:category usingObject:object asTotal:total withPeriod:period count:count from:fromDate delegate:self] autorelease];
}

- (NSString *)chartTitleInRegion:(Region *)region
{
	return @"Product Units";
}

#pragma mark - Operation callback

- (void)productSalesChartOperationCompleted:(ProductSalesChartOperation *)productSalesChartOperation;
{
	NSManagedObject *object = [productSalesChartOperation chartObject];
	NSArray *variables = [productSalesChartOperation chartVariables];
	NSNumber *maximum = [productSalesChartOperation chartMaximum];
	NSUInteger category = [productSalesChartOperation chartCategory];
	BOOL total = [productSalesChartOperation chartTotal];
	
	[self updatePlotWithOperationObject:object variables:variables maximum:maximum category:category total:total];
}

@end
