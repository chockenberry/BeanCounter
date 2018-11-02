//
//  SourceListViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 11/26/11.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import "SourceListViewController.h"

#import "DebugLog.h"

NSString *const SourceListViewChangedNotification = @"SourceListViewChangedNotification";

@implementation SourceListViewController

NSString *const SourceListChartsItem = @"CHARTS";

NSString *const SourceListChartsProductsItem = @"Product Units";
NSString *const SourceListChartsRegionsItem = @"Regions Sales";
NSString *const SourceListChartsEarningsItem = @"Product Earnings";

NSString *const SourceListReportsItem = @"REPORTS";

NSString *const SourceListReportsSalesByProductItem = @"Units by Product";
NSString *const SourceListReportsSalesByRegionItem = @"Sales by Region";
NSString *const SourceListReportsEarningsByProductItem = @"Earnings by Product";
NSString *const SourceListReportsEarningsByRegionItem = @"Earnings by Region";

NSString *const SourceListManageItem = @"MANAGE";

NSString *const SourceListManageImportReportsItem = @"Import Reports";
NSString *const SourceListManageReconcileDepositsItem = @"Reconcile Deposits";
NSString *const SourceListManageEditAccountItem = @"Account Settings";
NSString *const SourceListManageEditProductsItem = @"Edit Products";
NSString *const SourceListManageEditGroupsItem = @"Edit Groups";
NSString *const SourceListManageEditPartnersItem = @"Edit Partners";


static NSArray *sourceListRootItems;
static NSArray *sourceListChartsItems;
static NSArray *sourceListReportsItems;
static NSArray *sourceListManageItems;


@synthesize managedObjectModel, managedObjectContext;
@synthesize outlineView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		sourceListRootItems = [[NSArray arrayWithObjects:SourceListChartsItem, SourceListReportsItem, SourceListManageItem, nil] retain];

		sourceListChartsItems = [[NSArray arrayWithObjects:SourceListChartsProductsItem, SourceListChartsRegionsItem, SourceListChartsEarningsItem, nil] retain];
		sourceListReportsItems = [[NSArray arrayWithObjects:SourceListReportsSalesByProductItem, SourceListReportsSalesByRegionItem, SourceListReportsEarningsByProductItem, SourceListReportsEarningsByRegionItem, nil] retain];
 		sourceListManageItems = [[NSArray arrayWithObjects:SourceListManageImportReportsItem, SourceListManageReconcileDepositsItem, SourceListManageEditAccountItem, SourceListManageEditProductsItem, SourceListManageEditGroupsItem, SourceListManageEditPartnersItem, nil] retain];
   }
    
    return self;
}

- (void)selectItem:(id)item
{
#if 0
	NSInteger row = [outlineView rowForItem:item];
	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
#else
	NSInteger selectedRow = NSNotFound;
	NSInteger numberOfRows = [outlineView numberOfRows];
	for (NSUInteger row = 0; row < numberOfRows; row++) {
		if ([[outlineView itemAtRow:row] isEqualToString:item]) {
			selectedRow = row;
			break;
		}
	}
	if (selectedRow != NSNotFound) {
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
	}
#endif
}

- (id)selectedItem
{
	id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
	DebugLog(@"%s selectedItem = %@", __PRETTY_FUNCTION__, selectedItem);
	return selectedItem;
}

- (void)awakeFromNib
{
	// TODO: open all items for a new window
	if (YES) {
		[outlineView expandItem:SourceListChartsItem];
		[outlineView expandItem:SourceListReportsItem];
		[outlineView expandItem:SourceListManageItem];
	}
	//[outlineView reloadData];
	
#if 0
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *selectedItem = [userDefaults objectForKey:@"sourceListSelectedItem"];

	// this bullshit is needed because -rowForItem: compares object addresses rather than using -isEqual:
	id item = nil;
	NSUInteger index;
	index = [sourceListChartsItems indexOfObject:selectedItem];
	if (index != NSNotFound) {
		item = [sourceListChartsItems objectAtIndex:index];
	}
	else {
		index = [sourceListReportsItems indexOfObject:selectedItem];
		if (index != NSNotFound) {
			item = [sourceListReportsItems objectAtIndex:index];
		}
		else {
			index = [sourceListManageItems indexOfObject:selectedItem];
			if (index != NSNotFound) {
				item = [sourceListManageItems objectAtIndex:index];
			}
		}
	}
	if (! item) {
		item = SourceListManageImportReportsItem;
	}
	NSInteger row = [outlineView rowForItem:item];

	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
#endif
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	NSInteger result = 0;
	if (item == nil) {
		result = [sourceListRootItems count];
	}
	else if ([item isEqualToString:SourceListChartsItem]) {
		result = [sourceListChartsItems count];
	}
	else if ([item isEqualToString:SourceListReportsItem]) {
		result = [sourceListReportsItems count];
	}
	else if ([item isEqualToString:SourceListManageItem]) {
		result = [sourceListManageItems count];
	}
	
	return result;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	id result = nil;
	if (item == nil) {
		result = [sourceListRootItems objectAtIndex:index];
	}
	else if ([item isEqualToString:SourceListChartsItem]) {
		result = [sourceListChartsItems objectAtIndex:index];
	}
	else if ([item isEqualToString:SourceListReportsItem]) {
		result = [sourceListReportsItems objectAtIndex:index];
	}
	else if ([item isEqualToString:SourceListManageItem]) {
		result = [sourceListManageItems objectAtIndex:index];
	}
	return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	BOOL result = NO;
	if ([item isEqualToString:SourceListChartsItem] || [item isEqualToString:SourceListReportsItem] || [item isEqualToString:SourceListManageItem]) {
		result = YES;
	}
	return result;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return item;
}

/*
- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item
{
	return item;
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object
{
	return object;
}
*/

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	// not used
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	DebugLog(@"%s item = %@", __PRETTY_FUNCTION__, item);
	
	BOOL result = YES;
	if ([item isEqualToString:SourceListChartsItem] || [item isEqualToString:SourceListReportsItem] || [item isEqualToString:SourceListManageItem]) {
		result = NO;
	}
	return result;
}

- (void)outlineViewSelectionIsChanging:(NSNotification *)notification
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

#if 0
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:[self selectedItem] forKey:@"sourceListSelectedItem"];
#endif
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SourceListViewChangedNotification object:self];
}

@end
