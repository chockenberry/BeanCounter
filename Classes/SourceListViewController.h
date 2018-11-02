//
//  SourceListViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 11/26/11.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *const SourceListViewChangedNotification;

extern NSString *const SourceListChartsProductsItem;
extern NSString *const SourceListChartsRegionsItem;
extern NSString *const SourceListChartsEarningsItem;

extern NSString *const SourceListReportsSalesByProductItem;
extern NSString *const SourceListReportsSalesByRegionItem;
extern NSString *const SourceListReportsEarningsByProductItem;
extern NSString *const SourceListReportsEarningsByRegionItem;

extern NSString *const SourceListManageImportReportsItem;
extern NSString *const SourceListManageReconcileDepositsItem;
extern NSString *const SourceListManageEditAccountItem;
extern NSString *const SourceListManageEditProductsItem;
extern NSString *const SourceListManageEditGroupsItem;
extern NSString *const SourceListManageEditPartnersItem;

@interface SourceListViewController : NSViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	
	NSOutlineView *outlineView;
}

@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet NSOutlineView *outlineView;

- (void)selectItem:(id)item;
- (id)selectedItem;

@end
