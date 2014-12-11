//
//  DepositParser.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/16/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "DepositParser.h"

//#import "ReportData.h"
#import "DepositParserOperation.h"

#import "DebugLog.h"


@implementation DepositParser

- (DepositParser *)init
{
    if (self = [super init]) {
		_observers = [[NSMutableSet alloc] initWithCapacity:0];
		_operationQueue = [[NSOperationQueue alloc] init];

		// parsing reports can happen on multiple threads
		[_operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
	}
    
    return self;
}

- (DepositParser *)initWithParserObserver:(id<DepositParserObserver>)observer
{
    if ((self = [self init])) {
		[self addObserver:observer];
    }
    return self;
}

- (void)dealloc
{
	[_operationQueue cancelAllOperations];
	[_operationQueue release];	
	
	[_observers release];
	_observers = nil;
	
    [super dealloc];
}

- (void)parseDepositsAtPath:(NSString *)reportPath
{
	DepositParserOperation *operation = [[[DepositParserOperation alloc] initWithDepositPath:reportPath delegate:self] autorelease];
	if (operation) {
		[_operationQueue addOperation:operation];
	}
}

#pragma mark Observers

- (void)addObserver:(id<DepositParserObserver>)observer
{
	if (observer) {
		[_observers addObject:[NSValue valueWithNonretainedObject:observer]];
	}
}

- (void)removeObserver:(id<DepositParserObserver>)observer
{
	if (observer) {
		[_observers removeObject:[NSValue valueWithNonretainedObject:observer]];
	}
}

- (void)depositParserOperationDidSucceed:(DepositParserOperation *)depositParserOperation;
{
	NSString *reportPath = [depositParserOperation reportPath];
	NSArray *reportDataValues = [depositParserOperation reportDataValues];

	//DebugLog(@"%s reportDataValues = %@", __PRETTY_FUNCTION__, reportDataValues);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(depositsParsedAtPath:succeededWithResults:)]) {
			[object depositsParsedAtPath:reportPath succeededWithResults:reportDataValues];
		}
	}
}

- (void)depositParserOperationDidFail:(DepositParserOperation *)depositParserOperation;
{
	NSError *reportError = [depositParserOperation reportError];
	NSString *reportPath = [depositParserOperation reportPath];

	DebugLog(@"%s reportError = %@", __PRETTY_FUNCTION__, reportError);
	
	for (NSValue *o in [_observers allObjects]) {
		id object = [o nonretainedObjectValue];
		if ([object respondsToSelector:@selector(depositsParsedAtPath:failedWithError:)]) {
			[object depositsParsedAtPath:reportPath failedWithError:reportError];
		}
	}
}

@end
