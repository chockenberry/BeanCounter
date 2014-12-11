//
//  DepositParser.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/16/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DepositParserOperation.h"

@protocol DepositParserObserver
@optional

// these methods are called after a file with deposits has been parsed
- (void)depositsParsedAtPath:(NSString *)path succeededWithResults:(NSArray *)results;
- (void)depositsParsedAtPath:(NSString *)path failedWithError:(NSError *)error;

@end

@interface DepositParser : NSObject <DepositParserDelegate>
{
	NSMutableSet *_observers;

	NSOperationQueue *_operationQueue;
}

- (DepositParser *)init;
- (DepositParser *)initWithParserObserver:(id<DepositParserObserver>)observer;

- (void)addObserver:(id<DepositParserObserver>)observer;
- (void)removeObserver:(id<DepositParserObserver>)observer;

- (void)parseDepositsAtPath:(NSString *)path;

@end
