//
//  ProductEarningsReportOperation.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "ProductEarningsReportOperation.h"

#import "InternationalInfo.h"
#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"
#import "Group.h"
#import "Partner.h"
#import "Split.h"

#import "DebugLog.h"

@interface ProductEarningsReportOperation ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end


@implementation ProductEarningsReportOperation

@synthesize reportCategory;
@synthesize reportCategoryFilter;
@synthesize reportShowDetails;
@synthesize reportStartDate;
@synthesize reportEndDate;
@synthesize reportVariables;

@synthesize managedObjectContext;

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)thePersistentStoreCoordinator withReportCategory:(NSUInteger)theReportCategory andCategoryFilter:(NSString *)theCategoryFilter showingDetails:(BOOL)theShowDetails from:(NSDate *)theStartDate to:(NSDate *)theEndDate delegate:(NSObject <ProductEarningsReportOperationDelegate>*)theDelegate
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

- (NSDictionary *)createRegionDictionaryForRegion:(Region *)region withProduct:(Product *)product fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate
{
	if (self.isCancelled) {
		DebugLog(@"%s cancelled", __PRETTY_FUNCTION__);
		return nil;
	}
	
	NSDateComponents *loopDateComponents = [[[NSDateComponents alloc] init] autorelease];
	loopDateComponents.month = 1;
	
	NSDate *loopStartDate = startDate;
	
	NSNumber *unitsSummary = [NSNumber numberWithInteger:0];
	NSDecimalNumber *earningsSummary = [NSDecimalNumber zero];
	NSDecimalNumber *splitSummary = [NSDecimalNumber zero];
	
	NSMutableArray *earningsArray = [NSMutableArray array];
	
	while ([loopStartDate compare:endDate] == NSOrderedAscending) { // loopStartDate is earlier than endDate
		NSDate *loopEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:loopDateComponents toDate:loopStartDate options:0];
		
		NSUInteger salesCount = 0;
#if USE_COUNTS
		salesCount = [Sale countAllInManagedObjectContext:managedObjectContext forProduct:product inRegion:region startDate:loopStartDate endDate:loopEndDate];
#else
		NSArray *sales = [Sale fetchAllInManagedObjectContext:managedObjectContext forProduct:product inRegion:region startDate:loopStartDate endDate:loopEndDate];
		salesCount = [sales count];
#endif
		if (salesCount > 0) {
#if USE_EXPRESSIONS
			NSNumber *rangeUnitsSummary = [Sale sumQuantityInManagedObjectContext:managedObjectContext forProduct:product inRegion:region startDate:loopStartDate endDate:loopEndDate];
			NSDecimalNumber *rangeSalesSummary = [Sale sumTotalInManagedObjectContext:managedObjectContext forProduct:product inRegion:region startDate:loopStartDate endDate:loopEndDate];
#else
#if USE_COUNTS
			NSArray *sales = [Sale fetchAllInManagedObjectContext:managedObjectContext forProduct:product inRegion:region startDate:loopStartDate endDate:loopEndDate];
#endif
			NSNumber *rangeUnitsSummary = [sales valueForKeyPath:@"@sum.quantity"];
			NSDecimalNumber *rangeSalesSummary = [sales valueForKeyPath:@"@sum.total"];
#endif
			// check the quantity sum: it can be 0 because of sales (+1) that are refunded (-1)
			if ([rangeUnitsSummary integerValue] != 0) {
#if 1
				Earning *earning = [Earning fetchInManagedObjectContext:managedObjectContext forRegion:region onDate:loopStartDate]; // use earnings that may have occured in the future
#else
				Earning *earning = [Earning fetchInManagedObjectContext:managedObjectContext forRegion:region toDate:loopStartDate]; // use earnings only on the month of the report
#endif
				
				NSDecimalNumber *rangeEarningsSummary = nil;
				if (earning) {
#if ROUND_DECIMALS
					rangeEarningsSummary = [rangeSalesSummary decimalNumberByMultiplyingBy:earning.rate withBehavior:_roundingBehavior];
#else
					rangeEarningsSummary = [rangeSalesSummary decimalNumberByMultiplyingBy:earning.rate];
#endif
				}
				else {
					rangeEarningsSummary = [NSDecimalNumber zero];
				}

				NSDecimalNumber *rangeSplitSummary = [NSDecimalNumber zero];
				Partner *partner = product.Partner;
				if (partner) {
					NSSet *splits = product.Splits;
					if (splits && [splits count] > 0) {
						NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"fromDate" ascending:YES]];
						NSArray *sortedSplits = [splits sortedArrayUsingDescriptors:sortDescriptors];
						Split *selectedSplit = nil;
						for (Split *split in sortedSplits) {
							if (split.fromDate == nil) {
								selectedSplit = split;
							}
							else if ([split.fromDate compare:loopStartDate] != NSOrderedDescending) { // split.fromDate is earlier than or equal to loopStartDate
								selectedSplit = split;
							}
						}
						//DebugLog(@"%s loopStartDate = %@, selectedSplit = %@, splitSummary = %@", __PRETTY_FUNCTION__, loopStartDate, selectedSplit, splitSummary);
						rangeSplitSummary = [rangeEarningsSummary decimalNumberByMultiplyingBy:selectedSplit.percentage];
					}
				}
				
				if (reportShowDetails) {
					// TODO: Show earnings with value of zero or not?
					//					if ([rangeEarningsSum doubleValue] > 0.0) {
					if (YES) {
						NSString *unitsDetailFormatted = [_unitsFormatter stringFromNumber:rangeUnitsSummary];
						NSString *earningsDetailFormatted = [_salesFormatter stringFromNumber:rangeEarningsSummary];
						NSString *dateDetailFormatted = [_dateFormatter stringFromDate:loopStartDate];
						
						NSMutableDictionary *earningsDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
						[earningsDictionary setObject:unitsDetailFormatted forKey:@"unitsDetailFormatted"];
						[earningsDictionary setObject:earningsDetailFormatted forKey:@"earningsDetailFormatted"];
						[earningsDictionary setObject:dateDetailFormatted forKey:@"dateDetailFormatted"];
						[earningsArray addObject:earningsDictionary];
					}
				}
				
				unitsSummary = [NSNumber numberWithInteger:([unitsSummary integerValue] + [rangeUnitsSummary integerValue])];
				earningsSummary = [earningsSummary decimalNumberByAdding:rangeEarningsSummary];	
				splitSummary = [splitSummary decimalNumberByAdding:rangeSplitSummary];
			}
			else {
				DebugLog(@"%s no quantity sum for %@ in %@ on %@", __PRETTY_FUNCTION__, product.name, region.name, loopStartDate);
			}
		}
		else {
			//DebugLog(@"%s no sales for %@ in %@ on %@", __PRETTY_FUNCTION__, product.name, region.name, loopStartDate);
		}
		
		loopStartDate = loopEndDate;
	}
	
	NSString *unitsSummaryFormatted = [_unitsFormatter stringFromNumber:unitsSummary];
	NSString *earningsSummaryFormatted = [_salesFormatter stringFromNumber:earningsSummary];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:region, @"region", earningsArray, @"earningsArray", unitsSummary, @"unitsSummary", earningsSummary, @"earningsSummary", splitSummary, @"splitSummary", unitsSummaryFormatted, @"unitsSummaryFormatted", earningsSummaryFormatted, @"earningsSummaryFormatted", nil];
}

- (NSArray *)createRegionArrayWithProduct:(Product *)product fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate summaryVariables:(NSMutableDictionary *)summaryVariables
{
	if (self.isCancelled) {
		DebugLog(@"%s cancelled", __PRETTY_FUNCTION__);
		return nil;
	}
	
	NSMutableArray *regionArray = [NSMutableArray array];
	
	NSNumber *unitsTotal = [NSNumber numberWithInteger:0];
	NSDecimalNumber *earningsTotal = [NSDecimalNumber zero];
	NSDecimalNumber *splitTotal = [NSDecimalNumber zero];
	
	NSArray *allRegions = [Region fetchAllInManagedObjectContext:managedObjectContext];
	for (Region *region in allRegions) {
		NSDictionary *regionDictionary = [self createRegionDictionaryForRegion:region withProduct:product fromStartDate:startDate toEndDate:endDate];
		if (regionDictionary) {
			NSNumber *unitsSummary = [regionDictionary objectForKey:@"unitsSummary"];
			NSDecimalNumber *earningsSummary = [regionDictionary objectForKey:@"earningsSummary"];
			NSDecimalNumber *splitSummary = [regionDictionary objectForKey:@"splitSummary"];
			
			if ([unitsSummary compare:[NSDecimalNumber zero]] == NSOrderedDescending) {
				// unitsSummary > 0
				unitsTotal = [NSNumber numberWithInteger:([unitsTotal integerValue] + [unitsSummary integerValue])];
				earningsTotal = [earningsTotal decimalNumberByAdding:earningsSummary];
				splitTotal = [splitTotal decimalNumberByAdding:splitSummary];
				
				[regionArray addObject:regionDictionary];
			}
		}
	}
	
	[summaryVariables setObject:unitsTotal forKey:@"unitsTotal"];
	[summaryVariables setObject:earningsTotal forKey:@"earningsTotal"];
	[summaryVariables setObject:splitTotal forKey:@"splitTotal"];
	
	return [NSArray arrayWithArray:regionArray];
}

- (NSDictionary *)createProductDictionaryWithProduct:(Product *)product fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate
{
	if (self.isCancelled) {
		DebugLog(@"%s cancelled", __PRETTY_FUNCTION__);
		return nil;
	}
	
	NSDictionary *result = nil;
	
	NSMutableDictionary *summaryVariables = [NSMutableDictionary dictionary];
	NSArray *regionArray = [self createRegionArrayWithProduct:product fromStartDate:startDate toEndDate:endDate summaryVariables:summaryVariables];
	if (regionArray && [regionArray count] > 0) {
		NSNumber *unitsTotal = [summaryVariables objectForKey:@"unitsTotal"];
		NSDecimalNumber *earningsTotal = [summaryVariables objectForKey:@"earningsTotal"];
		NSDecimalNumber *splitTotal = [summaryVariables objectForKey:@"splitTotal"];
		
		NSMutableDictionary *productDictionary = [NSMutableDictionary dictionary];
		
		[productDictionary setObject:product forKey:@"product"];
		[productDictionary setObject:regionArray forKey:@"regionArray"];
		
		[productDictionary setObject:unitsTotal forKey:@"unitsTotal"];
		[productDictionary setObject:earningsTotal forKey:@"earningsTotal"];
		
		NSString *unitsTotalFormatted = [_unitsFormatter stringFromNumber:unitsTotal];
		NSString *earningsTotalFormatted = [_salesFormatter stringFromNumber:earningsTotal];		
		[productDictionary setObject:unitsTotalFormatted forKey:@"unitsTotalFormatted"];
		[productDictionary setObject:earningsTotalFormatted forKey:@"earningsTotalFormatted"];
		
		Partner *partner = product.Partner;
		if (partner) {
			[productDictionary setObject:partner.name forKey:@"partnerName"];

			[productDictionary setObject:splitTotal forKey:@"partnerSplit"];
			
			NSString *partnerSplitFormatted = [_salesFormatter stringFromNumber:splitTotal];
			[productDictionary setObject:partnerSplitFormatted forKey:@"partnerSplitFormatted"];
		}

		result = [NSDictionary dictionaryWithDictionary:productDictionary];
	}
	
	return result;
}

- (NSArray *)createProductArrayWithProducts:(NSArray *)products fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate summaryVariables:(NSMutableDictionary *)summaryVariables
{
	if (self.isCancelled) {
		DebugLog(@"%s cancelled", __PRETTY_FUNCTION__);
		return nil;
	}
	
	NSArray *result = nil;
	
	NSDecimalNumber *categoryEarningsTotal = [NSDecimalNumber zero];
	NSDecimalNumber *categoryPartnerSplitTotal = [NSDecimalNumber zero];
	
	NSMutableArray *productArray = [NSMutableArray array];
	
	for (Product *product in products) {
		NSDictionary *productDictionary = [self createProductDictionaryWithProduct:product fromStartDate:startDate toEndDate:endDate];
		if (productDictionary) {
			NSDecimalNumber *earningsTotal = [productDictionary objectForKey:@"earningsTotal"];
			NSDecimalNumber *partnerSplit = [productDictionary objectForKey:@"partnerSplit"];
			
			categoryEarningsTotal = [categoryEarningsTotal decimalNumberByAdding:earningsTotal];
			if (partnerSplit) {
				categoryPartnerSplitTotal = [categoryPartnerSplitTotal decimalNumberByAdding:partnerSplit];
			}
			
			[productArray addObject:productDictionary];
		}
	}
	
	if ([productArray count] > 0) {
		result = [NSArray arrayWithArray:productArray];
		
		[summaryVariables setObject:categoryEarningsTotal forKey:@"categoryEarningsTotal"];
		[summaryVariables setObject:categoryPartnerSplitTotal forKey:@"categoryPartnerSplitTotal"];
	}
	
	return result;
}

- (NSDictionary *)createCategoryDictionaryWithName:(NSString *)categoryName withProducts:(NSArray *)products fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate
{
	if (self.isCancelled) {
		DebugLog(@"%s cancelled", __PRETTY_FUNCTION__);
		return nil;
	}
	
	NSDictionary *result = nil;
	
	NSMutableDictionary *summaryVariables = [NSMutableDictionary dictionary];
	NSArray *productArray = [self createProductArrayWithProducts:products fromStartDate:startDate toEndDate:endDate summaryVariables:summaryVariables];
	
	if (productArray) {
		NSDecimalNumber *categoryEarningsTotal = [summaryVariables objectForKey:@"categoryEarningsTotal"];
		NSDecimalNumber *categoryPartnerSplitTotal = [summaryVariables objectForKey:@"categoryPartnerSplitTotal"];
		
		NSString *categoryEarningsTotalFormatted = [_salesFormatter stringFromNumber:categoryEarningsTotal];
		NSString *categoryPartnerSplitTotalFormatted = [_salesFormatter stringFromNumber:categoryPartnerSplitTotal];
		
		NSMutableDictionary *categoryDictionary = [NSMutableDictionary dictionary];
		if (categoryName) {
			[categoryDictionary setObject:categoryName forKey:@"categoryName"];
		}
		[categoryDictionary setObject:productArray forKey:@"productArray"];
		[categoryDictionary setObject:categoryEarningsTotal forKey:@"categoryEarningsTotal"];
		[categoryDictionary setObject:categoryEarningsTotalFormatted forKey:@"categoryEarningsTotalFormatted"];
		[categoryDictionary setObject:categoryPartnerSplitTotal forKey:@"categoryPartnerSplitTotal"];
		[categoryDictionary setObject:categoryPartnerSplitTotalFormatted forKey:@"categoryPartnerSplitTotalFormatted"];
		
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
	

	NSDecimalNumber *grandEarningsTotal = [NSDecimalNumber zero];
	NSMutableArray *categoryArray = [NSMutableArray array];

	switch (reportCategory) {
		default:
		case 0:
		{
			NSArray *allProducts = [Product fetchAllInManagedObjectContext:managedObjectContext];
			for (Product *product in allProducts) {
				NSString *categoryId = product.vendorId;
				NSString *categoryName = product.name;
				if (!reportCategoryFilter || [categoryId isEqualToString:reportCategoryFilter]) {
					NSArray *products = [NSArray arrayWithObject:product];
					NSDictionary *categoryDictionary = [self createCategoryDictionaryWithName:categoryName withProducts:products fromStartDate:reportStartDate toEndDate:reportEndDate];
					if (categoryDictionary) {
						NSDecimalNumber *categoryEarningsTotal = [categoryDictionary objectForKey:@"categoryEarningsTotal"];
						grandEarningsTotal = [grandEarningsTotal decimalNumberByAdding:categoryEarningsTotal];
						[categoryArray addObject:categoryDictionary];
					}
				}
			}
		}
			break;
		case 1:
		{
			NSArray *allGroups = [Group fetchAllInManagedObjectContext:managedObjectContext];
			for (Group *group in allGroups) {
				NSString *categoryId = group.groupId;
				NSString *categoryName = group.name;
				if (!reportCategoryFilter || [categoryId isEqualToString:reportCategoryFilter]) {
					NSArray *products = [Product fetchAllInManagedObjectContext:managedObjectContext forGroup:group];
					NSDictionary *categoryDictionary = [self createCategoryDictionaryWithName:categoryName withProducts:products fromStartDate:reportStartDate toEndDate:reportEndDate];
					if (categoryDictionary) {
						NSDecimalNumber *categoryEarningsTotal = [categoryDictionary objectForKey:@"categoryEarningsTotal"];
						grandEarningsTotal = [grandEarningsTotal decimalNumberByAdding:categoryEarningsTotal];
						[categoryArray addObject:categoryDictionary];
					}
				}
			}
			
			{
				NSString *categoryId = @"__NONE__";
				NSString *categoryName = @"No Product Group";
				if (!reportCategoryFilter || [categoryId isEqualToString:reportCategoryFilter]) {
					NSArray *products = [Product fetchAllWithoutGroupInManagedObjectContext:managedObjectContext];
					NSDictionary *categoryDictionary = [self createCategoryDictionaryWithName:categoryName withProducts:products fromStartDate:reportStartDate toEndDate:reportEndDate];
					if (categoryDictionary) {
						NSDecimalNumber *categoryEarningsTotal = [categoryDictionary objectForKey:@"categoryEarningsTotal"];
						grandEarningsTotal = [grandEarningsTotal decimalNumberByAdding:categoryEarningsTotal];
						[categoryArray addObject:categoryDictionary];
					}
				}
			}
		}
			break;
		case 2:
		{
			NSArray *allPartners = [Partner fetchAllInManagedObjectContext:managedObjectContext];
			for (Partner *partner in allPartners) {
				NSString *categoryId = partner.partnerId;
				NSString *categoryName = partner.name;
				if (!reportCategoryFilter || [categoryId isEqualToString:reportCategoryFilter]) {
					NSArray *products = [Product fetchAllInManagedObjectContext:managedObjectContext forPartner:partner];
					NSDictionary *categoryDictionary = [self createCategoryDictionaryWithName:categoryName withProducts:products fromStartDate:reportStartDate toEndDate:reportEndDate];
					if (categoryDictionary) {
						NSDecimalNumber *categoryEarningsTotal = [categoryDictionary objectForKey:@"categoryEarningsTotal"];
						grandEarningsTotal = [grandEarningsTotal decimalNumberByAdding:categoryEarningsTotal];
						[categoryArray addObject:categoryDictionary];
					}
				}
			}
			
			{
				NSString *categoryId = @"__NONE__";
				NSString *categoryName = @"No Partner";
				if (!reportCategoryFilter || [categoryId isEqualToString:reportCategoryFilter]) {
					NSArray *products = [Product fetchAllWithoutPartnerInManagedObjectContext:managedObjectContext];
					NSDictionary *categoryDictionary = [self createCategoryDictionaryWithName:categoryName withProducts:products fromStartDate:reportStartDate toEndDate:reportEndDate];
					if (categoryDictionary) {
						NSDecimalNumber *categoryEarningsTotal = [categoryDictionary objectForKey:@"categoryEarningsTotal"];
						grandEarningsTotal = [grandEarningsTotal decimalNumberByAdding:categoryEarningsTotal];
						[categoryArray addObject:categoryDictionary];
					}
				}
			}			
		}
			break;
	}

	if (! self.isCancelled) {
		NSString *reportTitle = [NSString stringWithFormat:@"%@ - %@", [_dateFormatter stringFromDate:reportStartDate], [_dateFormatter stringFromDate:reportEndDate]];
		
		NSMutableDictionary *variables = [NSMutableDictionary dictionary];
		[variables setObject:reportTitle forKey:@"reportTitle"];
		[variables setObject:categoryArray forKey:@"categoryArray"];
		if (! reportCategoryFilter) {
			NSString *grandEarningsTotalFormatted = [_salesFormatter stringFromNumber:grandEarningsTotal];
			[variables setObject:grandEarningsTotalFormatted forKey:@"grandEarningsTotalFormatted"];
		}

		self.reportVariables = [NSDictionary dictionaryWithDictionary:variables];
		
		[_delegate performSelectorOnMainThread:@selector(productEarningsReportOperationCompleted:) withObject:self waitUntilDone:YES];
	}
	
	self.managedObjectContext = nil;
	
	NSDate *reportEnd = [NSDate date];
	DebugLog(@"%s report generated in %f seconds", __PRETTY_FUNCTION__, [reportEnd timeIntervalSinceDate:reportStart]);

	[pool drain];
}

@end
