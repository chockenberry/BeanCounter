//
//  RegionSalesChartOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Product.h"
#import "Group.h"
#import "Partner.h"
#import "Region.h"

@class RegionSalesChartOperation;

@protocol RegionSalesChartOperationDelegate
- (void)regionSalesChartOperationCompleted:(RegionSalesChartOperation *)regionSalesChartOperation;
@end

@interface RegionSalesChartOperation : NSOperation
{
	NSUInteger chartCategory;
	NSManagedObject *chartObject;
	Region *chartRegion;
	BOOL chartTotal;
	NSUInteger chartPeriod;
	NSUInteger chartPeriodCount;
	NSDate *chartStartDate;
	NSArray *chartVariables;
	NSNumber *chartMaximum;
	
	NSPersistentStoreCoordinator *_persistentStoreCoordinator; // weak reference
	NSObject <RegionSalesChartOperationDelegate> *_delegate; // weak reference
}

@property (nonatomic, assign) NSUInteger chartCategory;
@property (nonatomic, retain) NSManagedObject *chartObject;
@property (nonatomic, retain) Region *chartRegion;
@property (nonatomic, assign) BOOL chartTotal;
@property (nonatomic, assign) NSUInteger chartPeriod;
@property (nonatomic, assign) NSUInteger chartPeriodCount;
@property (nonatomic, retain) NSDate *chartStartDate;
@property (nonatomic, retain) NSArray *chartVariables;
@property (nonatomic, retain) NSNumber *chartMaximum;


- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)thePersistentStoreCoordinator forCategory:(NSUInteger)theCategory usingObject:(NSManagedObject *)theObject inRegion:(Region *)theRegion asTotal:(BOOL)theTotal withPeriod:(NSUInteger)thePeriod count:(NSUInteger)thePeriodCount from:(NSDate *)theStartDate delegate:(NSObject <RegionSalesChartOperationDelegate>*)theDelegate;

@end
