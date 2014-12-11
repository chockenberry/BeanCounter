//
//  RegionSalesChartOperation.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "RegionSalesChartOperation.h"

#import "InternationalInfo.h"
#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"
#import "Group.h"
#import "Partner.h"
//#import "PlotInformation.h"

#import "DebugLog.h"

@interface RegionSalesChartOperation ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end


@implementation RegionSalesChartOperation

@synthesize chartCategory;
@synthesize chartObject;
@synthesize chartRegion;
@synthesize chartTotal;
@synthesize chartPeriod;
@synthesize chartPeriodCount;
@synthesize chartStartDate;
@synthesize chartVariables;
@synthesize chartMaximum;

@synthesize managedObjectContext;

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)thePersistentStoreCoordinator forCategory:(NSUInteger)theCategory usingObject:(NSManagedObject *)theObject inRegion:(Region *)theRegion asTotal:(BOOL)theTotal withPeriod:(NSUInteger)thePeriod count:(NSUInteger)thePeriodCount from:(NSDate *)theStartDate delegate:(NSObject <RegionSalesChartOperationDelegate>*)theDelegate
{
	if ((self = [super init])) {
		chartCategory = theCategory;
		chartObject = [theObject retain];
		chartRegion = [theRegion retain];
		chartTotal = theTotal;
		chartPeriod = thePeriod;
		chartPeriodCount = thePeriodCount;
		chartStartDate = [theStartDate retain];
		chartVariables = nil;
		
		_persistentStoreCoordinator = thePersistentStoreCoordinator;
		_delegate = theDelegate;
	}
	
	return self;
}

- (void)dealloc
{
	[chartObject release];
	[chartRegion release];
	[chartStartDate release];
	[chartVariables release];
	[chartMaximum release];
	
	_persistentStoreCoordinator = nil;
	_delegate = nil;
	
	[super dealloc];
}

#define USE_COUNTS 0
#define USE_EXPRESSIONS 0

- (void)main
{
	if (self.isCancelled) {
		DebugLog(@"%s cancelled", __PRETTY_FUNCTION__);
		return;
	}

	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
#if DEBUG
	switch (chartCategory) {
		default:
		case 0: // product
			DebugLog(@"%s product chart data started for %@", __PRETTY_FUNCTION__, ((Product *)chartObject).name);
			break;
		case 1: // group
			DebugLog(@"%s group chart data started for %@", __PRETTY_FUNCTION__, ((Group *)chartObject).name);
			break;
		case 2: // partner
			DebugLog(@"%s partner chart data started for %@", __PRETTY_FUNCTION__, ((Partner *)chartObject).name);
			break;
	}
	NSDate *reportStart = [NSDate date];
#endif
	
	self.managedObjectContext = [[[NSManagedObjectContext alloc] init] autorelease];
	[managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];

	NSDateComponents *loopDateComponents = [[[NSDateComponents alloc] init] autorelease];
	switch (chartPeriod) {
		default:
		case 0:
			// month
			loopDateComponents.month = 1;
			break;
		case 1:
			// year
			loopDateComponents.year = 1;
			break;
	}
	
	NSMutableArray *variables = [NSMutableArray arrayWithCapacity:chartPeriodCount];
	NSNumber *maximum = [NSNumber numberWithInteger:0];
	
	BOOL haveFirstTotal = NO;
	NSDate *loopStartDate = chartStartDate;
	NSUInteger periodCount = 0;
	while (periodCount < chartPeriodCount) {
		NSDate *loopEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:loopDateComponents toDate:loopStartDate options:0];
		
		NSDecimalNumber *total = nil;
		switch (chartCategory) {
			default:
			case 0: // product
				if (chartTotal) {
					total = [Sale sumTotalInManagedObjectContext:self.managedObjectContext forRegion:chartRegion startDate:loopStartDate endDate:loopEndDate];
				}
				else {
					total = [Sale sumTotalInManagedObjectContext:self.managedObjectContext forProduct:(Product *)chartObject inRegion:chartRegion startDate:loopStartDate endDate:loopEndDate];
				}
				break;
			case 1: // group
				if (chartTotal) {
					total = [Sale sumTotalInManagedObjectContext:self.managedObjectContext forGroup:(Group *)chartObject inRegion:chartRegion startDate:loopStartDate endDate:loopEndDate];
				}
				else {
					if ([chartObject isKindOfClass:[Group class]]) {
						total = [Sale sumTotalInManagedObjectContext:self.managedObjectContext forGroup:(Group *)chartObject inRegion:chartRegion startDate:loopStartDate endDate:loopEndDate];
					}
					else {
						total = [Sale sumTotalInManagedObjectContext:self.managedObjectContext forProduct:(Product *)chartObject inRegion:chartRegion  startDate:loopStartDate endDate:loopEndDate];
					}
				}
				break;
			case 2: // partner
				if (chartTotal) {
					total = [Sale sumTotalInManagedObjectContext:self.managedObjectContext forPartner:(Partner *)chartObject inRegion:chartRegion startDate:loopStartDate endDate:loopEndDate];
				}
				else {
					if ([chartObject isKindOfClass:[Partner class]]) {
						total = [Sale sumTotalInManagedObjectContext:self.managedObjectContext forPartner:(Partner *)chartObject inRegion:chartRegion startDate:loopStartDate endDate:loopEndDate];
					}
					else {
						total = [Sale sumTotalInManagedObjectContext:self.managedObjectContext forProduct:(Product *)chartObject inRegion:chartRegion startDate:loopStartDate endDate:loopEndDate];
					}
				}
				break;
		}
		if (total) {
			if ([total compare:[NSDecimalNumber zero]] == NSOrderedDescending) {
				// total > 0
				haveFirstTotal = YES;
			}
			
			if (haveFirstTotal) {
				[variables addObject:total];
			}
			else {
				[variables addObject:[NSDecimalNumber numberWithInteger:NSIntegerMin]];
			}
		}
		else {
			if (haveFirstTotal) {
				[variables addObject:[NSDecimalNumber zero]];
			}
			else {
				[variables addObject:[NSDecimalNumber numberWithInteger:NSIntegerMin]];
			}
		}		
		
		if ([total compare:maximum] == NSOrderedDescending) {
			maximum = total;
		}
		
		periodCount += 1;
		loopStartDate = loopEndDate;

		if (self.isCancelled) {
			break;
		}
	}
	
	if (! self.isCancelled) {
		DebugLog(@"%s maximum = %@", __PRETTY_FUNCTION__, maximum);

		self.chartVariables = [NSArray arrayWithArray:variables];
		self.chartMaximum = maximum;
		
		[_delegate performSelectorOnMainThread:@selector(regionSalesChartOperationCompleted:) withObject:self waitUntilDone:YES];
	}
	
	self.managedObjectContext = nil;
	
#if DEBUG
	NSDate *reportEnd = [NSDate date];
	DebugLog(@"%s chart data generated in %f seconds", __PRETTY_FUNCTION__, [reportEnd timeIntervalSinceDate:reportStart]);
#endif
			
	[pool drain];
}

@end
