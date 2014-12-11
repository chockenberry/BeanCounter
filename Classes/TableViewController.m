//
//  TableViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/2/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "TableViewController.h"

#import "InternationalInfo.h"
#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"

#import "DebugLog.h"


@interface TableViewController ()

@end


@implementation TableViewController

@synthesize managedObjectModel, managedObjectContext;
@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		_unitsFormatter = [[NSNumberFormatter alloc] init];
		_unitsFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		
		_salesFormatter = [[NSNumberFormatter alloc] init];
		_salesFormatter.numberStyle = NSNumberFormatterCurrencyStyle;

		_percentFormatter = [[NSNumberFormatter alloc] init];
		_percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
		_percentFormatter.minimumFractionDigits = 1;
		
	}
    
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_unitsFormatter release];
	[_salesFormatter release];
	[_percentFormatter release];

	//[[webView undoManager] removeAllActions];
	[webView setEditingDelegate:nil];
	[webView release], webView = nil;
	
	[managedObjectModel release], managedObjectModel = nil;
	[managedObjectContext release], managedObjectContext = nil;
	
	[super dealloc];
}

- (void)awakeFromNib
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[webView setEditingDelegate:self];
	//[[webView undoManager] disableUndoRegistration];

	[self generateReport:self];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)newManagedObjectContext
{
	if (newManagedObjectContext != managedObjectContext) {
		[managedObjectContext release];
		managedObjectContext = [newManagedObjectContext retain];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:managedObjectContext];
		
		//[managedObjectContext setUndoManager:nil];
	}
}
- (IBAction)testButton:(id)sender
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

- (NSArray *)salesForProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
			product.vendorId, @"vendorId",
			region.id, @"regionId",
			startDate, @"startDate",
			endDate, @"endDate",
			nil];
	NSFetchRequest *salesByProductInRegionWithRangeFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"salesByProductInRegionWithRange" substitutionVariables:variables];
	salesByProductInRegionWithRangeFetchRequest.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"country" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"quantity" ascending:NO], nil];
	NSArray *salesByProductInRegionWithRange = [managedObjectContext executeFetchRequest:salesByProductInRegionWithRangeFetchRequest error:NULL];

	return salesByProductInRegionWithRange;
}

- (NSString *)tableRowsForProduct:(Product *)product inRegion:(Region *)region withSales:(NSArray *)sales newProduct:(BOOL)newProduct newRegion:(BOOL)newRegion byProduct:(BOOL)byProduct showDetails:(BOOL)showDetails
{
	NSMutableString *tableRowHTML = [NSMutableString string];
	
	NSInteger unitsTotal = 0;
	float salesTotal = 0.0f;
	for (Sale *sale in sales) {
		unitsTotal += [sale.quantity integerValue];
		salesTotal += [sale.total floatValue];
	}

	_salesFormatter.currencySymbol = [[InternationalInfo sharedInternationalInfo] regionCurrencySymbolForId:region.id];

	NSString *majorColumn = nil;
	NSString *minorColumn = nil;
	if (byProduct) {
		majorColumn = (newProduct ? product.name : @"");
		minorColumn = (newRegion ? region.name : @"");
	}
	else {
		majorColumn = (newRegion ? region.name : @"");
		minorColumn = (newProduct ? product.name : @"");
	}

	NSString *unitsColumn = [_unitsFormatter stringFromNumber:[NSNumber numberWithInteger:unitsTotal]];
	NSString *salesColumn = [_salesFormatter stringFromNumber:[NSNumber numberWithFloat:salesTotal]];
	[tableRowHTML appendFormat:@"<tr><td>%@</td><td>%@</td><td style='text-align:right;'>%@</td><td style='text-align:right;'>%@</td><td></td><td></td></tr>", majorColumn, minorColumn, unitsColumn, salesColumn];
			
	if ([sales count] > 1 && showDetails) {
		for (Sale *sale in sales) {
			float unitPercentage = [sale.quantity floatValue] / (float)unitsTotal;
			NSString *unitsColumn = [_unitsFormatter stringFromNumber:sale.quantity];
			NSString *salesColumn = [_salesFormatter stringFromNumber:sale.total];
			NSString *percentageColumn = [_percentFormatter stringFromNumber:[NSNumber numberWithFloat:unitPercentage]];
			NSString *countryColumn = sale.countryName; 
			[tableRowHTML appendFormat:@"<tr><td></td><td></td><td style='text-align:right;'>%@</td><td style='text-align:right;'>%@</td><td style='text-align:right;'>%@</td><td>%@</td></tr>", unitsColumn, salesColumn, percentageColumn, countryColumn];
		}
	}
	
	return [NSString stringWithString:tableRowHTML];
}

- (IBAction)generateReport:(id)sender
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSUInteger reportPeriod = [userDefaults integerForKey:@"reportPeriod"];
	NSUInteger reportMonth = [userDefaults integerForKey:@"reportMonth"];
	NSUInteger reportYear = [userDefaults integerForKey:@"reportYear"];
	BOOL byProduct = [userDefaults boolForKey:@"reportByProduct"];
	BOOL showDetails = [userDefaults boolForKey:@"reportShowDetails"];
	
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

			endDateComponents.year = 1000;
			break;
	}
	NSDate *startDate = [[NSCalendar currentCalendar] dateFromComponents:startDateComponents];
	NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:startDate options:0];

	NSFetchRequest *allProductsFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"allProducts" substitutionVariables:[NSDictionary dictionary]];
	allProductsFetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	NSArray *allProducts = [managedObjectContext executeFetchRequest:allProductsFetchRequest error:NULL];

	NSFetchRequest *allRegionsFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"allRegions" substitutionVariables:[NSDictionary dictionary]];
	allRegionsFetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]];
	NSArray *allRegions = [managedObjectContext executeFetchRequest:allRegionsFetchRequest error:NULL];

	NSNumberFormatter *unitsFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	unitsFormatter.numberStyle = NSNumberFormatterDecimalStyle;
	
	NSNumberFormatter *salesFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	salesFormatter.numberStyle = NSNumberFormatterCurrencyStyle;

	NSNumberFormatter *percentFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
	percentFormatter.minimumFractionDigits = 1;

	NSMutableString *reportHTML = [NSMutableString string];

	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	dateFormatter.dateStyle = NSDateFormatterLongStyle;
	[reportHTML appendString:@"<html><head><style>body {font-family:Helvetica;}</style></head><body><h2>"];
	[reportHTML appendString:[NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:startDate], [dateFormatter stringFromDate:endDate]]];
	[reportHTML appendString:@"</h2><form><table><tr>"];	
	if (byProduct) {
		[reportHTML appendString:@"<th>Product</th><th>Region</th>"];
	}
	else {
		[reportHTML appendString:@"<th>Region</th><th>Product</th>"];
	}
	[reportHTML appendString:@"<th>Units</th><th>Sales</th><th></th><th></th></tr>"];	

#if 1
	// setup the Earning entities
	NSDate *earningDate = [NSCalendarDate dateWithYear:2011 month:11 day:11 hour:11 minute:11 second:11 timeZone:[NSTimeZone localTimeZone]];
	for (NSString *regionId in [NSArray arrayWithObjects:@"US", @"EU", @"GB", nil]) {
		Earning *earning = nil;
		{
			NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
									   earningDate, @"date",
									   regionId, @"regionId",
									   nil];
			NSFetchRequest *existingEarningFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingEarning" substitutionVariables:variables];
			NSArray *existingEarnings = [managedObjectContext executeFetchRequest:existingEarningFetchRequest error:NULL];
			if ([existingEarnings count] > 0) {
				// use existing earning
				earning = [existingEarnings lastObject];
				DebugLog(@"%s using existing %@", __PRETTY_FUNCTION__, earning);
			}
			else {
				// create a new earning
				Region *region = nil;
				NSFetchRequest *findRegionByIdFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"findRegionById" substitutionVariables:[NSDictionary dictionaryWithObject:regionId forKey:@"id"]];
				NSArray *regions = [managedObjectContext executeFetchRequest:findRegionByIdFetchRequest error:NULL];
				if ([regions count] > 0) {
					region = [regions lastObject];
				}
				else {
					DebugLog(@"%s ******* NO REGION %@ *******", __PRETTY_FUNCTION__, regionId);
				}
				
				earning = [NSEntityDescription insertNewObjectForEntityForName:@"Earning" inManagedObjectContext:managedObjectContext];
				earning.date = earningDate;
				earning.deposit = [NSDecimalNumber zero];
				earning.Region = region;
				
				DebugLog(@"%s **** creating earning %@", __PRETTY_FUNCTION__, earning);
			}
		}
		NSString *value = [earning.deposit stringValue];
		NSString *key = [[[earning objectID] URIRepresentation] description];

		[reportHTML appendFormat:@"<tr><td>%@</td><td style='text-align:right;'><input id='%@' type='text' size='10' value='%@'></td><td></td><td></td><td>%@</td><td></td></tr>", regionId, key, value, key];
	}
#endif
	
	if (byProduct) {
		for (Product *product in allProducts) {
			BOOL newProduct = YES;
			for (Region *region in allRegions) {
				BOOL newRegion = YES;

				NSArray *sales = [self salesForProduct:product inRegion:region startDate:startDate endDate:endDate];
				if ([sales count] > 0) {
					NSString *tableRowsHTML = [self tableRowsForProduct:product inRegion:region withSales:sales newProduct:newProduct newRegion:newRegion byProduct:byProduct showDetails:showDetails];
					[reportHTML appendString:tableRowsHTML];

					newRegion = NO;
					newProduct = NO;
				}
			}
		}
	}
	else {
		for (Region *region in allRegions) {
			BOOL newRegion = YES;
			for (Product *product in allProducts) {
				BOOL newProduct = YES;

				NSArray *sales = [self salesForProduct:product inRegion:region startDate:startDate endDate:endDate];
				if ([sales count] > 0) {
					NSString *tableRowsHTML = [self tableRowsForProduct:product inRegion:region withSales:sales newProduct:newProduct newRegion:newRegion byProduct:byProduct showDetails:showDetails];
					[reportHTML appendString:tableRowsHTML];

					newRegion = NO;
					newProduct = NO;
				}
			}
		}
	}

	[reportHTML appendString:@"</table></form></body></html>"];
	
	WebFrame *webFrame = webView.mainFrame;
	[webFrame loadHTMLString:reportHTML baseURL:nil];
}

- (IBAction)grabFormValues:(id)sender
{
	NSString *result1 = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('test1').value = '1';"];
	NSLog(@"%s result1 = %@", __PRETTY_FUNCTION__, result1);

	NSString *result2 = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('test2').value = '2';"];
	NSLog(@"%s result2 = %@", __PRETTY_FUNCTION__, result2);

	NSString *result3 = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('test3').value = '3';"];
	NSLog(@"%s result3 = %@", __PRETTY_FUNCTION__, result3);
}

- (void)managedObjectContextChanged:(NSNotification *)notification
{
#if 0
	NSDictionary *userInfo = [notification userInfo];
	DebugLog(@"%s inserted = %@, updated = %@, deleted = %@", __PRETTY_FUNCTION__, [userInfo objectForKey:NSInsertedObjectsKey], [userInfo objectForKey:NSUpdatedObjectsKey], [userInfo objectForKey:NSDeletedObjectsKey]);
#endif
	
#if 0
	// get the Earning entity
	NSString *test1 = @"";
	Earning *earning = nil;
	{
		NSDate *earningDate = [NSCalendarDate dateWithYear:2011 month:11 day:11 hour:11 minute:11 second:11 timeZone:[NSTimeZone localTimeZone]];
		
		NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
								   earningDate, @"date",
								   @"US", @"regionId",
								   nil];
		NSFetchRequest *existingEarningFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingEarning" substitutionVariables:variables];
		NSArray *existingEarnings = [managedObjectContext executeFetchRequest:existingEarningFetchRequest error:NULL];
		if ([existingEarnings count] > 0) {
			earning = [existingEarnings lastObject];
			DebugLog(@"%s using existing earning on %@ for %@", __PRETTY_FUNCTION__, earning.date, earning.deposit);
			test1 = [earning.deposit stringValue];
		}
	}
	NSString *result1 = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('test1').value = '%@';", earning.deposit]];
	NSLog(@"%s result1 = %@", __PRETTY_FUNCTION__, result1);
#endif
}

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

#if 0
	NSString *test1 = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('test1').value;"];
	NSLog(@"%s test1 = %@", __PRETTY_FUNCTION__, test1);
	
	NSString *test2 = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('test2').value;"];
	NSLog(@"%s test2 = %@", __PRETTY_FUNCTION__, test2);

	NSString *test3 = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('test3').value;"];
	NSLog(@"%s test3 = %@", __PRETTY_FUNCTION__, test3);
#else
	// setup the Earning entities
	NSDate *earningDate = [NSCalendarDate dateWithYear:2011 month:11 day:11 hour:11 minute:11 second:11 timeZone:[NSTimeZone localTimeZone]];
	for (NSString *regionId in [NSArray arrayWithObjects:@"US", @"EU", @"GB", nil]) {
		Earning *earning = nil;
		{
			NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
									   earningDate, @"date",
									   regionId, @"regionId",
									   nil];
			NSFetchRequest *existingEarningFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingEarning" substitutionVariables:variables];
			NSArray *existingEarnings = [managedObjectContext executeFetchRequest:existingEarningFetchRequest error:NULL];
			if ([existingEarnings count] > 0) {
				// use existing earning
				earning = [existingEarnings lastObject];
				//DebugLog(@"%s using existing %@", __PRETTY_FUNCTION__, earning);
			}
		}
		NSString *key = [[[earning objectID] URIRepresentation] description];
		NSString *currentValue = [earning.deposit stringValue];
		NSString *newValue = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('%@').value;", key]];
		NSLog(@"%s key = %@, currentValue = %@, newValue = %@", __PRETTY_FUNCTION__, key, currentValue, newValue);
		
		NSUndoManager *undoManager = [managedObjectContext undoManager];
		[undoManager disableUndoRegistration];

		NSNumber *newDeposit = [NSNumber numberWithFloat:[newValue floatValue]];
		earning.deposit = [NSDecimalNumber decimalNumberWithDecimal:[newDeposit decimalValue]];
		DebugLog(@"%s updated existing earning %@", __PRETTY_FUNCTION__, earning);
		
		[managedObjectContext processPendingChanges];
		[undoManager enableUndoRegistration];
	}
#endif
	
#if 0
	//[[webView undoManager] removeAllActions];
	
	NSUndoManager *undoManager = [managedObjectContext undoManager];

	[undoManager disableUndoRegistration];
	
	Earning *earning = nil;
	{
		NSDate *earningDate = [NSCalendarDate dateWithYear:2011 month:11 day:11 hour:11 minute:11 second:11 timeZone:[NSTimeZone localTimeZone]];
		
		NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
								   earningDate, @"date",
								   @"US", @"regionId",
								   nil];
		NSFetchRequest *existingEarningFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"existingEarning" substitutionVariables:variables];
		NSArray *existingEarnings = [managedObjectContext executeFetchRequest:existingEarningFetchRequest error:NULL];
		if ([existingEarnings count] == 0) {
			Region *region = nil;
			NSFetchRequest *findRegionByIdFetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"findRegionById" substitutionVariables:[NSDictionary dictionaryWithObject:@"US" forKey:@"id"]];
			NSArray *regions = [managedObjectContext executeFetchRequest:findRegionByIdFetchRequest error:NULL];
			if ([regions count] > 0) {
				region = [regions lastObject];
			}

			earning = [NSEntityDescription insertNewObjectForEntityForName:@"Earning" inManagedObjectContext:managedObjectContext];
			earning.date = earningDate;
			earning.deposit = [NSNumber numberWithInteger:[test1 integerValue]];
			earning.Region = region;

			DebugLog(@"%s **** creating earning %@", __PRETTY_FUNCTION__, earning);
		}
		else {
			NSNumber *newDeposit = [NSNumber numberWithInteger:[test1 integerValue]];
			earning = [existingEarnings lastObject];
			earning.deposit = newDeposit;
			DebugLog(@"%s updated existing earning %@", __PRETTY_FUNCTION__, earning);
		}
	}
	
	[managedObjectContext processPendingChanges];
	[undoManager enableUndoRegistration];

	//[undoManager setGroupsByEvent:YES];

//	NSString *result1 = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('test1').value = '%@';", earning.deposit]];
//	NSLog(@"%s result1 = %@", __PRETTY_FUNCTION__, result1);
#endif
}

- (NSUndoManager *)undoManagerForWebView:(WebView *)webView
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	NSUndoManager *undoManager = [managedObjectContext undoManager];

	/*
	[undoManager setGroupsByEvent:NO];

	[undoManager setActionName:@"Earning"];
	[undoManager endUndoGrouping];
	[undoManager beginUndoGrouping];
	*/
	
	return undoManager;
//	return nil;
}

@end
