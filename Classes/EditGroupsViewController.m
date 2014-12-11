//
//  EditGroupsViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/1/12.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import "EditGroupsViewController.h"

#import "Group.h"
#import "Product.h"
#import "ColorPalette.h"
#import "NSString+UUID.h"

#import "DebugLog.h"


@interface EditGroupsViewController ()

@end


@implementation EditGroupsViewController

@synthesize groupArrayController;
@synthesize availableProductsArrayController;

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

- (void)awakeFromNib
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

#pragma mark - KVO

#pragma mark - Accessors

- (NSArray *)nameSortDescriptors
{
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
}

#pragma mark - Methods

#pragma mark - Actions


- (IBAction)addGroup:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSUndoManager *undoManager = [managedObjectContext undoManager];
	[undoManager beginUndoGrouping];
	
	Group *group = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:managedObjectContext];
	group.groupId = [NSString stringWithNewUUID];
	group.name = @"New Group";
	group.color = [[ColorPalette sharedColorPalette] nextColor];
	
	[groupArrayController addObject:group];
	
	[managedObjectContext processPendingChanges];
	[undoManager endUndoGrouping];
	[undoManager setActionName:@"Add Group"];
}

- (IBAction)removeGroup:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	if ([groupArrayController selectionIndex] != NSNotFound) {
		NSUndoManager *undoManager = [managedObjectContext undoManager];
		[undoManager beginUndoGrouping];
	
		Group *group = [[groupArrayController selectedObjects] objectAtIndex:0];
		NSArray *products = [Product fetchAllInManagedObjectContext:managedObjectContext forGroup:group];
		for (Product *product in products) {
			product.Group = nil;
		}
		[groupArrayController removeObject:group];

		[managedObjectContext processPendingChanges];
		[undoManager endUndoGrouping];
		[undoManager setActionName:@"Remove Group"];
	}	
}

- (IBAction)addProduct:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	if ([groupArrayController selectionIndex] != NSNotFound && [availableProductsArrayController selectionIndex] != NSNotFound) {
		NSUndoManager *undoManager = [managedObjectContext undoManager];
		[undoManager beginUndoGrouping];
		
		Group *group = [[groupArrayController selectedObjects] objectAtIndex:0];
		
		NSMutableSet *products = [NSMutableSet setWithSet:group.Products];
		[products addObjectsFromArray:[availableProductsArrayController selectedObjects]];
		group.Products = products;

		[availableProductsArrayController rearrangeObjects];
		
		[managedObjectContext processPendingChanges];
		[undoManager endUndoGrouping];
		[undoManager setActionName:@"Add Group Product"];
	}
}

#pragma mark - Utility

@end
