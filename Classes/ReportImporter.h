//
//  ReportImporter.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ReportImporterOperation.h"
#import "ReportData.h"

@protocol ReportImporterObserver
@optional

// these methods are called after report data has been imported
- (void)reportsImportProcessedItem:(NSUInteger)item;
- (void)reportsImportSucceeded;
- (void)reportsImportFailedWithError:(NSError *)error;
- (void)reportsImportNotedWithError:(NSError *)error;

@end

@interface ReportImporter : NSObject <ReportImporterDelegate>
{
	NSMutableSet *_observers;
	NSOperationQueue *_operationQueue;
}

- (ReportImporter *)init;
- (ReportImporter *)initWithImporterObserver:(id<ReportImporterObserver>)observer;

- (void)addObserver:(id<ReportImporterObserver>)observer;
- (void)removeObserver:(id<ReportImporterObserver>)observer;

- (void)importReports:(NSArray *)reportData intoManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
