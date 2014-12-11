//
//  Partner.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Product;

@interface Partner :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * partnerId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSColor * color;
@property (nonatomic, retain) NSSet* Products;

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext;

+ (Partner *)fetchInManagedObjectContext:managedObjectContext withName:(NSString *)name;
+ (Partner *)fetchInManagedObjectContext:managedObjectContext withPartnerId:(NSString *)partnerId;

@end


@interface Partner (CoreDataGeneratedAccessors)
- (void)addProductsObject:(Product *)value;
- (void)removeProductsObject:(Product *)value;
- (void)addProducts:(NSSet *)value;
- (void)removeProducts:(NSSet *)value;

@end

