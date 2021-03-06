//
//  RegionSalesReportViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/2/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "RegionSalesReportViewController.h"

#import "InternationalInfo.h"
#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"
#import "NSMutableDictionary+Settings.h"
#import "ICUTemplateMatcher.h"

#import "DebugLog.h"


@interface RegionSalesReportViewController ()

@end


@implementation RegionSalesReportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
	}
    
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[super dealloc];
}

- (void)awakeFromNib
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[super awakeFromNib];
}

#pragma mark - Accessors

#pragma mark - Overrides

- (NSString *)reportTemplatePath
{
	return [[NSBundle mainBundle] pathForResource:@"regionSalesReport" ofType:@"html"];
}

- (NSOperation *)reportOperation
{
	NSInteger reportCategory = [self.settings integerForKey:@"reportCategory"];
	BOOL reportShowDetails = [self.settings boolForKey:@"reportShowDetails"];
	NSDate *startDate;
	NSDate *endDate;
	[self getReportRangeUsingStartDate:&startDate endDate:&endDate];
	
	NSString *filterChoice = nil;
	if ([self filterChoiceIndex] != 0) {
		filterChoice = [self filterChoice];
	}
	
	return [[[RegionSalesReportOperation alloc] initWithPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator] withReportCategory:reportCategory andCategoryFilter:filterChoice showingDetails:reportShowDetails from:startDate to:endDate delegate:self] autorelease];
}

#pragma mark - Operation callbacks

- (void)regionSalesReportOperationCompleted:(RegionSalesReportOperation *)regionSalesReportOperation
{
	NSString *templatePath = [self reportTemplatePath];
	
	// Set up some variables for this specific template.
	NSDictionary *variables = [regionSalesReportOperation reportVariables];
	
	NSString *reportHTML = [_templateEngine processTemplateInFileAtPath:templatePath withVariables:variables];
	
	NSString *resourcesPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Resources"];
	NSURL *bundleURL = [NSURL fileURLWithPath:resourcesPath isDirectory:YES];
	WebFrame *webFrame = webView.mainFrame;
	[webFrame loadHTMLString:reportHTML baseURL:bundleURL];
	
	[self performSelector:@selector(showReport) withObject:nil afterDelay:0.0];
}

@end
