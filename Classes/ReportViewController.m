//
//  ReportViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/2/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ReportViewController.h"

#import "InternationalInfo.h"
#import "NSMutableDictionary+Settings.h"
#import "ICUTemplateMatcher.h"

#import "DebugLog.h"


@interface ReportViewController ()

- (NSInteger)filterChoiceIndex;
- (void)updateFilterPopUpButton;

@end


@implementation ReportViewController

@synthesize progressIndicator;
@synthesize webView;
@synthesize filterPopUpButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		_templateEngine = [[MGTemplateEngine templateEngine] retain];
		[_templateEngine setDelegate:self];
		[_templateEngine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:_templateEngine]];

		/*
		_unitsFormatter = [[NSNumberFormatter alloc] init];
		_unitsFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		
		_salesFormatter = [[NSNumberFormatter alloc] init];
		_salesFormatter.numberStyle = NSNumberFormatterCurrencyStyle;

		_percentFormatter = [[NSNumberFormatter alloc] init];
		_percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
		_percentFormatter.minimumFractionDigits = 1;
		
		_dateFormatter = [[NSDateFormatter alloc] init];
		_dateFormatter.dateFormat = @"MMMM yyyy";
		 */
		
//		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.reportCategory" options:0 context:NULL];
	}
    
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	if (_operation) {
		[_operation cancel];
		[_operation release], _operation = nil;
	}

	//	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.reportCategory"];
	[settings removeObserver:self forKeyPath:@"reportCategory"];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	/*
	[_unitsFormatter release], _unitsFormatter = nil;
	[_salesFormatter release], _salesFormatter = nil;
	[_percentFormatter release], _percentFormatter = nil;
	 */
	
	[webView close];
	[webView release], webView = nil;
	
	[super dealloc];
}

- (void)awakeFromNib
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[self updateFilterPopUpButton];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	DebugLog(@"%s keyPath = %@, object = %@", __PRETTY_FUNCTION__, keyPath, object);
	
//	if ([keyPath isEqualToString:@"values.reportCategory"]) {
	if ([keyPath isEqualToString:@"reportCategory"]) {
		[self willChangeValueForKey:@"filterChoices"];
		[self didChangeValueForKey:@"filterChoices"];
		
		[self updateFilterPopUpButton];
	}
}

#pragma mark - Accessors

- (void)setSettings:(NSMutableDictionary *)newSettings
{
	if (newSettings != settings) {
		[settings removeObserver:self forKeyPath:@"reportCategory"];
		
		[settings release];
		settings = [newSettings retain];
		
		[settings addObserver:self forKeyPath:@"reportCategory" options:0 context:NULL];
	}
}

- (NSArray *)filterChoices
{
	NSArray *result = nil;
	
	NSInteger reportCategory = [self.settings integerForKey:@"reportCategory"];
	switch (reportCategory) {
		default:
		case 0:
			{
				NSMutableArray *choices = [NSMutableArray array];
				[choices addObject:[NSDictionary dictionaryWithObject:@"All" forKey:@"name"]];
				[choices addObjectsFromArray:[Product fetchAllInManagedObjectContext:managedObjectContext]];
				result = [NSArray arrayWithArray:choices];
			}
			break;
		case 1:
			{
				NSMutableArray *choices = [NSMutableArray array];
				[choices addObject:[NSDictionary dictionaryWithObject:@"All" forKey:@"name"]];
				[choices addObjectsFromArray:[Group fetchAllInManagedObjectContext:managedObjectContext]];
				[choices addObject:[NSDictionary dictionaryWithObject:@"No Product Group" forKey:@"name"]];
				result = [NSArray arrayWithArray:choices];
			}
			break;
		case 2:
		{
			NSMutableArray *choices = [NSMutableArray array];
			[choices addObject:[NSDictionary dictionaryWithObject:@"All" forKey:@"name"]];
			[choices addObjectsFromArray:[Partner fetchAllInManagedObjectContext:managedObjectContext]];
			[choices addObject:[NSDictionary dictionaryWithObject:@"No Partner" forKey:@"name"]];
			result = [NSArray arrayWithArray:choices];
		}
			break;
	}
	
	return result;
}

- (NSInteger)filterChoiceIndex
{
	NSInteger reportCategory = [self.settings integerForKey:@"reportCategory"];
	NSInteger result;
	switch (reportCategory) {
		default:
		case 0:
			result = [self.settings integerForKey:@"reportFilterProducts"];
			if (result > [[Product fetchAllInManagedObjectContext:managedObjectContext] count]) {
				result = 0;
			}
			break;
		case 1:
			result = [self.settings integerForKey:@"reportFilterGroup"];
			if (result > ([[Group fetchAllInManagedObjectContext:managedObjectContext] count] + 1)) {
				result = 0;
			}
			break;
		case 2:
			result = [self.settings integerForKey:@"reportFilterPartner"];
			if (result > ([[Partner fetchAllInManagedObjectContext:managedObjectContext] count] + 1)) {
				result = 0;
			}
			break;
	}
	
	return result;
}

- (NSString *)filterChoice
{
	NSString *result = nil;
	
	NSInteger index = [self filterChoiceIndex];
	NSArray *filterChoices = [self filterChoices];
	BOOL lastChoice = (index == ([filterChoices count] - 1));
	id filterChoice = [filterChoices objectAtIndex:index];
	
	NSInteger chartCategory = [self.settings integerForKey:@"reportCategory"];
	switch (chartCategory) {
		default:
		case 0:
			result = [filterChoice vendorId];
			break;
		case 1:
			if (lastChoice) {
				result = @"__NONE__";
			}
			else {
				result = [filterChoice groupId];
			}
			break;
		case 2:
			if (lastChoice) {
				result = @"__NONE__";
			}
			else {
				result = [filterChoice partnerId];
			}
			break;
	}
	
	return result;
}

- (NSArray *)yearChoices
{
	NSDate *date = [NSDate date];
	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear) fromDate:date];
	
	NSUInteger startYear = 2008;
	if ([self.settings integerForKey:@"accountEarningsStart"] == 0) {
		startYear = 2010;
	}
	
	NSMutableArray *result = [NSMutableArray array];
	for (NSUInteger year = startYear; year <= dateComponents.year; year++) {
		[result addObject:[NSNumber numberWithInteger:year]];
	}
	
	return result;
}

#pragma mark - Overrides

- (NSString *)reportTemplatePath
{
	return nil;
}

- (NSOperation *)reportOperation
{
	return nil;
}

#pragma mark - Methods

- (void)generateOutput
{
	[self generateReport];
}

- (NSPrintOperation *)printOperationWithPrintInfo:(NSPrintInfo *)printInfo
{
	return [[[webView mainFrame] frameView] printOperationWithPrintInfo:printInfo];
}

- (void)showReport
{
	[progressIndicator stopAnimation:self];
#if 1
	[webView setHidden:NO];
	[webView setNeedsDisplay:YES];
#else
	// turn on the viewWantsLayer for the webView and this kinda works, but it feels clunky
	NSMutableDictionary *viewDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[viewDictionary setObject:webView forKey:NSViewAnimationTargetKey];
	[viewDictionary setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
	
	NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:viewDictionary]];
	[animation setDuration:0.25];
	[animation setAnimationCurve:NSAnimationEaseInOut];
	[animation startAnimation];
	[animation release];
#endif
	
	if (_operation) {
		[_operation release], _operation = nil;
	}
}

- (void)generateReport
{
	[progressIndicator startAnimation:self];
#if 1
	[webView setHidden:YES];
	[webView setNeedsDisplay:YES];
#else
	NSMutableDictionary *viewDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[viewDictionary setObject:webView forKey:NSViewAnimationTargetKey];
	[viewDictionary setObject:NSViewAnimationFadeOutEffect forKey:NSViewAnimationEffectKey];
	
	NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:viewDictionary]];
	[animation setDuration:0.25];
	[animation setAnimationCurve:NSAnimationEaseInOut];
	[animation startAnimation];
	[animation release];
#endif
	
	if (_operation) {
		[_operation cancel];
		[_operation release], _operation = nil;
	}
	_operation = [[self reportOperation] retain];
	if (_operation) {
		NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
		[operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
		[operationQueue addOperation:_operation];
		[operationQueue release];
	}
}

#pragma mark -

- (void)updateFilterPopUpButton
{
	NSInteger selectedItem = [self filterChoiceIndex];
	[filterPopUpButton selectItemAtIndex:selectedItem];
}

#pragma mark - Actions

- (IBAction)generateReport:(id)sender
{
	[self generateReport];
}

- (IBAction)chooseFilter:(id)sender
{
	DebugLog(@"%s filter = %@", __PRETTY_FUNCTION__, [(NSPopUpButton *)sender titleOfSelectedItem]);

	NSInteger selectedItem = [filterPopUpButton indexOfSelectedItem];
	
	NSInteger reportCategory = [self.settings integerForKey:@"reportCategory"];
	switch (reportCategory) {
		default:
		case 0:
			[self.settings setInteger:selectedItem forKey:@"reportFilterProducts"];
			break;
		case 1:
			[self.settings setInteger:selectedItem forKey:@"reportFilterGroup"];
			break;
		case 2:
			[self.settings setInteger:selectedItem forKey:@"reportFilterPartner"];
			break;
	}

	[self generateReport];
}

#pragma mark - Utility (Private)

- (void)getReportRangeUsingStartDate:(NSDate **)startDate endDate:(NSDate **)endDate
{
	NSUInteger reportPeriod = [self.settings integerForKey:@"reportPeriod"];
	NSUInteger reportMonth = [self.settings integerForKey:@"reportMonth"];
	NSUInteger reportYear = [self.settings integerForKey:@"reportYear"];
	
	NSDateComponents *startDateComponents = [[[NSDateComponents alloc] init] autorelease];
	NSDateComponents *endDateComponents = [[[NSDateComponents alloc] init] autorelease];
	
	switch (reportPeriod) {
		default:
		case 0:
			// month
			startDateComponents.year = reportYear;
			startDateComponents.month = reportMonth;
			startDateComponents.day = 1;
			
			endDateComponents.month = 1;
			break;
		case 1:
			// quarter
			startDateComponents.year = reportYear;
			startDateComponents.month = (((reportMonth - 1) / 3) * 3) + 1; // compute first month of quarter
			startDateComponents.day = 1;
			
			endDateComponents.month = 3;
			break;
		case 2:
			// year
			startDateComponents.year = reportYear;
			startDateComponents.month = 1;
			startDateComponents.day = 1;
			
			endDateComponents.month = 12;
			break;
		case 3:
			// all
			startDateComponents.year = 2008;
			startDateComponents.month = 1;
			startDateComponents.day = 1;
			
			NSDate *today = [NSDate date];
			NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
			NSDateComponents *dateComponents = [gregorianCalendar components:NSCalendarUnitYear fromDate:today];
			NSInteger year = [dateComponents year];
			
			endDateComponents.year = year - 2008 + 1;
			break;
	}
	endDateComponents.second = -1; // the range does not include the exact end date

	*startDate = [[NSCalendar currentCalendar] dateFromComponents:startDateComponents];
	*endDate = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:*startDate options:0];
}

#pragma mark - MGTemplateEngineDelegate

- (void)templateEngine:(MGTemplateEngine *)engine encounteredError:(NSError *)error isContinuing:(BOOL)continuing;
{
	ReleaseLog(@"%s Template error: %@", __PRETTY_FUNCTION__, error);
}


@end
