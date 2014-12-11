//
//  ReportParser.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/16/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ReportParserOperation.h"

@protocol ReportParserObserver
@optional

// these methods are called after a report has been parsed
- (void)reportParsedAtPath:(NSString *)path succeededWithResults:(NSArray *)results;
- (void)reportParsedAtPath:(NSString *)path failedWithError:(NSError *)error;

@end

@interface ReportParser : NSObject <ReportParserDelegate>
{
	NSMutableSet *_observers;

	NSOperationQueue *_operationQueue;
}

- (ReportParser *)init;
- (ReportParser *)initWithParserObserver:(id<ReportParserObserver>)observer;

- (void)addObserver:(id<ReportParserObserver>)observer;
- (void)removeObserver:(id<ReportParserObserver>)observer;

- (void)parseReportAtPath:(NSString *)path checkingAccountNumber:(NSString *)accountNumber withManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
