//
//  ReconcileReportViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/2/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ReconcileReportViewController.h"

#import "InternationalInfo.h"
#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"

#import "ICUTemplateMatcher.h"

#import "DebugLog.h"


@interface ReconcileReportViewController ()

- (NSArray *)salesInRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

@end


@implementation ReconcileReportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
#if 0
		_webViewUndoManager = [[NSUndoManager alloc] init];
#endif
	}
    
    return self;
}

#if 1
- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	NSUndoManager *undoManager = [managedObjectContext undoManager];
//	[undoManager removeAllActionsWithTarget:webView];
//	[_webViewUndoManager removeAllActions];

#if 0
	if ([webView respondsToSelector:@selector(_clearUndoRedoOperations)]) {
		[webView performSelector:@selector(_clearUndoRedoOperations)];
	}
#endif
	
	//[webView setEditingDelegate:nil];

//	[undoManager endUndoGrouping];
//	[undoManager setActionName:@"Reconcile"];

#if 0
	[_webViewUndoManager release], _webViewUndoManager = nil;
	
	[managedObjectContext setUndoManager:_savedUndoManager];
	[_savedUndoManager release];
#endif
	
	[super dealloc];
}
#else
#warning "MEMORY LEAK ON PURPOSE DUH"
#endif

- (void)awakeFromNib
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[webView setEditingDelegate:self];
}

#pragma mark - Accessors

#if 1
- (void)setManagedObjectContext:(NSManagedObjectContext *)newManagedObjectContext
{
//	[_savedUndoManager release];
//	_savedUndoManager = [[managedObjectContext undoManager] retain];
	
	[super setManagedObjectContext:newManagedObjectContext];

//	[managedObjectContext setUndoManager:_webViewUndoManager];

	NSUndoManager *undoManager = [managedObjectContext undoManager];
//	[undoManager setGroupsByEvent:NO];
//	[undoManager beginUndoGrouping];
}
#endif

#pragma mark - Overrides

- (NSString *)reportTemplatePath
{
	return [[NSBundle mainBundle] pathForResource:@"reportForReconcile" ofType:@"html"];
}

- (NSDictionary *)reportVariables
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSUInteger reconcileReportMonth = [userDefaults integerForKey:@"reconcileReportMonth"];
	NSUInteger reconcileReportYear = [userDefaults integerForKey:@"reconcileReportYear"];
	
	NSDateComponents *startDateComponents = [[[NSDateComponents alloc] init] autorelease];
	startDateComponents.year = reconcileReportYear;
	startDateComponents.month = reconcileReportMonth;
	startDateComponents.day = 1;
	NSDate *startDate = [[NSCalendar currentCalendar] dateFromComponents:startDateComponents];
	
	NSDateComponents *endDateComponents = [[[NSDateComponents alloc] init] autorelease];
	endDateComponents.month = 1;
	NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:startDate options:0];
	
	NSFetchRequest *allRegionsFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"allRegions" substitutionVariables:[NSDictionary dictionary]];
	allRegionsFetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]];
	NSArray *allRegions = [managedObjectContext executeFetchRequest:allRegionsFetchRequest error:NULL];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	dateFormatter.dateStyle = NSDateFormatterLongStyle;
	NSString *reportTitle = [NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:startDate], [dateFormatter stringFromDate:endDate]];
	
	float totalDeposit = 0.0;
	NSMutableArray *regionArray = [NSMutableArray array];
	for (Region *region in allRegions) {
		NSMutableDictionary *regionDictionary = nil;
		NSArray *sales = [self salesInRegion:region startDate:startDate endDate:endDate];
		if ([sales count] > 0) {
			regionDictionary = [NSMutableDictionary dictionary];
			[regionDictionary setObject:region forKey:@"region"];
			
			NSNumber *salesSum = [sales valueForKeyPath:@"@sum.total"];
			
			InternationalInfo *internationalInfoManager = [InternationalInfo sharedInternationalInfo];
			_salesFormatter.currencySymbol = [internationalInfoManager regionCurrencySymbolForId:region.id];
			_salesFormatter.maximumFractionDigits = [internationalInfoManager regionCurrencyDigitsForId:region.id];
			_salesFormatter.minimumFractionDigits = [internationalInfoManager regionCurrencyDigitsForId:region.id];
			
			NSString *salesSummary = [_salesFormatter stringFromNumber:salesSum];
			[regionDictionary setObject:salesSummary forKey:@"salesSummary"];
			
			NSString *earningDepositFormatted = @"";
			{
				NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
										   startDate, @"date",
										   region.id, @"regionId",
										   nil];
				NSFetchRequest *existingEarningFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingEarning" substitutionVariables:variables];
				NSArray *existingEarnings = [managedObjectContext executeFetchRequest:existingEarningFetchRequest error:NULL];
				if ([existingEarnings count] > 0) {
					// use existing earning
					Earning *earning = [existingEarnings lastObject];
					
					_salesFormatter.currencySymbol = @"";
					_salesFormatter.maximumFractionDigits = 2;
					_salesFormatter.minimumFractionDigits = 2;
					earningDepositFormatted = [_salesFormatter stringFromNumber:earning.deposit];

					totalDeposit = totalDeposit + [earning.deposit floatValue];
				}
			}
			[regionDictionary setObject:earningDepositFormatted forKey:@"earningDeposit"];

			[regionArray addObject:regionDictionary];
		}
	}
	
	_salesFormatter.currencySymbol = @"";
	_salesFormatter.maximumFractionDigits = 2;
	_salesFormatter.minimumFractionDigits = 2;
	NSString *totalDepositFormatted = [_salesFormatter stringFromNumber:[NSNumber numberWithFloat:totalDeposit]];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			reportTitle, @"reportTitle",
			regionArray, @"regionArray",
			totalDepositFormatted, @"totalDeposit",
			@"$", @"depositCurrencySymbol",
			nil];
}

#if 0
- (void)managedObjectContextChanged:(NSNotification *)notification
{
#if 0
	NSDictionary *userInfo = [notification userInfo];
	DebugLog(@"%s inserted = %@, updated = %@, deleted = %@", __PRETTY_FUNCTION__, [userInfo objectForKey:NSInsertedObjectsKey], [userInfo objectForKey:NSUpdatedObjectsKey], [userInfo objectForKey:NSDeletedObjectsKey]);
#endif

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSUInteger reconcileReportMonth = [userDefaults integerForKey:@"reconcileReportMonth"];
	NSUInteger reconcileReportYear = [userDefaults integerForKey:@"reconcileReportYear"];
	
	NSDateComponents *startDateComponents = [[[NSDateComponents alloc] init] autorelease];
	startDateComponents.year = reconcileReportYear;
	startDateComponents.month = reconcileReportMonth;
	startDateComponents.day = 1;
	NSDate *startDate = [[NSCalendar currentCalendar] dateFromComponents:startDateComponents];
	
	NSDateComponents *endDateComponents = [[[NSDateComponents alloc] init] autorelease];
	endDateComponents.month = 1;
	NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:startDate options:0];
	
	NSFetchRequest *allRegionsFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"allRegions" substitutionVariables:[NSDictionary dictionary]];
	allRegionsFetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]];
	NSArray *allRegions = [managedObjectContext executeFetchRequest:allRegionsFetchRequest error:NULL];
	
	for (Region *region in allRegions) {
		NSString *earningDepositFormatted = @"";
		{
			NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
									   startDate, @"date",
									   region.id, @"regionId",
									   nil];
			NSFetchRequest *existingEarningFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingEarning" substitutionVariables:variables];
			NSArray *existingEarnings = [managedObjectContext executeFetchRequest:existingEarningFetchRequest error:NULL];
			if ([existingEarnings count] > 0) {
				// use existing earning
				Earning *earning = [existingEarnings lastObject];
				
				_salesFormatter.currencySymbol = @"";
				_salesFormatter.maximumFractionDigits = 2;
				_salesFormatter.minimumFractionDigits = 2;
				earningDepositFormatted = [_salesFormatter stringFromNumber:earning.deposit];
				
				NSString *javaScriptString = [NSString stringWithFormat:@"document.getElementById('%@_deposit').value = '%@';", region.id, earningDepositFormatted];
				[webView stringByEvaluatingJavaScriptFromString:javaScriptString];
				
				DebugLog(@"%s updated %@ to %@", __PRETTY_FUNCTION__, region.id, earningDepositFormatted);
			}
		}
	}
}
#endif

#pragma mark - Utility

- (NSArray *)salesInRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
			region.id, @"regionId",
			startDate, @"startDate",
			endDate, @"endDate",
			nil];
	NSFetchRequest *salesInRegionWithRangeFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"salesInRegionWithRange" substitutionVariables:variables];
	salesInRegionWithRangeFetchRequest.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"country" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"amount" ascending:NO], nil];
	NSArray *salesInRegionWithRange = [managedObjectContext executeFetchRequest:salesInRegionWithRangeFetchRequest error:NULL];

	return salesInRegionWithRange;
}

#pragma mark - Actions

- (IBAction)generateReport:(id)sender
{
	[self generateReport];
}

- (IBAction)grabFormValues:(id)sender
{
	
}

#pragma mark - WebViewEditingDelegate


- (void)webViewDidBeginEditing:(NSNotification *)notification
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

- (void)webViewDidEndEditing:(NSNotification *)notification
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

- (BOOL)webView:(WebView *)webView shouldBeginEditingInDOMRange:(DOMRange *)range
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	return YES;
}

- (BOOL)webView:(WebView *)webView shouldInsertText:(NSString *)text replacingDOMRange:(DOMRange *)range givenAction:(WebViewInsertAction)action
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	/*
	 NSUndoManager *undoManager = [managedObjectContext undoManager];
	 
	 [undoManager setGroupsByEvent:NO];
	 [undoManager beginUndoGrouping];
	 */
	return YES;
}

- (void)webViewDidChange:(NSNotification *)notification
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSUInteger reconcileReportMonth = [userDefaults integerForKey:@"reconcileReportMonth"];
	NSUInteger reconcileReportYear = [userDefaults integerForKey:@"reconcileReportYear"];
	
	NSDateComponents *startDateComponents = [[[NSDateComponents alloc] init] autorelease];
	startDateComponents.year = reconcileReportYear;
	startDateComponents.month = reconcileReportMonth;
	startDateComponents.day = 1;
	NSDate *startDate = [[NSCalendar currentCalendar] dateFromComponents:startDateComponents];
	
	NSDateComponents *endDateComponents = [[[NSDateComponents alloc] init] autorelease];
	endDateComponents.month = 1;
	NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:startDate options:0];
	
	NSFetchRequest *allRegionsFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"allRegions" substitutionVariables:[NSDictionary dictionary]];
	allRegionsFetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]];
	NSArray *allRegions = [managedObjectContext executeFetchRequest:allRegionsFetchRequest error:NULL];
	
	float totalDeposit = 0.0;
	for (Region *region in allRegions) {
		NSArray *sales = [self salesInRegion:region startDate:startDate endDate:endDate];
		if ([sales count] > 0) {
			NSString *javaScriptString = [NSString stringWithFormat:@"document.getElementById('%@_deposit').value;", region.id];
			NSString *value = [webView stringByEvaluatingJavaScriptFromString:javaScriptString];
			NSString *cleanValue = [value stringByReplacingOccurrencesOfString:@"," withString:@""];
			float deposit = [cleanValue floatValue];
			totalDeposit = totalDeposit + deposit;
			NSLog(@"%s %@ = %@", __PRETTY_FUNCTION__, region.id, value);

			NSUndoManager *undoManager = [managedObjectContext undoManager];
#if 1
			[undoManager disableUndoRegistration];
#else
			[undoManager beginUndoGrouping];
#endif
			
			Earning *earning = nil;
			{
				NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
										   startDate, @"date",
										   region.id, @"regionId",
										   nil];
				NSFetchRequest *existingEarningFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingEarning" substitutionVariables:variables];
				NSArray *existingEarnings = [managedObjectContext executeFetchRequest:existingEarningFetchRequest error:NULL];
				if ([existingEarnings count] > 0) {
					// use existing earning
					earning = [existingEarnings lastObject];
					//DebugLog(@"%s using earning %@", __PRETTY_FUNCTION__, earning);
				}
				else {
					// create new earning
					earning = [NSEntityDescription insertNewObjectForEntityForName:@"Earning" inManagedObjectContext:managedObjectContext];
					earning.date = startDate;
					earning.Region = region;
					
					//DebugLog(@"%s **** creating earning %@", __PRETTY_FUNCTION__, earning);
				}
				earning.deposit = [NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithFloat:deposit] decimalValue]];
			}

#if 1
			[managedObjectContext processPendingChanges];
			[undoManager enableUndoRegistration];
#else
			[managedObjectContext processPendingChanges];
			[undoManager endUndoGrouping];
			[undoManager setActionName:@"Earning"];
#endif
		}
	}
	
	{
		_salesFormatter.currencySymbol = @"";
		_salesFormatter.maximumFractionDigits = 2;
		_salesFormatter.minimumFractionDigits = 2;
		NSString *totalDepositFormatted = [_salesFormatter stringFromNumber:[NSNumber numberWithFloat:totalDeposit]];

		NSString *javaScriptString = [NSString stringWithFormat:@"document.getElementById('total_deposit').innerHTML = '%@';", totalDepositFormatted];
		[webView stringByEvaluatingJavaScriptFromString:javaScriptString];
	}
}

- (NSUndoManager *)undoManagerForWebView:(WebView *)webView
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

#if 1
	NSUndoManager *undoManager = [managedObjectContext undoManager];
	
	/*
	 [undoManager setGroupsByEvent:NO];
	 
	 [undoManager setActionName:@"Earning"];
	 [undoManager endUndoGrouping];
	 [undoManager beginUndoGrouping];
	 */
	
	return undoManager;
#else
	//return _webViewUndoManager;
	return [[[NSUndoManager alloc] init] autorelease];
#endif
}



@end
