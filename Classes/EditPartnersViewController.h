//
//  EditPartnersViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/1/12.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OutputViewController.h"

@interface EditPartnersViewController : OutputViewController
{
	NSArrayController *partnerArrayController;
	NSArrayController *availableProductsArrayController;
}

@property (nonatomic, retain) IBOutlet NSArrayController *partnerArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController *availableProductsArrayController;

@property (nonatomic, readonly) NSArray *nameSortDescriptors;

- (IBAction)addPartner:(id)sender;
- (IBAction)removePartner:(id)sender;
- (IBAction)addProduct:(id)sender;

@end
