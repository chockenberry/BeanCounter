//
//  NSManagedObjectContext+FetchAdditions.h
//
//  Created by Matt Gallagher on 26/02/07.
//  Copyright 2007 Matt Gallagher. All rights reserved.
//	http://cocoawithlove.com/2008/03/core-data-one-line-fetch.html
//
//	Adapted by Craig Hockenberry on 2/23/2012 to implement:
//	http://useyourloaf.com/blog/2012/1/19/core-data-queries-using-expressions.html
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "NSManagedObjectContext+FetchAdditions.h"

@implementation NSManagedObjectContext (FetchAdditions)

- (NSArray *)fetchObjectArrayForRequest:(NSFetchRequest *)request
{
	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:request error:&error];
	
	NSAssert(error == nil, [error description]);
	
	return results;
}

#pragma mark -

- (NSFetchRequest *)fetchRequestForEntity:(NSEntityDescription *)entity
{
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	
	return request;
}

- (NSFetchRequest *)fetchRequestForEntityName:(NSString *)entityName
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
	return [self fetchRequestForEntity:entity];
}


#pragma mark -

- (NSUInteger)countForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate
{
	NSFetchRequest *request = [self fetchRequestForEntityName:entityName];
	
	if (predicate) {
		[request setPredicate:predicate];
	}
	
	NSError *error = nil;
	NSUInteger result = [self countForFetchRequest:request error:&error];
	
	NSAssert(error == nil, [error description]);
	
	return result;
}

- (NSUInteger)countForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format arguments:(va_list)arguments
{
	NSPredicate *predicate = nil;
	if (format) {
		predicate = [NSPredicate predicateWithFormat:format arguments:arguments];
	}
	
	return [self countForEntityName:entityName withPredicate:predicate];
}

- (NSUInteger)countForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format, ...
{
	va_list arguments;
	va_start(arguments, format);
	NSUInteger result = [self countForEntityName:entityName withPredicateFormat:format arguments:arguments];
	va_end(arguments);
	
	return result;
}


#pragma mark -

- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicate:(NSPredicate *)predicate
{
	NSFetchRequest *request = [self fetchRequestForEntityName:entityName];
	
	if (sortDescriptors) {
		[request setSortDescriptors:sortDescriptors];
	}
	
	if (predicate) {
		[request setPredicate:predicate];
	}
	
	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:request error:&error];
	
	NSAssert(error == nil, [error description]);
	
	return results;
}

- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicateFormat:(NSString *)format arguments:(va_list)arguments
{
	NSPredicate *predicate = nil;
	if (format) {
		predicate = [NSPredicate predicateWithFormat:format arguments:arguments];
	}
	
	return [self fetchObjectArrayForEntityName:entityName usingSortDescriptors:sortDescriptors withPredicate:predicate];
}

- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicateFormat:(NSString *)format, ...
{
	va_list arguments;
	va_start(arguments, format);
	NSArray *results = [self fetchObjectArrayForEntityName:entityName usingSortDescriptors:sortDescriptors withPredicateFormat:format arguments:arguments];
	va_end(arguments);
	
	return results;
}

- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format, ...
{
	va_list arguments;
	va_start(arguments, format);
	NSArray *results = [self fetchObjectArrayForEntityName:entityName usingSortDescriptors:nil withPredicateFormat:format arguments:arguments];
	va_end(arguments);
	
	return results;
}

- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors
{
	return [self fetchObjectArrayForEntityName:entityName usingSortDescriptors:sortDescriptors withPredicate:nil];
}


#pragma mark -

- (id)fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function withPredicate:(NSPredicate *)predicate
{
	id value = nil;
	
	// get the entity so we can check its attribute information
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
	
	NSAttributeDescription *attribute = [[entity attributesByName] objectForKey:attributeName];
	if (attribute) {
		NSFetchRequest *request = [self fetchRequestForEntity:entity];
		
		NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:attributeName];
		NSExpression *functionExpression = [NSExpression expressionForFunction:function arguments:[NSArray arrayWithObject:keyPathExpression]];

		NSExpressionDescription *expressionDescription = [[[NSExpressionDescription alloc] init] autorelease];
		[expressionDescription setName:attributeName];
		[expressionDescription setExpression:functionExpression];
		[expressionDescription setExpressionResultType:[attribute attributeType]];
		
		[request setResultType:NSDictionaryResultType];
		[request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];

		if (predicate) {
			[request setPredicate:predicate];
		}

		NSError *error = nil;
		NSArray *results = [self executeFetchRequest:request error:&error];
		NSAssert(error == nil, [error description]);
		
		if (results) {
			value = [[results lastObject] valueForKey:attributeName];
		}
	}
	
	return value;
}

- (id)fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function withPredicateFormat:(NSString *)format arguments:(va_list)arguments
{
	NSPredicate *predicate = nil;
	if (format) {
		predicate = [NSPredicate predicateWithFormat:format arguments:arguments];
	}
	
	return [self fetchValueForEntityName:entityName usingAttribute:attributeName andFunction:function withPredicate:predicate];
}

- (id)fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function withPredicateFormat:(NSString *)format, ...
{
	id result = nil;

	va_list arguments;
	va_start(arguments, format);
	result = [self fetchValueForEntityName:entityName usingAttribute:attributeName andFunction:function withPredicateFormat:format arguments:arguments];
	va_end(arguments);
	
	return result;
}

- (id)fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function 
{
	return [self fetchValueForEntityName:entityName usingAttribute:attributeName andFunction:function withPredicate:nil];
}

@end
