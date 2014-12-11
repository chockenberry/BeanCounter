//
//  TableViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/2/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <WebKit/WebKit.h>


@interface TableViewController : NSViewController
{
	NSNumberFormatter *_unitsFormatter;
	NSNumberFormatter *_salesFormatter;
	NSNumberFormatter *_percentFormatter;

	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;

	WebView *webView;
}

@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet WebView *webView;

- (IBAction)generateReport:(id)sender;
- (IBAction)grabFormValues:(id)sender;

@end
