//
//  RegionEarningsReportViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/2/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "RegionEarningsReportViewController.h"

#import "InternationalInfo.h"
#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"
#import "NSMutableDictionary+Settings.h"
#import "ICUTemplateMatcher.h"

#import "DebugLog.h"


@interface RegionEarningsReportViewController ()

@end


@implementation RegionEarningsReportViewController

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

- (BOOL)usesAllControls
{
	return NO;
}


- (NSString *)reportTemplatePath
{
	return [[NSBundle mainBundle] pathForResource:@"regionEarningsReport" ofType:@"html"];
}

- (NSOperation *)reportOperation
{
	NSInteger reportCategory = [self.settings integerForKey:@"reportCategory"];
	BOOL reportShowDetails = [self.settings boolForKey:@"reportShowDetails"];
#if 0
	NSDate *startDate;
	NSDate *endDate;
	[self getReportRangeUsingStartDate:&startDate endDate:&endDate];
#else
	NSUInteger reportMonth = [self.settings integerForKey:@"reportMonth"];
	NSUInteger reportYear = [self.settings integerForKey:@"reportYear"];
	
	NSDateComponents *startDateComponents = [[[NSDateComponents alloc] init] autorelease];
	startDateComponents.year = reportYear;
	startDateComponents.month = reportMonth;
	startDateComponents.day = 1;
	
	NSDateComponents *endDateComponents = [[[NSDateComponents alloc] init] autorelease];
	endDateComponents.month = 1;
	endDateComponents.second = -1; // the range does not include the exact end date
	
	NSDate *startDate = [[NSCalendar currentCalendar] dateFromComponents:startDateComponents];
	NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:startDate options:0];
#endif
	
	NSString *filterChoice = nil;
	
	return [[[RegionEarningsReportOperation alloc] initWithPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator] withReportCategory:reportCategory andCategoryFilter:filterChoice showingDetails:reportShowDetails from:startDate to:endDate delegate:self] autorelease];
}

#pragma mark - Operation callbacks

- (void)regionEarningsReportOperationCompleted:(RegionEarningsReportOperation *)regionEarningsReportOperation
{
	NSString *templatePath = [self reportTemplatePath];
	
	// Set up some variables for this specific template.
	NSDictionary *variables = [regionEarningsReportOperation reportVariables];
	
	NSString *reportHTML = [_templateEngine processTemplateInFileAtPath:templatePath withVariables:variables];
	
	NSString *resourcesPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Resources"];
	NSURL *bundleURL = [NSURL fileURLWithPath:resourcesPath isDirectory:YES];
	WebFrame *webFrame = webView.mainFrame;
	[webFrame loadHTMLString:reportHTML baseURL:bundleURL];
	
	[self performSelector:@selector(showReport) withObject:nil afterDelay:0.0];
}

@end
