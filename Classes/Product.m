// 
//  Product.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "Product.h"

#import "Group.h"
#import "Partner.h"
#import "Sale.h"

#import "NSManagedObjectContext+FetchAdditions.h"

@implementation Product 

@dynamic color;
@dynamic vendorId;
//@dynamic split;
@dynamic appleId;
@dynamic name;
@dynamic Group;
@dynamic Sales;
@dynamic Partner;
@dynamic Splits;

#pragma mark -

+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext
{
	return [managedObjectContext countForEntityName:@"Product" withPredicate:nil];
}


+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext
{
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Product" usingSortDescriptors:sortDescriptors];
}


+ (Product *)fetchInManagedObjectContext:managedObjectContext withAppleId:(NSNumber *)appleId
{
	Product *result = nil;
	
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Product" withPredicateFormat:@"appleId == %@", appleId];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}

// TODO: deprecate this method
+ (Product *)fetchInManagedObjectContext:managedObjectContext withName:(NSString *)name
{
	Product *result = nil;
	
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Product" withPredicateFormat:@"name == %@", name];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}

+ (Product *)fetchInManagedObjectContext:managedObjectContext withVendorId:(NSString *)vendorId
{
	Product *result = nil;
	
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Product" withPredicateFormat:@"vendorId == %@", vendorId];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}


+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forPartner:(Partner *)partner
{
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Product" usingSortDescriptors:sortDescriptors withPredicateFormat:@"Partner.name == %@", partner.name];
}

+ (NSArray *)fetchAllWithoutPartnerInManagedObjectContext:managedObjectContext
{
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Product" usingSortDescriptors:sortDescriptors withPredicateFormat:@"Partner.name == nil"];
}


+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forGroup:(Group *)group
{
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Product" usingSortDescriptors:sortDescriptors withPredicateFormat:@"Group.name == %@", group.name];
}

+ (NSArray *)fetchAllWithoutGroupInManagedObjectContext:managedObjectContext
{
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Product" usingSortDescriptors:sortDescriptors withPredicateFormat:@"Group.name == nil"];
}

@end
