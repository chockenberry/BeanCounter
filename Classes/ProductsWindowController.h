//
//  ProductsWindowController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/4/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProductsWindowController : NSWindowController
{
	NSWindow *productGroupWindow;
	NSTextField *productGroupNameTextField;
	NSWindow *partnerWindow;
	NSTextField *partnerNameTextField;

	NSArrayController *groupArrayController;
	NSArrayController *partnerArrayController;
	
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) IBOutlet NSWindow *productGroupWindow;
@property (nonatomic, retain) IBOutlet NSTextField *productGroupNameTextField;
@property (nonatomic, retain) IBOutlet NSWindow *partnerWindow;
@property (nonatomic, retain) IBOutlet NSTextField *partnerNameTextField;

@property (nonatomic, retain) IBOutlet NSArrayController *groupArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController *partnerArrayController;

@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, readonly) NSArray *nameSortDescriptors;

- (void)showModalInWindow:(NSWindow *)window;

- (IBAction)done:(id)sender;

- (IBAction)newProductGroup:(id)sender;
- (IBAction)productGroupCreate:(id)sender;
- (IBAction)productGroupCancel:(id)sender;

- (IBAction)newPartner:(id)sender;
- (IBAction)partnerCreate:(id)sender;
- (IBAction)partnerCancel:(id)sender;

@end
