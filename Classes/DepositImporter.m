//
//  DepositImporter.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "DepositImporter.h"

#import "DepositImporterOperation.h"

#import "DebugLog.h"


@implementation DepositImporter

#define DO_THREAD 0

- (DepositImporter *)init
{
	if (self = [super init]) {
		_observers = [[NSMutableSet alloc] initWithCapacity:0];
#if DO_THREAD		
		_operationQueue = [[NSOperationQueue alloc] init];

		// import reports can only use a single thread since it creates objects (which may not be seen by other object contexts)
		[_operationQueue setMaxConcurrentOperationCount:1];
#else
		// this is me giving up: Core Data just can't cope with background threads that try to use the undo stack
		_operationQueue = [NSOperationQueue mainQueue];
#endif
	}
	
	return self;
}

- (DepositImporter *)initWithImporterObserver:(id<DepositImporterObserver>)observer
{
	if ((self = [self init])) {
		[self addObserver:observer];
	}
	return self;
}

- (void)dealloc
{
	[_operationQueue cancelAllOperations];
#if DO_THREAD
	[_operationQueue release];	
#endif
	
	[_observers release];
	_observers = nil;
	
	[super dealloc];
}

- (void)importDeposits:(NSArray *)depositData allDates:(BOOL)allDates intoManagedObjectContext:(NSManagedObjectContext *)theManagedObjectContext
{
	DepositImporterOperation *operation = [[[DepositImporterOperation alloc] initWithDepositData:depositData allDates:allDates intoManagedObjectContext:theManagedObjectContext delegate:self] autorelease];
	if (operation) {
		[_operationQueue addOperation:operation];
	}
}

#pragma mark Observers

- (void)addObserver:(id<DepositImporterObserver>)observer
{
	if (observer) {
		[_observers addObject:[NSValue valueWithNonretainedObject:observer]];
	}
}

- (void)removeObserver:(id<DepositImporterObserver>)observer
{
	if (observer) {
		[_observers removeObject:[NSValue valueWithNonretainedObject:observer]];
	}
}


- (void)depositImporterOperationProcessedItem:(DepositImporterOperation *)depositImporterOperation;
{
	//DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(depositsImportProcessedItem)]) {
			[object depositsImportProcessedItem];
		}
	}
}

- (void)depositImporterOperationDidSucceed:(DepositImporterOperation *)depositImporterOperation;
{
	//DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(depositsImportSucceeded)]) {
			[object depositsImportSucceeded];
		}
	}
}

- (void)depositImporterOperationDidFail:(DepositImporterOperation *)depositImporterOperation;
{
	NSError *reportError = [depositImporterOperation importError];

	DebugLog(@"%s reportError = %@", __PRETTY_FUNCTION__, reportError);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(depositsImportFailedWithError:)]) {
			[object depositsImportFailedWithError:reportError];
		}
	}
}

@end
