//
//  Product.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Group;
@class Partner;
@class Sale;
@class Split;

@interface Product :  NSManagedObject  
{
}

@property (nonatomic, retain) NSColor * color;
@property (nonatomic, retain) NSString * vendorId;
//@property (nonatomic, retain) NSDecimalNumber * split;
@property (nonatomic, retain) NSNumber * appleId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Group * Group;
@property (nonatomic, retain) NSSet* Sales;
@property (nonatomic, retain) Partner * Partner;
@property (nonatomic, retain) NSSet* Splits;

+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext;

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext;

+ (Product *)fetchInManagedObjectContext:managedObjectContext withAppleId:(NSNumber *)appleId;
+ (Product *)fetchInManagedObjectContext:managedObjectContext withName:(NSString *)name;
+ (Product *)fetchInManagedObjectContext:managedObjectContext withVendorId:(NSString *)vendorId;

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forPartner:(Partner *)partner;
+ (NSArray *)fetchAllWithoutPartnerInManagedObjectContext:managedObjectContext;

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forGroup:(Group *)group;
+ (NSArray *)fetchAllWithoutGroupInManagedObjectContext:managedObjectContext;

@end


@interface Product (CoreDataGeneratedAccessors)
- (void)addSalesObject:(Sale *)value;
- (void)removeSalesObject:(Sale *)value;
- (void)addSales:(NSSet *)value;
- (void)removeSales:(NSSet *)value;
- (void)addSplitsObject:(Split *)value;
- (void)removeSplitsObject:(Split *)value;
- (void)addSplits:(NSSet *)value;
- (void)removeSplits:(NSSet *)value;

@end

