//
//  Earning.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Region;

@interface Earning :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * fromDate;
@property (nonatomic, retain) NSDate * toDate;
@property (nonatomic, retain) NSDecimalNumber * balance;
@property (nonatomic, retain) NSDecimalNumber * adjustments;
@property (nonatomic, retain) NSDecimalNumber * deposit;
@property (nonatomic, retain) NSDecimalNumber * rate;
@property (nonatomic, retain) Region * Region;

+ (Earning *)fetchInManagedObjectContext:managedObjectContext forRegion:(Region *)region toDate:(NSDate *)toDate;
+ (Earning *)fetchInManagedObjectContext:managedObjectContext forRegion:(Region *)region onDate:(NSDate *)date;
+ (NSArray *)fetchAllSortedInManagedObjectContext:managedObjectContext;
+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forRegion:(Region *)region fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

+ (NSDate *)minimumToDateInManagedObjectContext:managedObjectContext;
+ (NSDate *)maximumToDateInManagedObjectContext:managedObjectContext;

@end



