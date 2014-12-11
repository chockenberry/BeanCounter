//
//  ReportImporterProductOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/23/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ReportImporterProductOperation;

@protocol ReportImporterProductDelegate
- (void)reportImporterProductOperationDidSucceed:(ReportImporterProductOperation *)reportImporterProductOperation;
- (void)reportImporterProductOperationDidFail:(ReportImporterProductOperation *)reportImporterProductOperation;
@end

@interface ReportImporterProductOperation : NSOperation
{
	__weak NSObject <ReportImporterProductDelegate> *_delegate; // weak reference

	id _parent;

	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
	NSManagedObjectContext *_managedObjectContext;

	NSError *reportError;
	NSArray *reportData;
	NSString *reportPath;
}

@property (nonatomic, retain) NSError *reportError;
@property (nonatomic, copy) NSArray *reportData;
@property (nonatomic, copy) NSString *reportPath;

//- (id)initWithReportData:(NSArray *)reportData fromPath:(NSString *)reportPath managedObjectContext:(NSManagedObjectContext *)managedObjectContext delegate:(NSObject *)theDelegate;
- (id)initWithReportData:(NSArray *)reportData fromPath:(NSString *)reportPath mergingWith:(id)parent delegate:(NSObject *)theDelegate;

@end
