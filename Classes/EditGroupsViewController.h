//
//  EditGroupsViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/1/12.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OutputViewController.h"

@interface EditGroupsViewController : OutputViewController
{
	NSArrayController *groupArrayController;
	NSArrayController *availableProductsArrayController;
}

@property (nonatomic, retain) IBOutlet NSArrayController *groupArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController *availableProductsArrayController;

@property (nonatomic, readonly) NSArray *nameSortDescriptors;

- (IBAction)addGroup:(id)sender;
- (IBAction)removeGroup:(id)sender;
- (IBAction)addProduct:(id)sender;

@end
