//
//  Sale.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Product;
@class Group;
@class Partner;
@class Region;

@interface Sale :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) NSNumber * quantity;
@property (nonatomic, retain) NSDecimalNumber * total;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) Product * Product;
@property (nonatomic, retain) Region * Region;

@property (nonatomic, readonly) NSString *countryName;
@property (nonatomic, readonly) NSDecimalNumber *computedTotal;

+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext;
+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext forRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

+ (NSDecimalNumber *)sumTotalInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (NSDecimalNumber *)sumTotalInManagedObjectContext:managedObjectContext forGroup:(Group *)group inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (NSDecimalNumber *)sumTotalInManagedObjectContext:managedObjectContext forPartner:(Partner *)partner inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (NSDecimalNumber *)sumTotalInManagedObjectContext:managedObjectContext forRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext forProduct:(Product *)product startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext forGroup:(Group *)group startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext forPartner:(Partner *)partner startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

+ (NSDate *)fastMinimumDateInManagedObjectContext:managedObjectContext;
+ (NSDate *)fastMaximumDateInManagedObjectContext:managedObjectContext;

+ (NSDate *)minimumDateInManagedObjectContext:managedObjectContext;
+ (NSDate *)maximumDateInManagedObjectContext:managedObjectContext;

+ (NSDate *)minimumDateInManagedObjectContext:managedObjectContext forProduct:(Product *)product;
+ (NSDate *)maximumDateInManagedObjectContext:managedObjectContext forProduct:(Product *)product;

@end



