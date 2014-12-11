//
//  RegionSalesReportOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RegionSalesReportOperation;

@protocol RegionSalesReportOperationDelegate
- (void)regionSalesReportOperationCompleted:(RegionSalesReportOperation *)regionSalesReportOperation;
@end

@interface RegionSalesReportOperation : NSOperation
{
	NSUInteger reportCategory;
	NSString *reportCategoryFilter;
	BOOL reportShowDetails;
	NSDate *reportStartDate;
	NSDate *reportEndDate;
	NSDictionary *reportVariables;
	
	NSNumberFormatter *_unitsFormatter;
	NSNumberFormatter *_salesFormatter;
	NSNumberFormatter *_percentFormatter;
	NSDateFormatter *_dateFormatter;
	
	__weak NSPersistentStoreCoordinator *_persistentStoreCoordinator; // weak reference
	__weak NSObject <RegionSalesReportOperationDelegate> *_delegate; // weak reference
}

@property (nonatomic, assign) NSUInteger reportCategory;
@property (nonatomic, copy) NSString *reportCategoryFilter;
@property (nonatomic, assign) BOOL reportShowDetails;
@property (nonatomic, retain) NSDate *reportStartDate;
@property (nonatomic, retain) NSDate *reportEndDate;
@property (nonatomic, retain) NSDictionary *reportVariables;

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)thePersistentStoreCoordinator withReportCategory:(NSUInteger)theReportCategory andCategoryFilter:(NSString *)theCategoryFilter showingDetails:(BOOL)theShowDetails from:(NSDate *)theStartDate to:(NSDate *)theEndDate delegate:(NSObject <RegionSalesReportOperationDelegate>*)theDelegate;

@end
