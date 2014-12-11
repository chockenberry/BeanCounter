//
//  Group.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Product;

@interface Group :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * groupId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSColor * color;
@property (nonatomic, retain) NSSet* Products;

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext;

+ (Group *)fetchInManagedObjectContext:managedObjectContext withName:(NSString *)name;
+ (Group *)fetchInManagedObjectContext:managedObjectContext withGroupId:(NSString *)groupId;

@end


@interface Group (CoreDataGeneratedAccessors)
- (void)addProductsObject:(Product *)value;
- (void)removeProductsObject:(Product *)value;
- (void)addProducts:(NSSet *)value;
- (void)removeProducts:(NSSet *)value;

@end

