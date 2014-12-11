//
//  OutputViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 11/27/11.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import "OutputViewController.h"

#import "NSManagedObjectContext+FetchAdditions.h"

#import "DebugLog.h"


@implementation OutputViewController

@synthesize managedObjectModel, managedObjectContext;
@synthesize settings;

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[managedObjectModel release], managedObjectModel = nil;
	[managedObjectContext release], managedObjectContext = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark - Testing

#define WATCH_MANAGED_OBJECT_CONTEXT_CHANGES 1

#define WATCH_ALL_CONTEXTS 0

#if WATCH_MANAGED_OBJECT_CONTEXT_CHANGES
- (void)managedObjectContextChanged:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
//	DebugLog(@"%s inserted = %@, updated = %@, deleted = %@", __PRETTY_FUNCTION__, [userInfo objectForKey:NSInsertedObjectsKey], [userInfo objectForKey:NSUpdatedObjectsKey], [userInfo objectForKey:NSDeletedObjectsKey]);
	DebugLog(@"%s %@ inserted = %ld, updated = %ld, deleted = %ld", __PRETTY_FUNCTION__, ([NSThread isMainThread] ? @"MAIN" : @"BACKGROUND"), [[userInfo objectForKey:NSInsertedObjectsKey] count], [[userInfo objectForKey:NSUpdatedObjectsKey] count], [[userInfo objectForKey:NSDeletedObjectsKey] count]);
	//DebugLog(@"%s  updated = %@", __PRETTY_FUNCTION__, [userInfo objectForKey:NSUpdatedObjectsKey]);
	
	// TODO: refresh object with - (void)refreshObject:(NSManagedObject *)object mergeChanges:(BOOL)flag  ???

/*
	if (! [NSThread isMainThread]) {
		for (NSManagedObjectID *objectID in [[userInfo objectForKey:NSUpdatedObjectsKey] valueForKey:@"objectID"]) {
			[managedObjectContext objectWithID:objectID];
		}
	}
*/

//	NSUndoManager *undoManager = [self.managedObjectContext undoManager];
//	DebugLog(@"%s changes groupingLevel = %ld, undoStack = %@", __PRETTY_FUNCTION__, [undoManager groupingLevel], [undoManager valueForKey:@"_undoStack"]);

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(generateOutput) object:nil];
	[self performSelector:@selector(generateOutput) withObject:nil afterDelay:0.0];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)newManagedObjectContext
{
	if (newManagedObjectContext != managedObjectContext) {
#if WATCH_ALL_CONTEXTS
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
#else
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:managedObjectContext];
#endif
		
		[managedObjectContext release];
		managedObjectContext = [newManagedObjectContext retain];
		
#if WATCH_ALL_CONTEXTS
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
#else
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:managedObjectContext];
#endif
	}
}
#endif

#pragma mark - Overrides

- (void)saveSettings
{
}

- (void)generateOutput
{
}

- (NSPrintOperation *)printOperationWithPrintInfo:(NSPrintInfo *)printInfo
{
	return [NSPrintOperation printOperationWithView:self.view printInfo:printInfo];
}

@end
