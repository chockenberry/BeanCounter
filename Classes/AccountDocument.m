//
//  AccountDocument.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/16/11.
//  Copyright The Iconfactory 2011 . All rights reserved.
//

#import "AccountDocument.h"

#import "ChartViewController.h"
#import "ProductSalesReportViewController.h"
#import "RegionSalesReportViewController.h"
#import "ProductEarningsReportViewController.h"
#import "ImportViewController.h"
#import "ReconcileViewController.h"
#import "EditProductsViewController.h"
#import "NSPersistentDocument+FileWrapperSupport.h"

#import "DebugLog.h"

static NSString *const accountFileName = @"account.db";
static NSString *const settingsFileName = @"settings.plist";

#define SHARE_WINDOW_FRAME 0

@interface AccountDocument ()

- (void)saveSettings;

- (NSURL *)storeURLFromFileURL:(NSURL *)fileURL;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper atURL:(NSURL *)baseURL error:(NSError **)error;
- (BOOL)updateFileWrapper:(NSFileWrapper*)fileWrapper atURL:(NSURL *)baseURL error:(NSError **)error;

- (void)sourceListViewChanged:(NSNotification *)notification;

@end


@implementation AccountDocument

@synthesize sourceListView, outputView;
@synthesize settings;

- (id)init 
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	self = [super init];
	if (self != nil) {
		settings = [[NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Default-Settings" ofType:@"plist"]] retain];
		
		_sourceListViewController = [[SourceListViewController alloc] initWithNibName:@"SourceListView" bundle:nil];

		_outputViewConfiguration = [[NSDictionary dictionaryWithObjectsAndKeys:
[NSDictionary dictionaryWithObjectsAndKeys:@"ProductSalesChartViewController", @"class", @"ChartView", @"nibName", nil], SourceListChartsProductsItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"RegionSalesChartViewController", @"class", @"ChartView", @"nibName", nil], SourceListChartsRegionsItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"ProductEarningsChartViewController", @"class", @"ChartView", @"nibName", nil], SourceListChartsEarningsItem,
									 
[NSDictionary dictionaryWithObjectsAndKeys:@"ProductSalesReportViewController", @"class", @"ReportView", @"nibName", nil], SourceListReportsSalesByProductItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"RegionSalesReportViewController", @"class", @"ReportView", @"nibName", nil], SourceListReportsSalesByRegionItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"ProductEarningsReportViewController", @"class", @"ReportView", @"nibName", nil], SourceListReportsEarningsByProductItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"RegionEarningsReportViewController", @"class", @"ReportView", @"nibName", nil], SourceListReportsEarningsByRegionItem,
									 
[NSDictionary dictionaryWithObjectsAndKeys:@"ImportViewController", @"class", @"ImportView", @"nibName", nil], SourceListManageImportReportsItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"ReconcileViewController", @"class", @"ReconcileView", @"nibName", nil], SourceListManageReconcileDepositsItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"EditAccountViewController", @"class", @"EditAccountView", @"nibName", nil], SourceListManageEditAccountItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"EditProductsViewController", @"class", @"EditProductsView", @"nibName", nil], SourceListManageEditProductsItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"EditGroupsViewController", @"class", @"EditGroupsView", @"nibName", nil], SourceListManageEditGroupsItem,
[NSDictionary dictionaryWithObjectsAndKeys:@"EditPartnersViewController", @"class", @"EditPartnersView", @"nibName", nil], SourceListManageEditPartnersItem,
nil] retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceListViewChanged:) name:SourceListViewChangedNotification object:_sourceListViewController];
		
//		self.managedObjectContext.retainsRegisteredObjects = YES;
	}
	
	return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[sourceListView release];
	[outputView release];

	[settings release];

	[_sourceListViewController release];
	[_outputViewController release];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

- (NSString *)windowNibName 
{
	return @"AccountDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];

	// center window the first time it's loaded
	NSWindow *window = [windowController window];
#if SHARE_WINDOW_FRAME
	if (! [window setFrameUsingName:@"__account"]) {
		[window center];
	}
	[window setFrameAutosaveName:@"__account"];
#else
	NSString *windowFrameString = [self.settings objectForKey:@"windowFrameString"];
	if (windowFrameString) {
		[window setFrameFromString:windowFrameString];
	}
	else {
		[window center];
	}
#endif

	// when the source list view gets instantiate, it will change the selection and cause the output view to be instantiated in -sourceListViewChanged:
	NSView *view = [_sourceListViewController view];
	view.frame = sourceListView.bounds;
	[sourceListView addSubview:view];
	
	NSString *selectedItem = [self.settings objectForKey:@"sourceListSelectedItem"];
	[_sourceListViewController selectItem:selectedItem];
}

#pragma mark - Utility

- (void)saveSettings
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	if (self.settings) {
		NSError *error;
		
		// give the current view controller a chance to update its copy of the settings
		if (_outputViewController) {
			[_outputViewController saveSettings];
		}
		
		// save the settings in the file wrapper
		//	NSFileWrapper *fileWrapper = [[[NSFileWrapper alloc] initWithPath:path] autorelease];
		NSFileWrapper *fileWrapper = [[[NSFileWrapper alloc] initWithURL:self.fileURL options:0 error:&error] autorelease];
		if (fileWrapper) {
#if 0
			// write out the entire file wrapper (atomically) -- takes awhile to close a document window this way
			[self updateFileWrapper:fileWrapper atURL:self.fileURL error:NULL];
			BOOL success = [fileWrapper writeToURL:self.fileURL options:NSFileWrapperWritingAtomic originalContentsURL:nil error:&error];
			if (! success) {
				ReleaseLog(@"%s Cannot write file wrapper, error = %@", __PRETTY_FUNCTION__, error);
			}
#else
			// update the file wrapper by substituting the settings file in place -- closing the document window is much faster this way
			NSFileWrapper *settingsFileWrapper = [[fileWrapper fileWrappers] objectForKey:settingsFileName];
			if (settingsFileWrapper) {
				NSData *saveSettings = [NSPropertyListSerialization dataWithPropertyList:self.settings format:NSPropertyListXMLFormat_v1_0 options:0 error:&error]; 
				if (saveSettings) {
					NSURL *settingsURL = [self.fileURL URLByAppendingPathComponent:[settingsFileWrapper filename]];
					[saveSettings writeToURL:settingsURL atomically:NO];
				}
				else {
					ReleaseLog(@"%s Cannot save settings in file wrapper, error = %@", __PRETTY_FUNCTION__, error);
				}
			}
#endif
		}
		else {
			ReleaseLog(@"%s Cannot create file wrapper, error = %@", __PRETTY_FUNCTION__, error);
		}
	}
}

#pragma mark - URL Management

//	Sets the on-disk location for the document's file.  NSPersistentDocument's implementation is bypassed using the FileWrapperSupport category.
//	The persistent store coordinator is directed to use an internal URL rather than NSPersistentDocument's default (the main file URL).

- (void)setFileURL:(NSURL *)fileURL
{	
    NSURL *originalFileURL = [self storeURLFromFileURL:fileURL];
    if (originalFileURL != nil) {
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [self.managedObjectContext persistentStoreCoordinator];
        NSPersistentStore *persistentStore = [persistentStoreCoordinator persistentStoreForURL:originalFileURL];
        if (persistentStore != nil) {
            // switch the coordinator to an internal URL
            [persistentStoreCoordinator setURL:[self storeURLFromFileURL:fileURL] forPersistentStore:persistentStore];
        }
    }
//    [self simpleSetFileURL:fileURL];
	[super setFileURL:fileURL];
}


//	Returns the URL for the wrapped Core Data store file. This appends the account file name to the document's path.

- (NSURL *)storeURLFromFileURL:(NSURL *)fileURL
{
	NSURL *result = [fileURL URLByAppendingPathComponent:accountFileName];
    if (! result) {
        result = fileURL;
    }

    return result;
}


#pragma mark - Overrides

/*
- (BOOL)setMetadataForStoreAtURL:(NSURL *)url
{
	NSPersistentStoreCoordinator *persistentStoreCoordinator = [[self managedObjectContext] persistentStoreCoordinator];
	
	NSPersistentStore *persistentStore = [persistentStoreCoordinator persistentStoreForURL:url];
	NSString *departmentName = self.department.departmentName;
	
	if ((persistentStore != nil) && (departmentName != nil))
	{
		// metadata auto-configured with NSStoreType and NSStoreUUID
		NSMutableDictionary *metadata = [[persistentStoreCoordinator metadataForPersistentStore:persistentStore]
										 mutableCopy];
		
		[metadata setObject:[NSArray arrayWithObject:departmentName]
					 forKey:(NSString *)kMDItemKeywords];
		
		[persistentStoreCoordinator setMetadata:metadata forPersistentStore:persistentStore];
		return YES;
	}
	return NO;
}
*/

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(NSString *)configuration storeOptions:(NSDictionary *)storeOptions error:(NSError **)error
{
#if 1
	// from: http://stackoverflow.com/questions/3025742/detecting-a-lightweight-core-data-migration
	{
		NSError *error = nil;
		NSPersistentStoreCoordinator *persistentStoreCoordinator = [self.managedObjectContext persistentStoreCoordinator];
		
		// determine if a migration is needed
		NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:url error:&error];
		NSManagedObjectModel *destinationModel = [persistentStoreCoordinator managedObjectModel];
		BOOL compatible = [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
		DebugLog(@"%s compatible = %ld", __PRETTY_FUNCTION__, (long)compatible);
		
		if (! compatible) {
			// determine what caused the migration
			
			NSDictionary *sourceVersionHashes = (NSDictionary *)[sourceMetadata objectForKey:@"NSStoreModelVersionHashes"];
			
			NSSet *sourceEntities = [NSSet setWithArray:[sourceVersionHashes allKeys]];
			NSSet *destinationEntities = [NSSet setWithArray:[[destinationModel entitiesByName] allKeys]];
			
			// entities that were added
			NSMutableSet *addedEntities = [NSMutableSet setWithSet:destinationEntities];
			[addedEntities minusSet:sourceEntities];
			
			// entities that were removed
			NSMutableSet *removedEntities = [NSMutableSet setWithSet:sourceEntities];
			[removedEntities minusSet:destinationEntities];
			
			// entities that were changed
			NSMutableSet *changedEntities = [NSMutableSet set];
			NSArray *destinationVersionHashes = [[destinationModel entities] valueForKey:@"versionHash"];
			for (NSString *sourceVersionHashKey in [sourceVersionHashes allKeys]) {
				NSData *sourceVersionHash = [sourceVersionHashes objectForKey:sourceVersionHashKey];
				if (! [destinationVersionHashes containsObject:sourceVersionHash]) {
					[changedEntities addObject:sourceVersionHashKey];
				}
			}

			DebugLog(@"%s addedEntities = %@, removedEntities = %@, changedEntities = %@", __PRETTY_FUNCTION__, addedEntities, removedEntities, changedEntities);
		}
	}
#endif
	
	// from: http://homepage.mac.com/mmalc/CocoaExamples/controllers.html
	// If your application uses the same file extension for all versions, then you can just add the NSMigratePersistentStoresAutomaticallyOption to the options dictionary. If the file being opened is an old version, it will be automatically updated in situ and the old version moved to <filename>.extension~
	NSMutableDictionary *newStoreOptions;
	if (storeOptions == nil) {
		newStoreOptions = [NSMutableDictionary dictionary];
	}
	else {
		newStoreOptions = [NSMutableDictionary dictionaryWithDictionary:storeOptions];
	}
	[newStoreOptions setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
	[newStoreOptions setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
	
	BOOL result = [super configurePersistentStoreCoordinatorForURL:url ofType:fileType modelConfiguration:configuration storeOptions:newStoreOptions error:error];

	/*
	if (result == YES) {
		[self setMetadataForStoreAtURL:url];
	}
	*/
	
	return result;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper atURL:(NSURL *)baseURL error:(NSError **)error
{
	NSFileWrapper *settingsFile = [[fileWrapper fileWrappers] objectForKey:settingsFileName];
	
	if (settingsFile) {
		// merge contents of file into default settings (picking up any new defaults)
		NSURL *settingsURL = [baseURL URLByAppendingPathComponent:[settingsFile filename]];
		NSDictionary *accountSettings = [NSDictionary dictionaryWithContentsOfURL:settingsURL];
		if (accountSettings) {
			[self.settings addEntriesFromDictionary:accountSettings];
		}
	}	
	else {
		self.settings = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Default-Settings" ofType:@"plist"]];
	}
	
	return YES;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)error
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	BOOL result = NO;
	
	NSFileWrapper *directoryFileWrapper = [[[NSFileWrapper alloc] initWithURL:absoluteURL options:0 error:NULL] autorelease];
	NSFileWrapper *accountFileWrapper = [[directoryFileWrapper fileWrappers] objectForKey:accountFileName];
	if (accountFileWrapper) {
		NSURL *accountFileURL = [absoluteURL URLByAppendingPathComponent:[accountFileWrapper filename]];
		result = [self configurePersistentStoreCoordinatorForURL:accountFileURL ofType:typeName modelConfiguration:nil storeOptions:nil error:error];
	}

	if (result == YES) {
		 result = [self readFromFileWrapper:directoryFileWrapper atURL:absoluteURL error:error];
	}
	
	return result;
}

- (BOOL)updateFileWrapper:(NSFileWrapper *)documentFileWrapper atURL:(NSURL *)baseURL error:(NSError **)error
{
	BOOL result = NO;
	
	NSFileWrapper *settingsFileWrapper = [[documentFileWrapper fileWrappers] objectForKey:settingsFileName];
	if (settingsFileWrapper) {
		[documentFileWrapper removeFileWrapper:settingsFileWrapper];
	}

	if (self.settings) {
		NSData *saveSettings = [NSPropertyListSerialization dataWithPropertyList:self.settings format:NSPropertyListXMLFormat_v1_0 options:0 error:error]; 
		if (saveSettings) {
			settingsFileWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:saveSettings] autorelease];
			[settingsFileWrapper setPreferredFilename:settingsFileName];
			[documentFileWrapper addFileWrapper:settingsFileWrapper];
			
			result = YES;
		}
	}
	
	return result;
}

- (BOOL)writeSafelyToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)error
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	BOOL result = YES;
	NSFileWrapper *fileWrapper = nil;
	NSURL *originalURL = self.fileURL;
	NSString *persistentStoreType = [self persistentStoreTypeForFileType:typeName];
	
	if (saveOperation == NSSaveAsOperation) {
		// saving as a new document, first setup the directory
		fileWrapper = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}] autorelease];
		BOOL success = [fileWrapper writeToURL:absoluteURL options:NSFileWrapperWritingAtomic originalContentsURL:nil error:error];
		if (! success) {
			ReleaseLog(@"%s Cannot write file wrapper for directory, error = %@", __PRETTY_FUNCTION__, *error);
			result = NO;
		}
		else {
			// now migrage the persistent store
			NSURL *newStoreURL = [self storeURLFromFileURL:absoluteURL];
			NSURL *originalStoreURL = [self storeURLFromFileURL:originalURL];
			
			if (originalStoreURL) {
				// migrate an existing persistent store to a new location (for "Save As…")
				NSPersistentStoreCoordinator *persistentStoreCoordinator = [self.managedObjectContext persistentStoreCoordinator];
				NSPersistentStore *originalPeristentStore = [persistentStoreCoordinator persistentStoreForURL:originalStoreURL];
				NSPersistentStore *newPersistentStore = [persistentStoreCoordinator migratePersistentStore:originalPeristentStore toURL:newStoreURL options:nil withType:persistentStoreType error:error];
				if (! newPersistentStore) {
					result = NO;
				}
			}
			else {
				// first save of a new persistent store (a new file will be created)
				result = [self configurePersistentStoreCoordinatorForURL:newStoreURL ofType:typeName modelConfiguration:nil storeOptions:nil error:error];
			}

			// now that the persistent store has been created in the directory, add it to the file wrapper
			NSFileWrapper *newStoreFileWrapper = [[[NSFileWrapper alloc] initWithURL:newStoreURL options:0 error:error] autorelease];
			if (! newStoreFileWrapper) {
				result = NO;
			}
			else {
				[fileWrapper addFileWrapper:newStoreFileWrapper];
			}
		}
	}
	else {
		// not saving a new document, just create the file wrapper

		/*
		//  needed  -- configure not called for writing existing document
		if ([self fileURL] != nil)
		{
			[self setMetadataForStoreAtURL:self.fileURL];
		}
		 */
		
		fileWrapper = [[[NSFileWrapper alloc] initWithURL:absoluteURL options:0 error:error] autorelease];
		if (! fileWrapper) {
			ReleaseLog(@"%s Cannot write file wrapper, error = %@", __PRETTY_FUNCTION__, *error);
			result = NO;
		}
	}

	if (result) {
		// save the persistent store in the file wrapper
		result = [[self managedObjectContext] save:error];
	}
	
	
	if (result) {
		// update the file wrapper (writing data other than the persistent store)
		[self updateFileWrapper:fileWrapper atURL:absoluteURL error:NULL];
		BOOL success = [fileWrapper writeToURL:absoluteURL options:NSFileWrapperWritingAtomic originalContentsURL:absoluteURL error:error];
		if (! success) {
			ReleaseLog(@"%s Cannot write file wrapper for directory, error = %@", __PRETTY_FUNCTION__, *error);
			result = NO;
		}
	}
	
	if (result) {
        // set the appropriate file attributes (such as hiding the file extension)
        NSDictionary *fileAttributes = [self fileAttributesToWriteToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:originalURL error:NULL];
        [[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:[absoluteURL path] error:NULL];
    }

	return result;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)error
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[self managedObjectContext] persistentStoreCoordinator];
    NSPersistentStore *persistentStore = [persistentStoreCoordinator persistentStoreForURL:[self storeURLFromFileURL:absoluteURL]];
    if (persistentStore) {
        [persistentStoreCoordinator removePersistentStore:persistentStore error:error];
    }
	
	BOOL result = [super revertToContentsOfURL:absoluteURL ofType:typeName error:error];
	if (result) {
		// the selection change notification doesn't fire when the document is reverted, this is a workaround
		[self sourceListViewChanged:nil];
	}
	
	return result;
}

#pragma mark - Actions

- (void)printOperationDidRun:(NSPrintOperation *)printOperation success:(BOOL)success contextInfo:(void *)info
{
	DebugLog(@"%s success = %ld", __PRETTY_FUNCTION__, (long)success);
	if (success) {
		self.printInfo = [printOperation printInfo];
	}
}

- (IBAction)printDocument:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSPrintInfo *printInfo = self.printInfo;
	
	NSSize paperSize = [printInfo paperSize];
	NSRect imageablePageBounds = [printInfo imageablePageBounds];
	
	// calculate page margins
	CGFloat marginLeft = imageablePageBounds.origin.x;
	CGFloat marginRight = paperSize.width - (imageablePageBounds.origin.x + imageablePageBounds.size.width);
	CGFloat marginBottom = imageablePageBounds.origin.y;
	CGFloat marginTop = paperSize.height - (imageablePageBounds.origin.y + imageablePageBounds.size.height);
	
	// make sure margins are symetric and positive
	CGFloat marginHorizontal = MAX(0, MAX(marginLeft, marginRight));
	CGFloat marginVertical = MAX(0, MAX(marginTop, marginBottom));
	
	// set margins
	[printInfo setLeftMargin:marginHorizontal];
	[printInfo setRightMargin:marginHorizontal];
	[printInfo setTopMargin:marginVertical];
	[printInfo setBottomMargin:marginVertical];

	NSPrintOperation *printOperation = [_outputViewController printOperationWithPrintInfo:printInfo];
	[printOperation runOperationModalForWindow:[outputView window] delegate:self didRunSelector:@selector(printOperationDidRun:success:contextInfo:) contextInfo:NULL];
}

#pragma mark - Notifications

- (void)sourceListViewChanged:(NSNotification *)notification
{
	id selectedItem = [_sourceListViewController selectedItem];

	if (selectedItem) {
		[self.settings setObject:selectedItem forKey:@"sourceListSelectedItem"];
	}
	else {
		[self.settings removeObjectForKey:@"sourceListSelectedItem"];
	}
	DebugLog(@"%s selectedItem = %@", __PRETTY_FUNCTION__, selectedItem);
	
	// give the current view controller a chance to save its settings
	[_outputViewController saveSettings];

	NSWindow *window = [outputView window];
	[window makeFirstResponder:nil];
	
	// remove the old view and controller
	NSView *oldView = [_outputViewController view];
	[oldView setNextResponder:nil];
	[oldView removeFromSuperview];
	[_outputViewController setNextResponder:nil];
	[_outputViewController release], _outputViewController = nil;

	// create and configure a new view controller
	NSDictionary *viewConfiguration = [_outputViewConfiguration objectForKey:selectedItem];
	if (viewConfiguration) {
		Class class = NSClassFromString([viewConfiguration objectForKey:@"class"]);
		_outputViewController = [[class alloc] initWithNibName:[viewConfiguration objectForKey:@"nibName"] bundle:nil];
	}
	_outputViewController.managedObjectModel = self.managedObjectModel;
	_outputViewController.managedObjectContext = self.managedObjectContext;
	_outputViewController.settings = self.settings;
	[_outputViewController setNextResponder:outputView];
	
	// add the new controller's view into the view and responder chain hierarchy
	NSView *view = [_outputViewController view];
	view.frame = outputView.bounds;
	[outputView addSubview:view];
	[view setNextResponder:_outputViewController];

#if 0
	// make the new view controller the first responder (after giving NIB loading a chance to finish)
	[[view window] performSelector:@selector(makeFirstResponder:) withObject:_outputViewController afterDelay:0.0];
#else
	[[view window] makeFirstResponder:_outputViewController];
#endif
	
	// update the view's data
	[_outputViewController generateOutput];
}

#pragma mark - NSWindowDelegate

#if !SHARE_WINDOW_FRAME

- (void)windowWillClose:(NSNotification *)notification
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	NSWindow *window = nil;
	NSArray *windowControllers = self.windowControllers;
	if (windowControllers && [windowControllers count] > 0) {
		NSWindowController *windowController = [windowControllers lastObject];
		window = [windowController window];
	}
	if (window) {
		NSString *windowFrameString = [window stringWithSavedFrame];
		[self.settings setObject:windowFrameString forKey:@"windowFrameString"];
	}

	[self saveSettings];
}

#endif

@end
