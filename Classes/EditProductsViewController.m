//
//  EditProductsViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/1/12.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import "EditProductsViewController.h"

#import "Product.h"
#import "Split.h"

#import "DebugLog.h"


@interface EditProductsViewController ()

@end


@implementation EditProductsViewController

@synthesize productArrayController;
@synthesize splitArrayController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
	}
    
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[super dealloc];
}	

#pragma mark - Accessors

- (NSArray *)nameSortDescriptors
{
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
}

- (NSArray *)fromDateSortDescriptors
{
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"fromDate" ascending:YES]];
}

#pragma mark - Methods

#pragma mark - Actions

- (IBAction)addSplit:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSUndoManager *undoManager = [managedObjectContext undoManager];
	[undoManager beginUndoGrouping];
	
	Split *split = [NSEntityDescription insertNewObjectForEntityForName:@"Split" inManagedObjectContext:managedObjectContext];
	split.fromDate = nil;
	split.percentage = [NSDecimalNumber decimalNumberWithMantissa:5 exponent:-1 isNegative:NO]; // 50%
	
	[splitArrayController addObject:split];
	
	[managedObjectContext processPendingChanges];
	[undoManager endUndoGrouping];
	[undoManager setActionName:@"Add Split"];
}

- (IBAction)removeSplit:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	if ([splitArrayController selectionIndex] != NSNotFound) {
		NSUndoManager *undoManager = [managedObjectContext undoManager];
		[undoManager beginUndoGrouping];

		Split *split = [[splitArrayController selectedObjects] objectAtIndex:0];
		[splitArrayController removeObject:split];
		
		[managedObjectContext processPendingChanges];
		[undoManager endUndoGrouping];
		[undoManager setActionName:@"Remove Split"];
	}	
}

#pragma mark - Utility

@end
