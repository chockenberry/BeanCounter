//
//  ProductsWindowController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/4/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ProductsWindowController.h"

#import "Group.h"
#import "Partner.h"

#import "DebugLog.h"


@implementation ProductsWindowController

@synthesize productGroupWindow, productGroupNameTextField, partnerWindow, partnerNameTextField;
@synthesize groupArrayController, partnerArrayController;
@synthesize managedObjectModel, managedObjectContext;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

    self = [super initWithWindowNibName:windowNibName];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[productGroupWindow release];
	[productGroupNameTextField release];
	[partnerWindow release];
	[partnerNameTextField release];
	
	[groupArrayController release];
	[partnerArrayController release];

	[managedObjectModel release];
	[managedObjectContext release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

#pragma mark Initialization

#define USE_SHEET 0

/*
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}
*/

- (void)showModalInWindow:(NSWindow *)window
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

//	NSUndoManager *undoManager = [managedObjectContext undoManager];
//	[undoManager setGroupsByEvent:NO];
//	DebugLog(@"%s _undoStack = %@", __PRETTY_FUNCTION__, [undoManager valueForKey:@"_undoStack"]);
//	[undoManager beginUndoGrouping];

//	DebugLog(@"%s _undoStack = %@", __PRETTY_FUNCTION__, [undoManager valueForKey:@"_undoStack"]);
	
#if USE_SHEET
	//[NSApp beginSheet:self.window modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[NSApp beginSheet:self.window modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
#else
	[NSApp runModalForWindow:self.window];
#endif
}

#pragma mark Accessors

- (NSArray *)nameSortDescriptors
{
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
}

#pragma mark Actions

- (IBAction)done:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	NSUndoManager *undoManager = [managedObjectContext undoManager];
	//	DebugLog(@"%s _undoStack = %@", __PRETTY_FUNCTION__, [undoManager valueForKey:@"_undoStack"]);
	//	[undoManager endUndoGrouping];
	[undoManager setActionName:@"Product Changes"];
//	DebugLog(@"%s _undoStack = %@", __PRETTY_FUNCTION__, [undoManager valueForKey:@"_undoStack"]);

#if USE_SHEET
	// grab any pending editing changes in the text fields
	[self.window makeFirstResponder:self.window];

	[NSApp endSheet:self.window returnCode:NSOKButton];

	[self.window orderOut:sender];
#else
	[self.window performClose:sender];
#endif	
}

- (IBAction)newProductGroup:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	[NSApp beginSheet:productGroupWindow modalForWindow:self.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)productGroupCreate:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	NSUndoManager *undoManager = [managedObjectContext undoManager];

	NSString *productGroupName = [productGroupNameTextField stringValue];
	NSDictionary *variables = [NSDictionary dictionaryWithObject:productGroupName forKey:@"name"];
	NSFetchRequest *existingGroupFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingGroup" substitutionVariables:variables];
	NSArray *existingGroups = [managedObjectContext executeFetchRequest:existingGroupFetchRequest error:NULL];
	if ([existingGroups count] == 0) {
		[undoManager beginUndoGrouping];

		Group *group = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:managedObjectContext];
		group.name = productGroupName;
		[groupArrayController addObject:group];

		[managedObjectContext processPendingChanges];
		[undoManager endUndoGrouping];
		[undoManager setActionName:@"Create Group"];
		
		[NSApp endSheet:productGroupWindow returnCode:NSOKButton];
		[productGroupWindow orderOut:sender];
	}
	else {
// TODO: display an error message that the name already exists
	}
}

- (IBAction)productGroupCancel:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[NSApp endSheet:productGroupWindow returnCode:NSCancelButton];
	[productGroupWindow orderOut:sender];
}

- (IBAction)newPartner:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	[NSApp beginSheet:partnerWindow modalForWindow:self.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)partnerCreate:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	NSUndoManager *undoManager = [managedObjectContext undoManager];

	NSString *partnerName = [partnerNameTextField stringValue];
	NSDictionary *variables = [NSDictionary dictionaryWithObject:partnerName forKey:@"name"];
	NSFetchRequest *existingPartnerFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingPartner" substitutionVariables:variables];
	NSArray *existingPartners = [managedObjectContext executeFetchRequest:existingPartnerFetchRequest error:NULL];
	if ([existingPartners count] == 0) {
		[undoManager beginUndoGrouping];

		Partner *partner = [NSEntityDescription insertNewObjectForEntityForName:@"Partner" inManagedObjectContext:managedObjectContext];
		partner.name = partnerName;
		[partnerArrayController addObject:partner];

		[managedObjectContext processPendingChanges];
		[undoManager endUndoGrouping];
		[undoManager setActionName:@"Create Partner"];

		[NSApp endSheet:partnerWindow returnCode:NSOKButton];
		[partnerWindow orderOut:sender];
	}
	else {
// TODO: display an error message that the name already exists
	}
}

- (IBAction)partnerCancel:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[NSApp endSheet:partnerWindow returnCode:NSCancelButton];
	[partnerWindow orderOut:sender];
}


#pragma mark Overrides

- (void)windowDidLoad
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

#if !USE_SHEET
	// center window the first time it's loaded
	if (! [self.window setFrameUsingName:@"__products"]) {
		[self.window center];
	}
#endif
	[self.window setFrameAutosaveName:@"__products"];
}

#pragma mark NSWindowDelegate

#if !USE_SHEET
- (BOOL)windowShouldClose:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	// grab any pending editing changes in the text fields
	[self.window makeFirstResponder:self.window];

	[NSApp abortModal];

	return YES;
}
#endif

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	NSUndoManager *undoManager = [managedObjectContext undoManager];
//	DebugLog(@"%s _undoStack = %@", __PRETTY_FUNCTION__, [undoManager valueForKey:@"_undoStack"]);

	return undoManager;
}

@end
