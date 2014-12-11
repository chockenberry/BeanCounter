//
//  ReconcileReportViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 11/12/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ReportViewController.h"

@interface ReconcileReportViewController : ReportViewController
{
	NSUndoManager *_savedUndoManager;
	NSUndoManager *_webViewUndoManager;
}

- (IBAction)generateReport:(id)sender;
- (IBAction)grabFormValues:(id)sender;

@end