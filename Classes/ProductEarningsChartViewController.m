//
//  ProductEarningsChartViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/2/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "ProductEarningsChartViewController.h"

#import "CPTCalendarFormatter.h"

#import "Product.h"
#import "InternationalInfo.h"
#import "NSMutableDictionary+Settings.h"

#import "DebugLog.h"


@interface ProductEarningsChartViewController ()

@end

@implementation ProductEarningsChartViewController

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
	return [[[ProductEarningsChartOperation alloc] initWithPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator] forCategory:category usingObject:object asTotal:total withPeriod:period count:count from:fromDate delegate:self] autorelease];
}

- (NSNumberFormatter *)numberFormatterInRegion:(Region *)region
{
	NSNumberFormatter *result = [[[NSNumberFormatter alloc] init] autorelease];
	result.numberStyle = NSNumberFormatterCurrencyStyle;
	result.maximumFractionDigits = 0;
	result.minimumFractionDigits = 0;
	
	return result;
}

- (NSString *)chartTitleInRegion:(Region *)region
{
	return @"Product Earnings";
}

#pragma mark - Operation callback

- (void)productEarningsChartOperationCompleted:(ProductEarningsChartOperation *)productEarningsChartOperation;
{
	NSManagedObject *object = [productEarningsChartOperation chartObject];
	NSArray *variables = [productEarningsChartOperation chartVariables];
	NSNumber *maximum = [productEarningsChartOperation chartMaximum];
	NSUInteger category = [productEarningsChartOperation chartCategory];
	BOOL total = [productEarningsChartOperation chartTotal];
	
	NSString *chartCategoryFilter = nil;
	if ([self filterChoiceIndex] != 0) {
		chartCategoryFilter = [self filterChoice];
	}

	NSString *plotIdentifier = nil;
	if (total) {
		plotIdentifier = @"__TOTAL__";
	}
	else {
		switch (category) {
			default:
			case 0: // product
				plotIdentifier = ((Product *)object).vendorId;
				break;
			case 1: // group
				if (chartCategoryFilter) {
					plotIdentifier = ((Product *)object).vendorId;
				}
				else {
					plotIdentifier = ((Group *)object).groupId;
				}
				break;
			case 2: // partner
				if (chartCategoryFilter) {
					plotIdentifier = ((Product *)object).vendorId;
				}
				else {
					plotIdentifier = ((Partner *)object).partnerId;
				}
				break;
		}
	}
	if (plotIdentifier) {
		[_chartVariablesCache setObject:variables forKey:plotIdentifier];
		DebugLog(@"%s set variables for %@", __PRETTY_FUNCTION__, plotIdentifier);
		
		CPTGraph *graph = self.graphHostingView.hostedGraph;
		
		if ([maximum compare:_chartMaximumCache] == NSOrderedDescending) {
			// round maximum value
			double originalMaximum = [maximum doubleValue];
#if 0
			double exponent = floor(log10(originalMaximum));
			double fraction = originalMaximum / pow(10.0, exponent);
			
#if 0
			double roundedFraction;
			if ( fraction <= 1.0 ) {
				roundedFraction = 1.0;
			}
			else if ( fraction <= 2.0 ) {
				roundedFraction = 2.0;
			}
			else if ( fraction <= 5.0 ) {
				roundedFraction = 5.0;
			}
			else {
				roundedFraction = 10.0;
			}
#else
			double roundedFraction;
			if ( fraction > 5.0 ) {
				roundedFraction = 10.0;
			}
			else if ( fraction > 2.0 ) {
				roundedFraction = 5.0;
			}
			else if ( fraction > 1.0 ) {
				roundedFraction = 2.0;
			}
			else {
				roundedFraction = 1.0;
			}
#endif
			double roundedMaximum = roundedFraction * pow(10.0, exponent);
#else		
			//		double rounding = pow(10.0, floor(log10(originalMaximum)) - 1.0); // 110 -> 120, 1,100 -> 1,200, 11,000 -> 12,000, ...
			double rounding = pow(10.0, floor(log10(originalMaximum))); // 110 -> 200, 1,100 -> 2,000, 11,000 -> 20,000, ...
			double roundedMaximum = ceil(originalMaximum / rounding) * rounding;
#endif
			
			[_chartMaximumCache release];
			_chartMaximumCache = [[NSNumber numberWithDouble:roundedMaximum] retain];
			
			DebugLog(@"%s set chart maximum to %@", __PRETTY_FUNCTION__, _chartMaximumCache);
			
			NSUInteger intervalCount = [variables count];
			
			// adjust plot space
			CPTXYPlotSpace *plotSpace = [[[CPTXYPlotSpace alloc] init] autorelease];
			{
				plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-0.5) length:CPTDecimalFromInteger(intervalCount)];
				plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:[_chartMaximumCache decimalValue]];
				[graph addPlotSpace:plotSpace];
			}
			
			for (CPTPlot *plot in graph.allPlots) {
				plot.plotSpace = plotSpace;
				[plot setNeedsDisplay];
			}
			
			CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
			axisSet.xAxis.plotSpace = plotSpace;
			axisSet.yAxis.plotSpace = plotSpace;
		}
		
		// load the plot with new data
		CPTPlot *plot = [graph plotWithIdentifier:plotIdentifier];
		plot.dataSource = self;
		[plot reloadData];
	}
}

@end
