//
//  Region.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Earning;
@class Sale;

@interface Region :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* Sales;
@property (nonatomic, retain) NSSet* Earnings;

+ (Region *)fetchInManagedObjectContext:managedObjectContext withId:(NSString *)regionId;
+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext;
+ (NSArray *)fetchAllInManagedObjectContextByCurrency:managedObjectContext;

@end


@interface Region (CoreDataGeneratedAccessors)
- (void)addSalesObject:(Sale *)value;
- (void)removeSalesObject:(Sale *)value;
- (void)addSales:(NSSet *)value;
- (void)removeSales:(NSSet *)value;

- (void)addEarningsObject:(Earning *)value;
- (void)removeEarningsObject:(Earning *)value;
- (void)addEarnings:(NSSet *)value;
- (void)removeEarnings:(NSSet *)value;

@end

