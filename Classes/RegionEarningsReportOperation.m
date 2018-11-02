//
//  RegionEarningsReportOperation.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "RegionEarningsReportOperation.h"

#import "InternationalInfo.h"
#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"
#import "Group.h"
#import "Partner.h"

#import "DebugLog.h"

@interface RegionEarningsReportOperation ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end


@implementation RegionEarningsReportOperation

@synthesize reportCategory;
@synthesize reportCategoryFilter;
@synthesize reportShowDetails;
@synthesize reportStartDate;
@synthesize reportEndDate;
@synthesize reportVariables;

@synthesize managedObjectContext;

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)thePersistentStoreCoordinator withReportCategory:(NSUInteger)theReportCategory andCategoryFilter:(NSString *)theCategoryFilter showingDetails:(BOOL)theShowDetails from:(NSDate *)theStartDate to:(NSDate *)theEndDate delegate:(NSObject <RegionEarningsReportOperationDelegate>*)theDelegate
{
	if ((self = [super init])) {
		reportCategory = theReportCategory;
		reportCategoryFilter = [theCategoryFilter copy];
		reportShowDetails = theShowDetails;
		reportStartDate = [theStartDate retain];
		reportEndDate = [theEndDate retain];
		reportVariables = nil;
		
		_unitsFormatter = [[NSNumberFormatter alloc] init];
		_unitsFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		
		_salesFormatter = [[NSNumberFormatter alloc] init];
		_salesFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
		_salesFormatter.currencySymbol = @"";
		
		_earningsFormatter = [[NSNumberFormatter alloc] init];
		_earningsFormatter.numberStyle = NSNumberFormatterCurrencyStyle;

		_percentFormatter = [[NSNumberFormatter alloc] init];
		_percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
		_percentFormatter.minimumFractionDigits = 1;
		
		_dateFormatter = [[NSDateFormatter alloc] init];
		_dateFormatter.dateFormat = @"MMMM yyyy";

		_persistentStoreCoordinator = thePersistentStoreCoordinator;
		_delegate = theDelegate;
	}
	
	return self;
}

- (void)dealloc
{
	[reportCategoryFilter release];
	[reportStartDate release];
	[reportEndDate release];
	[reportVariables release];
	
	[_unitsFormatter release];
	[_salesFormatter release];
	[_percentFormatter release];
	[_dateFormatter release];
	
	_persistentStoreCoordinator = nil;
	_delegate = nil;
	
	[super dealloc];
}

#define USE_COUNTS 0
#define USE_EXPRESSIONS 0

- (NSDictionary *)createProductDictionaryForRegion:(Region *)region withProduct:(Product *)product fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate
{
	NSDictionary *result = nil;
	
	NSArray *sales = [Sale fetchAllInManagedObjectContext:managedObjectContext forProduct:product inRegion:region startDate:startDate endDate:endDate];
	if ([sales count] > 0) {
		NSNumber *unitsSummary = [sales valueForKeyPath:@"@sum.quantity"];
		NSDecimalNumber *salesSummary = [sales valueForKeyPath:@"@sum.total"];
		NSDecimalNumber *earningsSummary = [NSDecimalNumber zero];
		NSDecimalNumber *earningsPercentage = [NSDecimalNumber zero];

		// check the quantity sum: it can be 0 because of sales (+1) that are refunded (-1)
		if ([unitsSummary integerValue] != 0) {
			Earning *earning = [Earning fetchInManagedObjectContext:managedObjectContext forRegion:region onDate:startDate]; // use earnings that may have occured in the future
			if (earning) {
				if ([earning.adjustments isEqual:[NSDecimalNumber zero]]) {
					earningsSummary = [salesSummary decimalNumberByMultiplyingBy:earning.rate];
				}
				else {
					// compute the adjusted earning rate
					NSArray *allSales = [Sale fetchAllInManagedObjectContext:managedObjectContext forRegion:region startDate:startDate endDate:endDate];
					NSDecimalNumber *allSalesSummary = [allSales valueForKeyPath:@"@sum.total"];
					NSDecimalNumber *adjustedRate = [earning.deposit decimalNumberByDividingBy:allSalesSummary];
					earningsSummary = [salesSummary decimalNumberByMultiplyingBy:adjustedRate];
				}
				
				earningsPercentage = [earningsSummary decimalNumberByDividingBy:earning.deposit];
			}


			InternationalInfo *internationalInfoManager = [InternationalInfo sharedInternationalInfo];
			//_salesFormatter.currencySymbol = [internationalInfoManager regionCurrencySymbolForId:region.id];
			_salesFormatter.maximumFractionDigits = [internationalInfoManager regionCurrencyDigitsForId:region.id];
			_salesFormatter.minimumFractionDigits = [internationalInfoManager regionCurrencyDigitsForId:region.id];
			
			NSString *unitsSummaryFormatted = [_unitsFormatter stringFromNumber:unitsSummary];
			NSString *salesSummaryFormatted = [_salesFormatter stringFromNumber:salesSummary];
			NSString *earningsSummaryFormatted = [_earningsFormatter stringFromNumber:earningsSummary];
			NSString *earningsPercentageFormatted = [_percentFormatter stringFromNumber:earningsPercentage];

			result = [NSDictionary dictionaryWithObjectsAndKeys:product, @"product",
					unitsSummary, @"unitsSummary", unitsSummaryFormatted, @"unitsSummaryFormatted",
					salesSummary, @"salesSummary", salesSummaryFormatted, @"salesSummaryFormatted",
					earningsSummary, @"earningsSummary", earningsSummaryFormatted, @"earningsSummaryFormatted",
					earningsPercentage, @"earningsPercentage", earningsPercentageFormatted, @"earningsPercentageFormatted",
					nil];
		}
	}
	
	return result;
}

- (NSArray *)createProductArrayWithRegion:(Region *)region fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate summaryVariables:(NSMutableDictionary *)summaryVariables
{
	NSArray *result = nil;
	
	NSNumber *categoryUnitsTotal = [NSNumber numberWithInteger:0];
	NSDecimalNumber *categorySalesTotal = [NSDecimalNumber zero];
	NSDecimalNumber *categoryEarningsTotal = [NSDecimalNumber zero];

	NSMutableArray *productArray = [NSMutableArray array];
	
	NSArray *products = [Product fetchAllInManagedObjectContext:managedObjectContext];
	for (Product *product in products) {
		NSDictionary *productDictionary = [self createProductDictionaryForRegion:region withProduct:product fromStartDate:startDate toEndDate:endDate];
		if (productDictionary) {
			NSNumber *unitsSummary = [productDictionary objectForKey:@"unitsSummary"];
			NSDecimalNumber *salesSummary = [productDictionary objectForKey:@"salesSummary"];
			NSDecimalNumber *earningsSummary = [productDictionary objectForKey:@"earningsSummary"];

			categoryUnitsTotal = [NSNumber numberWithInteger:([categoryUnitsTotal integerValue] + [unitsSummary integerValue])];
			categorySalesTotal = [categorySalesTotal decimalNumberByAdding:salesSummary];
			categoryEarningsTotal = [categoryEarningsTotal decimalNumberByAdding:earningsSummary];

			[productArray addObject:productDictionary];
		}
	}
	
	if ([productArray count] > 0) {
		result = [NSArray arrayWithArray:productArray];
		
		[summaryVariables setObject:categoryUnitsTotal forKey:@"categoryUnitsTotal"];
		[summaryVariables setObject:categorySalesTotal forKey:@"categorySalesTotal"];
		[summaryVariables setObject:categoryEarningsTotal forKey:@"categoryEarningsTotal"];
	}
	
	return result;
}

- (NSDictionary *)createCategoryDictionaryWithRegion:(Region *)region fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate
{
	NSDictionary *result = nil;
	
	NSMutableDictionary *summaryVariables = [NSMutableDictionary dictionary];
	NSArray *productArray = [self createProductArrayWithRegion:region fromStartDate:startDate toEndDate:endDate summaryVariables:summaryVariables];
	
	if (productArray) {
		NSNumber *categoryUnitsTotal = [summaryVariables objectForKey:@"categoryUnitsTotal"];
		NSDecimalNumber *categorySalesTotal = [summaryVariables objectForKey:@"categorySalesTotal"];
		NSDecimalNumber *categoryEarningsTotal = [summaryVariables objectForKey:@"categoryEarningsTotal"];

		NSString *categoryUnitsTotalFormatted = [_unitsFormatter stringFromNumber:categoryUnitsTotal];

		InternationalInfo *internationalInfoManager = [InternationalInfo sharedInternationalInfo];
		_salesFormatter.maximumFractionDigits = [internationalInfoManager regionCurrencyDigitsForId:region.id];
		_salesFormatter.minimumFractionDigits = [internationalInfoManager regionCurrencyDigitsForId:region.id];

		NSString *categorySalesTotalFormatted = [_salesFormatter stringFromNumber:categorySalesTotal];

		NSString *categoryEarningsTotalFormatted = [_earningsFormatter stringFromNumber:categoryEarningsTotal];

		NSMutableDictionary *categoryDictionary = [NSMutableDictionary dictionary];
		if (region) {
			[categoryDictionary setObject:[NSString stringWithFormat:@"%@ (%@)", region.name, region.currency] forKey:@"categoryName"];
		}
		[categoryDictionary setObject:productArray forKey:@"productArray"];
		[categoryDictionary setObject:categoryUnitsTotal forKey:@"categoryUnitsTotal"];
		[categoryDictionary setObject:categorySalesTotal forKey:@"categorySalesTotal"];
		[categoryDictionary setObject:categoryEarningsTotal forKey:@"categoryEarningsTotal"];
		[categoryDictionary setObject:categoryUnitsTotalFormatted forKey:@"categoryUnitsTotalFormatted"];
		[categoryDictionary setObject:categorySalesTotalFormatted forKey:@"categorySalesTotalFormatted"];
		[categoryDictionary setObject:categoryEarningsTotalFormatted forKey:@"categoryEarningsTotalFormatted"];

		result = [NSDictionary dictionaryWithDictionary:categoryDictionary];
	}
	
	return result;
}

- (void)main
{
	if (self.isCancelled) {
		DebugLog(@"%s cancelled", __PRETTY_FUNCTION__);
		return;
	}

	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	DebugLog(@"%s report started", __PRETTY_FUNCTION__);
	NSDate *reportStart = [NSDate date];

	self.managedObjectContext = [[[NSManagedObjectContext alloc] init] autorelease];
	[managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
	
	NSNumber *grandUnitsTotal = [NSNumber numberWithInteger:0];
	NSDecimalNumber *grandEarningsTotal = [NSDecimalNumber zero];
	NSMutableArray *categoryArray = [NSMutableArray array];

	NSArray *allRegions = [Region fetchAllInManagedObjectContext:managedObjectContext];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"currency" ascending:YES], nil];
	allRegions = [allRegions sortedArrayUsingDescriptors:sortDescriptors];
	
	for (Region *region in allRegions) {

		NSDictionary *categoryDictionary = [self createCategoryDictionaryWithRegion:region fromStartDate:reportStartDate toEndDate:reportEndDate];
		if (categoryDictionary) {
			NSNumber *categoryUnitsTotal = [categoryDictionary objectForKey:@"categoryUnitsTotal"];
			//NSDecimalNumber *categorySalesTotal = [categoryDictionary objectForKey:@"categorySalesTotal"];
			NSDecimalNumber *categoryEarningsTotal = [categoryDictionary objectForKey:@"categoryEarningsTotal"];
			grandUnitsTotal = [NSNumber numberWithInteger:([grandUnitsTotal integerValue] + [categoryUnitsTotal integerValue])];
			grandEarningsTotal = [grandEarningsTotal decimalNumberByAdding:categoryEarningsTotal];

			[categoryArray addObject:categoryDictionary];
		}
	}

	if (! self.isCancelled) {
		NSString *reportTitle = [_dateFormatter stringFromDate:reportStartDate];
		
		NSMutableDictionary *variables = [NSMutableDictionary dictionary];
		[variables setObject:reportTitle forKey:@"reportTitle"];
		[variables setObject:categoryArray forKey:@"categoryArray"];
		NSString *grandUnitsTotalFormatted = [_unitsFormatter stringFromNumber:grandUnitsTotal];
		[variables setObject:grandUnitsTotalFormatted forKey:@"grandUnitsTotalFormatted"];
		NSString *grandEarningsTotalFormatted = [_earningsFormatter stringFromNumber:grandEarningsTotal];
		[variables setObject:grandEarningsTotalFormatted forKey:@"grandEarningsTotalFormatted"];

		self.reportVariables = [NSDictionary dictionaryWithDictionary:variables];
		
		[_delegate performSelectorOnMainThread:@selector(regionEarningsReportOperationCompleted:) withObject:self waitUntilDone:YES];
	}
	
	self.managedObjectContext = nil;
	
	NSDate *reportEnd = [NSDate date];
	DebugLog(@"%s report generated in %f seconds", __PRETTY_FUNCTION__, [reportEnd timeIntervalSinceDate:reportStart]);

	[pool drain];
}

@end
