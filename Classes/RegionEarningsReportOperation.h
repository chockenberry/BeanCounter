//
//  RegionEarningsReportOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RegionEarningsReportOperation;

@protocol RegionEarningsReportOperationDelegate
- (void)regionEarningsReportOperationCompleted:(RegionEarningsReportOperation *)regionEarningsReportOperation;
@end

@interface RegionEarningsReportOperation : NSOperation
{
	NSUInteger reportCategory;
	NSString *reportCategoryFilter;
	BOOL reportShowDetails;
	NSDate *reportStartDate;
	NSDate *reportEndDate;
	NSDictionary *reportVariables;
	
	NSNumberFormatter *_unitsFormatter;
	NSNumberFormatter *_salesFormatter;
	NSNumberFormatter *_earningsFormatter;
	NSNumberFormatter *_percentFormatter;
	NSDateFormatter *_dateFormatter;
	
	NSPersistentStoreCoordinator *_persistentStoreCoordinator; // weak reference
	NSObject <RegionEarningsReportOperationDelegate> *_delegate; // weak reference
}

@property (nonatomic, assign) NSUInteger reportCategory;
@property (nonatomic, copy) NSString *reportCategoryFilter;
@property (nonatomic, assign) BOOL reportShowDetails;
@property (nonatomic, retain) NSDate *reportStartDate;
@property (nonatomic, retain) NSDate *reportEndDate;
@property (nonatomic, retain) NSDictionary *reportVariables;

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)thePersistentStoreCoordinator withReportCategory:(NSUInteger)theReportCategory andCategoryFilter:(NSString *)theCategoryFilter showingDetails:(BOOL)theShowDetails from:(NSDate *)theStartDate to:(NSDate *)theEndDate delegate:(NSObject <RegionEarningsReportOperationDelegate>*)theDelegate;

@end
