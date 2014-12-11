//
//  ReportImporter.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ReportImporter.h"

#import "ReportImporterOperation.h"

#import "DebugLog.h"


@implementation ReportImporter

#define DO_THREAD 0

- (ReportImporter *)init
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

- (ReportImporter *)initWithImporterObserver:(id<ReportImporterObserver>)observer
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

- (void)importReports:(NSArray *)reportData intoManagedObjectContext:(NSManagedObjectContext *)theManagedObjectContext;
{
	ReportImporterOperation *operation = [[[ReportImporterOperation alloc] initWithReportData:reportData intoManagedObjectContext:theManagedObjectContext delegate:self] autorelease];
	if (operation) {
		[_operationQueue addOperation:operation];
	}
}

#pragma mark Observers

- (void)addObserver:(id<ReportImporterObserver>)observer
{
	if (observer) {
		[_observers addObject:[NSValue valueWithNonretainedObject:observer]];
	}
}

- (void)removeObserver:(id<ReportImporterObserver>)observer
{
	if (observer) {
		[_observers removeObject:[NSValue valueWithNonretainedObject:observer]];
	}
}

- (void)reportImporterOperationProcessedItem:(ReportImporterOperation *)reportImporterOperation;
{
	//DebugLog(@"%s called", __PRETTY_FUNCTION__h);
	
	NSUInteger importProgress = [reportImporterOperation importProgress];
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(reportsImportProcessedItem:)]) {
			[object reportsImportProcessedItem:importProgress];
		}
	}
}

- (void)reportImporterOperationDidSucceed:(ReportImporterOperation *)reportImporterOperation;
{
	//DebugLog(@"%s called", __PRETTY_FUNCTION__h);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(reportsImportSucceeded)]) {
			[object reportsImportSucceeded];
		}
	}
}

- (void)reportImporterOperationDidNote:(ReportImporterOperation *)reportImporterOperation;
{
	NSError *importError = [reportImporterOperation importError];
	
	//DebugLog(@"%s importError = %@", __PRETTY_FUNCTION__, importError);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(reportsImportNotedWithError:)]) {
			[object reportsImportNotedWithError:importError];
		}
	}
}

- (void)reportImporterOperationDidFail:(ReportImporterOperation *)reportImporterOperation;
{
	NSError *importError = [reportImporterOperation importError];

	//DebugLog(@"%s importError = %@", __PRETTY_FUNCTION__, importError);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(reportsImportFailedWithError:)]) {
			[object reportsImportFailedWithError:importError];
		}
	}
}

@end
