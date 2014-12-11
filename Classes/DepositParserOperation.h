//
//  DepositParserOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/20/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	DepositParserOperationError = -1000,
	DepositParserOperationInfo = 0,
	DepositParserOperationWarning = 1000,	
} DepositParserOperationFailure;

@class DepositParserOperation;

@protocol DepositParserDelegate
- (void)depositParserOperationDidSucceed:(DepositParserOperation *)depositParserOperation;
- (void)depositParserOperationDidFail:(DepositParserOperation *)depositParserOperation;
@end

@interface DepositParserOperation : NSOperation
{
	__weak NSObject <DepositParserDelegate> *_delegate; // weak reference

	NSError *reportError;
	NSString *reportPath;
	NSArray *reportDataValues;
}

@property (nonatomic, retain) NSError *reportError;
@property (nonatomic, copy) NSString *reportPath;
@property (nonatomic, retain) NSArray *reportDataValues;

- (id)initWithDepositPath:(NSString *)initialDepositPath delegate:(NSObject <DepositParserDelegate> *)theDelegate;

@end
