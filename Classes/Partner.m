// 
//  Partner.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "Partner.h"

#import "Product.h"

#import "NSManagedObjectContext+FetchAdditions.h"


@implementation Partner 

@dynamic partnerId;
@dynamic name;
@dynamic info;
@dynamic email;
@dynamic color;
@dynamic Products;

#pragma mark -

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext
{
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Partner" usingSortDescriptors:sortDescriptors];
}

// TODO: deprecate this method
+ (Partner *)fetchInManagedObjectContext:managedObjectContext withName:(NSString *)name
{
	Partner *result = nil;
	
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Partner" withPredicateFormat:@"name == %@", name];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}

+ (Partner *)fetchInManagedObjectContext:managedObjectContext withPartnerId:(NSString *)partnerId
{
	Partner *result = nil;
	
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Partner" withPredicateFormat:@"partnerId == %@", partnerId];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}


@end
