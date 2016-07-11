//
//  ReportImporterOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/23/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	ReportImporterOperationError = -2000,
	ReportImporterOperationInfo = 0,
	ReportImporterOperationWarning = 2000,	
} ReportImporterOperationFailure;

@class ReportImporterOperation;

@protocol ReportImporterDelegate
- (void)reportImporterOperationProcessedItem:(ReportImporterOperation *)reportImporterOperation;
- (void)reportImporterOperationDidSucceed:(ReportImporterOperation *)reportImporterOperation;
- (void)reportImporterOperationDidFail:(ReportImporterOperation *)reportImporterOperation;
- (void)reportImporterOperationDidNote:(ReportImporterOperation *)reportImporterOperation;
@end

@interface ReportImporterOperation : NSOperation
{
	NSObject <ReportImporterDelegate> *_delegate; // weak reference
	NSManagedObjectContext *_managedObjectContext; // weak reference

	NSError *importError;
	NSArray *reportData;
	NSUInteger importProgress;
}

@property (nonatomic, retain) NSError *importError;
@property (nonatomic, copy) NSArray *reportData;
@property (nonatomic, readonly, assign) NSUInteger importProgress;

- (id)initWithReportData:(NSArray *)theReportData intoManagedObjectContext:(NSManagedObjectContext *)theManagedObjectContext delegate:(NSObject <ReportImporterDelegate>*)theDelegate;

@end
