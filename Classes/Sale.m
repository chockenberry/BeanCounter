// 
//  Sale.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "Sale.h"

#import "Product.h"
#import "Group.h"
#import "Partner.h"
#import "Region.h"

#import "InternationalInfo.h"

#import "NSManagedObjectContext+FetchAdditions.h"

@implementation Sale 

@dynamic amount;
@dynamic quantity;
@dynamic total;
@dynamic country;
@dynamic date;
@dynamic Product;
@dynamic Region;

- (NSString *)countryName
{
	return [[InternationalInfo sharedInternationalInfo] countryNameForCode:self.country];
}

- (NSDecimalNumber *)computedTotal
{
	return [self.amount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[self.quantity decimalValue]]];
}

#pragma mark - Counts

+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext
{
	return [managedObjectContext countForEntityName:@"Sale" withPredicateFormat:nil];
}

#if 1

+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	return [managedObjectContext countForEntityName:@"Sale" withPredicateFormat:@"Product == %@ AND Region == %@ AND date >= %@ AND date < %@", product, region, startDate, endDate];
}

+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext forRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	return [managedObjectContext countForEntityName:@"Sale" withPredicateFormat:@"Region == %@ AND date >= %@ AND date < %@", region, startDate, endDate];
}

#else
// putting joins after properties in query doesn't speed things up

+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	return [managedObjectContext countForEntityName:@"Sale" withPredicateFormat:@"date >= %@ AND date < %@ AND Product == %@ AND Region == %@", startDate, endDate, product, region];
}

+ (NSUInteger)countAllInManagedObjectContext:managedObjectContext forRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	return [managedObjectContext countForEntityName:@"Sale" withPredicateFormat:@"date >= %@ AND date < %@ AND Region == %@", startDate, endDate, region];
}

#endif

#pragma mark - Fetches

#if 1

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	return [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:nil withPredicateFormat:@"Product == %@ AND Region == %@ AND date >= %@ AND date < %@", product, region, startDate, endDate];
}

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"country" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"amount" ascending:NO], nil];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:sortDescriptors withPredicateFormat:@"Region == %@ AND date >= %@ AND date < %@", region, startDate, endDate];
}

#else
// putting joins after properties in query doesn't speed things up

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	return [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:nil withPredicateFormat:@"date >= %@ AND date < %@ AND Product == %@ AND Region == %@", startDate, endDate, product, region];
}

+ (NSArray *)fetchAllInManagedObjectContext:managedObjectContext forRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"country" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"amount" ascending:NO], nil];
	return [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:sortDescriptors withPredicateFormat:@"date >= %@ AND date < %@ AND Region == %@", startDate, endDate, region];
}

#endif

#pragma mark - Expressions

+ (NSDecimalNumber *)sumTotalInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"total" andFunction:@"sum:" withPredicateFormat:@"Product == %@ AND Region == %@ AND date >= %@ AND date < %@", product, region, startDate, endDate];
}

+ (NSDecimalNumber *)sumTotalInManagedObjectContext:managedObjectContext forGroup:(Group *)group inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	if (group) {
		return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"total" andFunction:@"sum:" withPredicateFormat:@"Product.Group == %@ AND Region == %@ AND date >= %@ AND date < %@", group, region, startDate, endDate];
	}
	else {
		return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"total" andFunction:@"sum:" withPredicateFormat:@"Product.Group != NULL AND Region == %@ AND date >= %@ AND date < %@", region, startDate, endDate];
	}
}

+ (NSDecimalNumber *)sumTotalInManagedObjectContext:managedObjectContext forPartner:(Partner *)partner inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	if (partner) {
		return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"total" andFunction:@"sum:" withPredicateFormat:@"Product.Partner == %@ AND Region == %@ AND date >= %@ AND date < %@", partner, region, startDate, endDate];
	}
	else {
		return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"total" andFunction:@"sum:" withPredicateFormat:@"Product.Partner != NULL AND Region == %@ AND date >= %@ AND date < %@", region, startDate, endDate];
	}
}

+ (NSDecimalNumber *)sumTotalInManagedObjectContext:managedObjectContext forRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"total" andFunction:@"sum:" withPredicateFormat:@"Region == %@ AND date >= %@ AND date < %@", region, startDate, endDate];
}

#pragma mark -

+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext forProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"quantity" andFunction:@"sum:" withPredicateFormat:@"Product == %@ AND Region == %@ AND date >= %@ AND date < %@", product, region, startDate, endDate];
}

+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext forProduct:(Product *)product startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"quantity" andFunction:@"sum:" withPredicateFormat:@"Product == %@ AND date >= %@ AND date < %@", product, startDate, endDate];
}

+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext forGroup:(Group *)group startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	if (group) {
		return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"quantity" andFunction:@"sum:" withPredicateFormat:@"Product.Group == %@ AND date >= %@ AND date < %@", group, startDate, endDate];
	}
	else {
		return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"quantity" andFunction:@"sum:" withPredicateFormat:@"Product.Group != NULL AND date >= %@ AND date < %@", startDate, endDate];
	}
}

+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext forPartner:(Partner *)partner startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	if (partner) {
		return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"quantity" andFunction:@"sum:" withPredicateFormat:@"Product.Partner == %@ AND date >= %@ AND date < %@", partner, startDate, endDate];
	}
	else {
		return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"quantity" andFunction:@"sum:" withPredicateFormat:@"Product.Partner != NULL AND date >= %@ AND date < %@", startDate, endDate];
	}
}

+ (NSNumber *)sumQuantityInManagedObjectContext:managedObjectContext startDate:(NSDate *)startDate endDate:(NSDate *)endDate 
{
	return [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"quantity" andFunction:@"sum:" withPredicateFormat:@"date >= %@ AND date < %@", startDate, endDate];
}

#pragma mark -

+ (NSDate *)fastMinimumDateInManagedObjectContext:managedObjectContext 
{
	NSDate *result = nil;
	
	result = [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"date" andFunction:@"min:" withPredicate:nil];
	if (! result) {
		// can't use a fast expression because it only works on persisted data, so use this slower method
		NSArray *sales = [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:nil withPredicate:nil];
		result = [sales valueForKeyPath:@"@min.date"];
	}
	
	return result;
}

+ (NSDate *)fastMaximumDateInManagedObjectContext:managedObjectContext
{
	NSDate *result = nil;
	
	result = [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"date" andFunction:@"max:" withPredicate:nil];
	if (! result) {
		// can't use a fast expression because it only works on persisted data, so use this slower method
		NSArray *sales = [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:nil withPredicate:nil];
		result = [sales valueForKeyPath:@"@max.date"];
	}
	
	return result;
}

+ (NSDate *)minimumDateInManagedObjectContext:managedObjectContext 
{
	NSArray *sales = [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:nil withPredicate:nil];
	return [sales valueForKeyPath:@"@min.date"];
}

+ (NSDate *)maximumDateInManagedObjectContext:managedObjectContext
{
	NSArray *sales = [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:nil withPredicate:nil];
	return [sales valueForKeyPath:@"@max.date"];
}


+ (NSDate *)minimumDateInManagedObjectContext:managedObjectContext forProduct:(Product *)product 
{
	NSDate *result = nil;

	result = [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"date" andFunction:@"min:" withPredicateFormat:@"Product == %@", product];
	if (! result) {
		// can't use a fast expression because it only works on persisted data, so use this slower method
		NSArray *sales = [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:nil withPredicateFormat:@"Product == %@", product];
		result = [sales valueForKeyPath:@"@min.date"];
	}

	return result;
}

+ (NSDate *)maximumDateInManagedObjectContext:managedObjectContext forProduct:(Product *)product 
{
	NSDate *result = nil;

	result = [managedObjectContext fetchValueForEntityName:@"Sale" usingAttribute:@"date" andFunction:@"max:" withPredicateFormat:@"Product == %@", product];
	if (! result) {
		// can't use a fast expression because it only works on persisted data, so use this slower method
		NSArray *sales = [managedObjectContext fetchObjectArrayForEntityName:@"Sale" usingSortDescriptors:nil withPredicateFormat:@"Product == %@", product];
		result = [sales valueForKeyPath:@"@max.date"];
	}
	
	return result;
}

@end
