//
//  ReportImporterSaleOperation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/23/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ReportImporterSaleOperation;

@protocol ReportImporterSaleDelegate
- (void)reportImporterSaleOperationDidSucceed:(ReportImporterSaleOperation *)reportImporterSaleOperation;
- (void)reportImporterSaleOperationDidFail:(ReportImporterSaleOperation *)reportImporterSaleOperation;
@end

@interface ReportImporterSaleOperation : NSOperation
{
	__weak NSObject <ReportImporterSaleDelegate> *_delegate; // weak reference

	id _parent;

	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
	NSManagedObjectContext *_managedObjectContext;

	NSError *reportError;
	NSArray *reportData;
	NSString *reportPath;

	NSDictionary *regionDictionary;
	NSDictionary *productDictionary;
}

@property (nonatomic, retain) NSError *reportError;
@property (nonatomic, copy) NSArray *reportData;
@property (nonatomic, copy) NSString *reportPath;

@property (nonatomic, retain) NSDictionary *regionDictionary;
@property (nonatomic, retain) NSDictionary *productDictionary;

//- (id)initWithReportData:(NSArray *)reportData fromPath:(NSString *)reportPath managedObjectContext:(NSManagedObjectContext *)managedObjectContext delegate:(NSObject *)theDelegate;
- (id)initWithReportData:(NSArray *)reportData fromPath:(NSString *)reportPath mergingWith:(id)parent delegate:(NSObject *)theDelegate;

@end
