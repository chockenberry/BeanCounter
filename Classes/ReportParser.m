//
//  ReportParser.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/16/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ReportParser.h"

//#import "ReportData.h"
#import "ReportParserOperation.h"

#import "DebugLog.h"


@implementation ReportParser

#define DO_THREAD 0

- (ReportParser *)init
{
    if (self = [super init]) {
		_observers = [[NSMutableSet alloc] initWithCapacity:0];
		_operationQueue = [[NSOperationQueue alloc] init];

#if DO_THREAD
		_operationQueue = [[NSOperationQueue alloc] init];
		
		// parsing reports can happen on multiple threads, but Core Data does its own threading
		[_operationQueue setMaxConcurrentOperationCount:1];
#else
		// this is me giving up: using a persistent store on a separate thread means that any unsaved changes (from previous imports) can't be checked.
		// the result is that the check for duplicate reports fails because it can't check for them on disk
		_operationQueue = [NSOperationQueue mainQueue];
#endif
	}
    
    return self;
}

- (ReportParser *)initWithParserObserver:(id<ReportParserObserver>)observer
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

- (void)parseReportAtPath:(NSString *)reportPath checkingAccountNumber:(NSString *)accountNumber withManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	ReportParserOperation *operation = [[[ReportParserOperation alloc] initWithReportPath:reportPath checkingAccountNumber:accountNumber withManagedObjectContext:managedObjectContext delegate:self] autorelease];
	if (operation) {
		[_operationQueue addOperation:operation];
	}
}

#pragma mark Observers

- (void)addObserver:(id<ReportParserObserver>)observer
{
	if (observer) {
		[_observers addObject:[NSValue valueWithNonretainedObject:observer]];
	}
}

- (void)removeObserver:(id<ReportParserObserver>)observer
{
	if (observer) {
		[_observers removeObject:[NSValue valueWithNonretainedObject:observer]];
	}
}

- (void)reportParserOperationDidSucceed:(ReportParserOperation *)reportParserOperation;
{
	NSString *reportPath = [reportParserOperation reportPath];
	NSArray *reportDataValues = [reportParserOperation reportDataValues];

	//DebugLog(@"%s reportDataValues = %@", __PRETTY_FUNCTION__, reportDataValues);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(reportParsedAtPath:succeededWithResults:)]) {
			[object reportParsedAtPath:reportPath succeededWithResults:reportDataValues];
		}
	}
}

- (void)reportParserOperationDidFail:(ReportParserOperation *)reportParserOperation;
{
	NSError *reportError = [reportParserOperation reportError];
	NSString *reportPath = [reportParserOperation reportPath];

	//DebugLog(@"%s reportError = %@", __PRETTY_FUNCTION__, reportError);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(reportParsedAtPath:failedWithError:)]) {
			[object reportParsedAtPath:reportPath failedWithError:reportError];
		}
	}
}

@end
