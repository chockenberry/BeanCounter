// 
//  Group.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "Group.h"

#import "Product.h"

#import "NSManagedObjectContext+FetchAdditions.h"


@implementation Group 

@dynamic groupId;
@dynamic name;
@dynamic info;
@dynamic color;
@dynamic Products;

#pragma mark -

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext
{
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Group" usingSortDescriptors:sortDescriptors];
}

// TODO: deprecate this method
+ (Group *)fetchInManagedObjectContext:managedObjectContext withName:(NSString *)name
{
	Group *result = nil;
	
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Group" withPredicateFormat:@"name == %@", name];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}

+ (Group *)fetchInManagedObjectContext:managedObjectContext withGroupId:(NSString *)groupId
{
	Group *result = nil;
	
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Group" withPredicateFormat:@"groupId == %@", groupId];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}

@end
