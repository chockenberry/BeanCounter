//
//  Split.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/19/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "Split.h"
#import "Product.h"

#import "DebugLog.h"

@interface Split (PrimitiveAccessors)

- (NSDate *)primitiveFromDate;
- (void)setPrimitiveFromDate:(NSDate *)fromDate;

@end

@implementation Split

@dynamic fromDate;
@dynamic percentage;
@dynamic Product;

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromFetch
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[super awakeFromFetch];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];
}

- (void)awakeFromInsert
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[super awakeFromInsert];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];
}

- (void)managedObjectContextChanged:(NSNotification *)notification
{
	// listen for changes to this object and make the KVO notifications fire for the "beginning" property which is computed using "fromDate"
	
	NSArray *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
	if ([updatedObjects containsObject:self]) {
		DebugLog(@"%s updating", __PRETTY_FUNCTION__);
		
		[self willChangeValueForKey:@"beginning"];
		[self didChangeValueForKey:@"beginning"];
	}
}

- (void)setBeginning:(NSNumber *)flag
{
	[self willChangeValueForKey:@"beginning"];
	
	if ([flag boolValue] == NO) {
		self.fromDate = nil;
	}
	else {
		NSDateComponents *currentDateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:[NSDate date]];
		NSDate *currentDate = [[NSCalendar currentCalendar] dateFromComponents:currentDateComponents];
		self.fromDate = currentDate;
	}

	[self didChangeValueForKey:@"beginning"];
}

- (NSNumber *)beginning
{
	[self willAccessValueForKey:@"beginning"];
	
	NSNumber *result = [NSNumber numberWithBool:NO];
	if (self.fromDate) {
		result = [NSNumber numberWithBool:YES];
	}
//	DebugLog(@"%s result = %@", __PRETTY_FUNCTION__, result);
	
	[self didAccessValueForKey:@"beginning"];

	return result;
}

@end
