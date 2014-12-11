// 
//  Region.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "Region.h"

#import "Earning.h"
#import "Sale.h"

#import "InternationalInfo.h"

#import "NSManagedObjectContext+FetchAdditions.h"

@implementation Region 

@dynamic currency;
@dynamic id;
@dynamic name;
@dynamic Sales;
@dynamic Earnings;

#pragma mark -

+ (Region *)fetchInManagedObjectContext:managedObjectContext withId:(NSString *)regionId
{
	Region *result = nil;
		
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Region" withPredicateFormat:@"id == %@", regionId];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext
{
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Region" usingSortDescriptors:sortDescriptors];
}

+ (NSArray *)fetchAllInManagedObjectContextByCurrency:managedObjectContext
{
	NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"currency" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Region" usingSortDescriptors:sortDescriptors];
}

- (NSString *)displayName
{
	NSString *result = nil;
	
	InternationalInfo *internationalInfo = [InternationalInfo sharedInternationalInfo];
	result = [NSString stringWithFormat:@"%@ - %@", [internationalInfo regionCurrencyForId:self.id], [internationalInfo regionNameForId:self.id]];
	
	return result;
}

@end
