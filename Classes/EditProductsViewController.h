//
//  EditProductsViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/1/12.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OutputViewController.h"

@interface EditProductsViewController : OutputViewController
{
	NSArrayController *productArrayController;
	NSArrayController *splitArrayController;
//	NSArrayController *partnerArrayController;
}

@property (nonatomic, readonly) NSArray *nameSortDescriptors;
@property (nonatomic, readonly) NSArray *fromDateSortDescriptors;

@property (nonatomic, retain) IBOutlet NSArrayController *productArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController *splitArrayController;

- (IBAction)addSplit:(id)sender;
- (IBAction)removeSplit:(id)sender;

@end
