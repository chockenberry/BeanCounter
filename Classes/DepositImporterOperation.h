//
//  DepositImporterOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/23/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DepositImporterOperation;

@protocol DepositImporterDelegate
- (void)depositImporterOperationProcessedItem:(DepositImporterOperation *)depositImporterOperation;
- (void)depositImporterOperationDidSucceed:(DepositImporterOperation *)depositImporterOperation;
- (void)depositImporterOperationDidFail:(DepositImporterOperation *)depositImporterOperation;
@end

@interface DepositImporterOperation : NSOperation
{
	NSObject <DepositImporterDelegate> *_delegate; // weak reference
	NSManagedObjectContext *_managedObjectContext; // weak reference

	NSError *importError;
	NSArray *depositData;
	BOOL importAllDates;
}

@property (nonatomic, retain) NSError *importError;
@property (nonatomic, copy) NSArray *depositData;

- (id)initWithDepositData:(NSArray *)theDepositData allDates:(BOOL)allDates intoManagedObjectContext:(NSManagedObjectContext *)theManagedObjectContext delegate:(NSObject <DepositImporterDelegate>*)theDelegate;

@end
