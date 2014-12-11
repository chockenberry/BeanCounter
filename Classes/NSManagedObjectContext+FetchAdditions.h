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

@interface NSManagedObjectContext (FetchAdditions)

- (NSArray *)fetchObjectArrayForRequest:(NSFetchRequest *)request;

- (NSFetchRequest *)fetchRequestForEntity:(NSEntityDescription *)entity;
- (NSFetchRequest *)fetchRequestForEntityName:(NSString *)entityName;

/*
 NSNumber *salaryLevel = [NSNumber numberWithInteger:1000000];
 NSUInteger count = [managedObjectContext countForEntityName:@"Employee" withPredicateFormat:@"salary > %@", salaryLevel];
 */

- (NSUInteger)countForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate;
- (NSUInteger)countForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format arguments:(va_list)arguments;
- (NSUInteger)countForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format, ...;

/*
 NSNumber *salaryLevel = [NSNumber numberWithInteger:1000000];
 NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
 NSArray *objects = [managedObjectContext fetchObjectArrayForEntityName:@"Employee" usingSortDescriptors:sortDescriptors withPredicateFormat:@"salary > %@", salaryLevel];
 */

- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicate:(NSPredicate *)predicate;
- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicateFormat:(NSString *)format arguments:(va_list)arguments;
- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicateFormat:(NSString *)format, ...;
- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format, ...;
- (NSArray *)fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors;

/*
 NSNumber *payroll = [managedObjectContext fetchObjectArrayForEntityName:@"Employee" usingAttribute:@"salary" andFunction:@"sum:" withPredicateFormat:@"dept == %@", marketing];

 Remember that not all data stores will implement all expressions. For example, an in-memory persistent store won't handle the 'min:' and 'max:' functions.
 See the NSExpression documentation for valid function names.
 */

- (id)fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function withPredicate:(NSPredicate *)predicate;
- (id)fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function withPredicateFormat:(NSString *)format arguments:(va_list)arguments;
- (id)fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function withPredicateFormat:(NSString *)format, ...;
- (id)fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function;

@end
