//
//  ProductSalesChartOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Product.h"
#import "Group.h"
#import "Partner.h"


@class ProductSalesChartOperation;

@protocol ProductSalesChartOperationDelegate
- (void)productSalesChartOperationCompleted:(ProductSalesChartOperation *)productSalesChartOperation;
@end

@interface ProductSalesChartOperation : NSOperation
{
	NSUInteger chartCategory;
	NSManagedObject *chartObject;
	BOOL chartTotal;
	NSUInteger chartPeriod;
	NSUInteger chartPeriodCount;
	NSDate *chartStartDate;
	NSArray *chartVariables;
	NSNumber *chartMaximum;
	
	NSPersistentStoreCoordinator *_persistentStoreCoordinator; // weak reference
	NSObject <ProductSalesChartOperationDelegate> *_delegate; // weak reference
}

@property (nonatomic, assign) NSUInteger chartCategory;
@property (nonatomic, retain) NSManagedObject *chartObject;
@property (nonatomic, assign) BOOL chartTotal;
@property (nonatomic, assign) NSUInteger chartPeriod;
@property (nonatomic, assign) NSUInteger chartPeriodCount;
@property (nonatomic, retain) NSDate *chartStartDate;
@property (nonatomic, retain) NSArray *chartVariables;
@property (nonatomic, retain) NSNumber *chartMaximum;


- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)thePersistentStoreCoordinator forCategory:(NSUInteger)theCategory usingObject:(NSManagedObject *)theObject asTotal:(BOOL)theTotal withPeriod:(NSUInteger)thePeriod count:(NSUInteger)thePeriodCount from:(NSDate *)theStartDate delegate:(NSObject <ProductSalesChartOperationDelegate>*)theDelegate;

@end
