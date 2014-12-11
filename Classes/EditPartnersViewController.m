//
//  EditPartnersViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/1/12.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import "EditPartnersViewController.h"

#import "NSString+UUID.h"
#import "ColorPalette.h"

#import "DebugLog.h"


@interface EditPartnersViewController ()

@end


@implementation EditPartnersViewController

@synthesize partnerArrayController;
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

- (IBAction)addPartner:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	NSUndoManager *undoManager = [managedObjectContext undoManager];
	[undoManager beginUndoGrouping];
	
	Partner *partner = [NSEntityDescription insertNewObjectForEntityForName:@"Partner" inManagedObjectContext:managedObjectContext];
	partner.partnerId = [NSString stringWithNewUUID];
	partner.name = @"New Partner";
	partner.email = nil;
	partner.info = nil;
	partner.color = [[ColorPalette sharedColorPalette] nextColor];

	[partnerArrayController addObject:partner];

	[managedObjectContext processPendingChanges];
	[undoManager endUndoGrouping];
	[undoManager setActionName:@"Add Partner"];
}

- (IBAction)removePartner:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	if ([partnerArrayController selectionIndex] != NSNotFound) {
		NSUndoManager *undoManager = [managedObjectContext undoManager];
		[undoManager beginUndoGrouping];
		
		Partner *partner = [[partnerArrayController selectedObjects] objectAtIndex:0];
		NSArray *products = [Product fetchAllInManagedObjectContext:managedObjectContext forPartner:partner];
		for (Product *product in products) {
			product.Partner = nil;
		}
		[partnerArrayController removeObject:partner];
		
		[managedObjectContext processPendingChanges];
		[undoManager endUndoGrouping];
		[undoManager setActionName:@"Remove Partner"];
	}
}

- (IBAction)addProduct:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	if ([partnerArrayController selectionIndex] != NSNotFound && [availableProductsArrayController selectionIndex] != NSNotFound) {
		NSUndoManager *undoManager = [managedObjectContext undoManager];
		[undoManager beginUndoGrouping];
		
		Partner *partner = [[partnerArrayController selectedObjects] objectAtIndex:0];
		
		NSMutableSet *products = [NSMutableSet setWithSet:partner.Products];
		[products addObjectsFromArray:[availableProductsArrayController selectedObjects]];
		partner.Products = products;
		
		[availableProductsArrayController rearrangeObjects];
		
		[managedObjectContext processPendingChanges];
		[undoManager endUndoGrouping];
		[undoManager setActionName:@"Add Partner Product"];
	}
}


#pragma mark - Utility

@end
