//
//  ReportParserOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/20/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	ReportParserOperationError = -1000,
	ReportParserOperationInfo = 0,
	ReportParserOperationWarning = 1000,	
} ReportParserOperationFailure;

@class ReportParserOperation;

@protocol ReportParserDelegate
- (void)reportParserOperationDidSucceed:(ReportParserOperation *)reportParserOperation;
- (void)reportParserOperationDidFail:(ReportParserOperation *)reportParserOperation;
@end

@interface ReportParserOperation : NSOperation
{
	NSManagedObjectContext *_managedObjectContext; // weak reference
	NSObject <ReportParserDelegate> *_delegate; // weak reference

	NSString *reportPath;
	NSString *accountNumber;
	NSArray *reportDataValues;
	NSError *reportError;
}

@property (nonatomic, copy) NSString *reportPath;
@property (nonatomic, copy) NSString *accountNumber;
@property (nonatomic, retain) NSArray *reportDataValues;
@property (nonatomic, retain) NSError *reportError;

- (id)initWithReportPath:(NSString *)initialReportPath checkingAccountNumber:(NSString *)theAccountNumber withManagedObjectContext:(NSManagedObjectContext *)managedObjectContext delegate:(NSObject <ReportParserDelegate> *)theDelegate;

@end
