// 
//  Earning.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "Earning.h"

#import "Region.h"

#import "NSManagedObjectContext+FetchAdditions.h"

@implementation Earning 

@dynamic fromDate;
@dynamic toDate;
@dynamic balance;
@dynamic adjustments;
@dynamic deposit;
@dynamic rate;
@dynamic Region;

#pragma mark -

+ (Earning *)fetchInManagedObjectContext:managedObjectContext forRegion:(Region *)region toDate:(NSDate *)toDate
{
	Earning *result = nil;
	
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Earning" withPredicateFormat:@"Region.id == %@ AND toDate == %@", region.id, toDate];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}

+ (Earning *)fetchInManagedObjectContext:managedObjectContext forRegion:(Region *)region onDate:(NSDate *)date
{
	Earning *result = nil;
	
	NSArray *results = [managedObjectContext fetchObjectArrayForEntityName:@"Earning" withPredicateFormat:@"Region.id == %@ AND fromDate <= %@ AND toDate >= %@", region.id, date, date];
	if ([results count] > 0) {
		result = [results lastObject];
	}
	
	return result;
}

+ (NSArray *)fetchAllSortedInManagedObjectContext:managedObjectContext
{
	NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"toDate" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"Region.id" ascending:YES], nil];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Earning" usingSortDescriptors:sortDescriptors];
}

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forRegion:(Region *)region fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
	return [managedObjectContext fetchObjectArrayForEntityName:@"Earning" withPredicateFormat:@"Region.id == %@ AND fromDate >= %@ AND toDate <= %@", region.id, fromDate, toDate];
}

#pragma mark -

+ (NSDate *)minimumToDateInManagedObjectContext:managedObjectContext 
{
	NSArray *earnings = [managedObjectContext fetchObjectArrayForEntityName:@"Earning" usingSortDescriptors:nil withPredicate:nil];
	return [earnings valueForKeyPath:@"@min.toDate"];
}

+ (NSDate *)maximumToDateInManagedObjectContext:managedObjectContext
{
	NSArray *earnings = [managedObjectContext fetchObjectArrayForEntityName:@"Earning" usingSortDescriptors:nil withPredicate:nil];
	return [earnings valueForKeyPath:@"@max.toDate"];
}


@end
