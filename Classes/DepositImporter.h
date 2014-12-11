//
//  DepositImporter.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DepositImporterOperation.h"
#import "ReportData.h"

@protocol DepositImporterObserver
@optional

// these methods are called after report data has been imported
- (void)depositsImportProcessedItem;
- (void)depositsImportSucceeded;
- (void)depositsImportFailedWithError:(NSError *)error;

@end

@interface DepositImporter : NSObject <DepositImporterDelegate>
{
	NSMutableSet *_observers;
	NSOperationQueue *_operationQueue;
}

- (DepositImporter *)init;
- (DepositImporter *)initWithImporterObserver:(id<DepositImporterObserver>)observer;

- (void)addObserver:(id<DepositImporterObserver>)observer;
- (void)removeObserver:(id<DepositImporterObserver>)observer;

- (void)importDeposits:(NSArray *)depositData allDates:(BOOL)allDates intoManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
