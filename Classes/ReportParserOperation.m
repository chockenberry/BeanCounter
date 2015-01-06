//
//  ReportParserOperation.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/20/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ReportParserOperation.h"

#import "Sale.h"
#import "Region.h"
#import "ReportData.h"
#import "InternationalInfo.h"
#import "NSError+Reporting.h"

#import "DebugLog.h"

@implementation ReportParserOperation

@synthesize reportPath;
@synthesize accountNumber;
@synthesize reportDataValues;
@synthesize reportError;

- (id)initWithReportPath:(NSString *)theReportPath checkingAccountNumber:(NSString *)theAccountNumber withManagedObjectContext:(NSManagedObjectContext *)theManagedObjectContext delegate:(NSObject <ReportParserDelegate> *)theDelegate;
{
	if ((self = [super init])) {
		reportPath = [theReportPath copy];
		accountNumber = [theAccountNumber copy];
		
		_managedObjectContext = theManagedObjectContext;
		_delegate = theDelegate;
	}
	
	return self;
}

- (void)dealloc
{
	[reportError release];
	[reportPath release];
	[accountNumber release];
	[reportDataValues release];

	_managedObjectContext = nil;
	_delegate = nil;
	
	[super dealloc];
}

#define DEBUG_FIELDS 0

- (void)main
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	InternationalInfo *internationalInfo = [InternationalInfo sharedInternationalInfo];

	NSManagedObjectContext *managedObjectContext = _managedObjectContext;

	
	NSDateComponents *periodEndDateComponents = [[[NSDateComponents alloc] init] autorelease];
	periodEndDateComponents.month = 1;

	self.reportDataValues = nil;

	NSError *error = nil;
	NSString *fileData = [NSString stringWithContentsOfFile:reportPath encoding:NSUTF8StringEncoding error:&error];
	if (! fileData) {
		self.reportError = error;
		ReleaseLog(@"%s failed to open report, error = %@", __PRETTY_FUNCTION__, error);

		SEL selector = @selector(reportParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		
		[pool drain];
		return;
	}

	NSString *reportFile = [reportPath lastPathComponent];
	NSString *reportName = [reportFile stringByDeletingPathExtension];
	NSArray *reportNameComponents = [reportName componentsSeparatedByString:@"_"];
	if ([reportNameComponents count] == 4 && [[reportNameComponents lastObject] isEqualToString:@"PYMT"]) {
		NSString *errorDescription = @"Skipping file, PYMT contains no sales information";
		self.reportError = [NSError errorWithCode:ReportParserOperationWarning filePath:reportPath description:errorDescription];
		
		SEL selector = @selector(reportParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		
		[pool drain];
		return;
	}
	if ([reportNameComponents count] != 3) {
		NSString *errorDescription = @"File name is not formatted with an account number, time period and region identifier";
		self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];

		SEL selector = @selector(reportParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		
		[pool drain];
		return;
	}

	NSString *reportAccountNumber = [reportNameComponents objectAtIndex:0];
	NSString *reportPeriod = [reportNameComponents objectAtIndex:1];
	NSString *reportRegionId = [reportNameComponents objectAtIndex:2];
	if (!reportAccountNumber || !reportPeriod || !reportRegionId || [reportAccountNumber length] == 0 || [reportPeriod length] != 4 || [reportRegionId length] != 2) {
		NSString *errorDescription = [NSString stringWithFormat:@"File name account number of '%@', 4 digit report period of '%@' or 2 digit region identifier of '%@' is missing", reportAccountNumber, reportPeriod, reportRegionId];
		self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];

		SEL selector = @selector(reportParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		
		[pool drain];
		return;
	}

	NSString *regionName = [internationalInfo regionNameForId:reportRegionId];
	if (! regionName) {
		NSString *errorDescription = [NSString stringWithFormat:@"Cannot import sales in region '%@', update this application to get latest iTunes regions", reportRegionId];
		self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];
		
		SEL selector = @selector(reportParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		
		[pool drain];
		return;
	}
	
	if (accountNumber && [accountNumber length] > 0 && ![accountNumber isEqualToString:reportAccountNumber]) {
		NSString *errorDescription = [NSString stringWithFormat:@"Skipping file, account number does not match '%@'", accountNumber];
		self.reportError = [NSError errorWithCode:ReportParserOperationWarning filePath:reportPath description:errorDescription];

		SEL selector = @selector(reportParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		
		[pool drain];
		return;
	}
	
	NSDateFormatter *periodDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[periodDateFormatter setDateFormat:@"MMyy"];
	NSDate *periodDate = [periodDateFormatter dateFromString:reportPeriod];
	NSDate *earliestPeriodDate = [periodDateFormatter dateFromString:@"0708"];
	if (! periodDate || ([periodDate timeIntervalSinceDate:earliestPeriodDate] < 0.0)) {
		NSString *errorDescription = [NSString stringWithFormat:@"File name uses an invalid report period date of '%@'", reportPeriod];
		self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];
		
		SEL selector = @selector(reportParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];

		[pool drain];
		return;
	}
	
	// TODO: check if there are any existing sales for the period & region
	Region *region = [Region fetchInManagedObjectContext:managedObjectContext withId:reportRegionId];
	NSDate *periodEndDate = [[NSCalendar currentCalendar] dateByAddingComponents:periodEndDateComponents toDate:periodDate options:0];
	NSUInteger salesCount = [Sale countAllInManagedObjectContext:managedObjectContext forRegion:region startDate:periodDate endDate:periodEndDate];
	if (salesCount > 0) {
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		dateFormatter.dateFormat = @"MMMM yyyy";
		NSString *periodDateFormatted = [dateFormatter stringFromDate:periodDate];

		NSString *errorDescription = [NSString stringWithFormat:@"Skipping file, financial data for %@ in %@ has already been imported", periodDateFormatted, region.name];
		self.reportError = [NSError errorWithCode:ReportParserOperationWarning filePath:reportPath description:errorDescription];
		
		SEL selector = @selector(reportParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		
		[pool drain];
		return;
	}
	
	NSUInteger startDateIndex = 0;
	NSUInteger endDateIndex = 0;
	NSUInteger vendorIdentifierIndex = 0;
	NSUInteger quantityIndex = 0;
	NSUInteger partnerShareIndex = 0;
	NSUInteger extendedPartnerShareIndex = 0;
	NSUInteger currencyIndex = 0;
	NSUInteger isReturnIndex = 0;
	NSUInteger appleIdentifierIndex = 0;
	NSUInteger developerNameIndex = 0;
	NSUInteger productNameIndex = 0;
	NSUInteger productTypeIndex = 0;
	NSUInteger countryOfSaleIndex = 0;

	NSDateFormatter *usDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[usDateFormatter setDateStyle:NSDateFormatterShortStyle];
    [usDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
	NSDateFormatter *internationalDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[internationalDateFormatter setDateFormat:@"dd.MM.yyyy"];
	
	NSMutableArray *parsedDataValues = [NSMutableArray array];

#if DEBUG_FIELDS	
	NSArray *debugHeaders = nil;
#endif
	
	BOOL firstLine = YES;
	NSArray *lines = [fileData componentsSeparatedByString:@"\n"];
	if ([lines count] == 1) {
		// lines aren't terminated with a newline, try a return
		lines = [fileData componentsSeparatedByString:@"\r"];
	}
	if (! ([lines count] > 1)) {
		NSString *errorDescription = @"No lines of data to parse";
		self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];
		
		SEL selector = @selector(reportParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		
		[pool drain];
		return;
	}
	
	for (NSString *line in lines) {
		NSArray *columns = [line componentsSeparatedByString:@"\t"];
		if (firstLine) {
#if DEBUG_FIELDS	
			debugHeaders = [NSArray arrayWithArray:columns];
#endif
			//DebugLog(@"%s headers = %@", __PRETTY_FUNCTION__, columns);
			NSUInteger index = 0;
			for (NSString *column in columns) {
				if ([column isEqualToString:@"Start Date"]) {
					startDateIndex = index;
				}
				else if ([column isEqualToString:@"End Date"]) {
					endDateIndex = index;
				}
				else if ([column isEqualToString:@"Vendor Identifier"]) {
					vendorIdentifierIndex = index;
				}
				else if ([column isEqualToString:@"Quantity"]) {
					quantityIndex = index;
				}
				else if ([column isEqualToString:@"Partner Share"]) {
					partnerShareIndex = index;
				}
				else if ([column isEqualToString:@"Extended Partner Share"]) {
					extendedPartnerShareIndex = index;
				}
				else if ([column isEqualToString:@"Partner Share Currency"]) {
					currencyIndex = index;
				}
				else if ([column isEqualToString:@"Sales or Return"] || [column isEqualToString:@"Sale or Return"]) {
					isReturnIndex = index;
				}
				else if ([column isEqualToString:@"Apple Identifier"]) {
					appleIdentifierIndex = index;
				}
				else if ([column isEqualToString:@"Artist/Show/Developer/Author"] || [column isEqualToString:@"Artist/Show/Developer"]) {
					developerNameIndex = index;
				}
				else if ([column isEqualToString:@"Title"]) {
					productNameIndex = index;
				}
				else if ([column isEqualToString:@"Product Type Identifier"]) {
					productTypeIndex = index;
				}
				else if ([column isEqualToString:@"Country Of Sale"]) {
					countryOfSaleIndex = index;
				}
				
				index += 1;
			}
			
			firstLine = NO;
		}
		else {
			//DebugLog(@"%s data = %@", __PRETTY_FUNCTION__, columns);
			if ([columns count] <= 10 || [[columns objectAtIndex:0] length] == 0 || [[columns objectAtIndex:0] hasPrefix:@"Total_Amount"]) {
				// summary lines
// TODO: perform some data validation using the summary fields (e.g. sum the extendedPartnerShare and compare against the total
				break;
			}
			else {
#if DEBUG_FIELDS	
				for (NSUInteger i = 0; i < [columns count]; i++) {
					DebugLog(@"'%@' = '%@'", [debugHeaders objectAtIndex:i], [columns objectAtIndex:i]);
				}
				DebugLog(@"==================================================================");
#endif

				// data line
				ReportData *reportData = [[[ReportData alloc] init] autorelease];
				reportData.regionId = reportRegionId;
				reportData.periodDate = periodDate;
				reportData.startDate = [usDateFormatter dateFromString:[columns objectAtIndex:startDateIndex]];
				if (! reportData.startDate) {
					reportData.startDate = [internationalDateFormatter dateFromString:[columns objectAtIndex:startDateIndex]];
				}
				reportData.endDate = [usDateFormatter dateFromString:[columns objectAtIndex:endDateIndex]];
				if (! reportData.endDate) {
					reportData.endDate = [internationalDateFormatter dateFromString:[columns objectAtIndex:endDateIndex]];
				}
				if (reportData.startDate == nil || reportData.endDate == nil) {
					NSString *errorDescription = [NSString stringWithFormat:@"Invalid start date of '%@' or end date of '%@'", [columns objectAtIndex:startDateIndex], [columns objectAtIndex:endDateIndex]];
					self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];
					
					SEL selector = @selector(reportParserOperationDidFail:);
					[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
					
					[pool drain];
					return;
				}

				// some reports included commas in the extended partner share field (e.g. 3,801.00 in 80045102_1008_US.txt)
				NSString *cleanExtendedPartnerShare = [[columns objectAtIndex:extendedPartnerShareIndex] stringByReplacingOccurrencesOfString:@"," withString:@""];
				
				if (! ([[columns objectAtIndex:appleIdentifierIndex] length] > 0)) {
					NSString *errorDescription = @"Missing Apple identifier";
					self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];
					
					SEL selector = @selector(reportParserOperationDidFail:);
					[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
					
					[pool drain];
					return;
				}
				
				reportData.vendorIdentifier = [columns objectAtIndex:vendorIdentifierIndex];
				reportData.quantity = [NSNumber numberWithInteger:[[columns objectAtIndex:quantityIndex] integerValue]];
				reportData.partnerShare = [NSDecimalNumber decimalNumberWithString:[columns objectAtIndex:partnerShareIndex]];
				reportData.extendedPartnerShare = [NSDecimalNumber decimalNumberWithString:cleanExtendedPartnerShare];
				reportData.currency = [columns objectAtIndex:currencyIndex];
				reportData.isReturn = [[columns objectAtIndex:isReturnIndex] isEqualToString:@"R"];
				reportData.appleIdentifier = [NSNumber numberWithInteger:[[columns objectAtIndex:appleIdentifierIndex] integerValue]];
				reportData.developerName = [columns objectAtIndex:developerNameIndex];
				reportData.productName = [columns objectAtIndex:productNameIndex];
				reportData.productType = [columns objectAtIndex:productTypeIndex];
				NSString *countryOfSale = [columns objectAtIndex:countryOfSaleIndex];
				NSString *countryCode = [internationalInfo countryCodeForName:countryOfSale];
				if (countryCode) {
					reportData.countryOfSale = countryCode;
				}
				else {
					reportData.countryOfSale = countryOfSale;
				}

				// TODO: perform some data validation by comparing extendedPartnerShare and (quantity * partnerShare)
				NSDecimalNumber *computedExtendedPartnerShare = [reportData.partnerShare decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[reportData.quantity decimalValue]]];
				if (! [reportData.extendedPartnerShare isEqualToNumber:computedExtendedPartnerShare]) {
					NSString *errorDescription = [NSString stringWithFormat:@"Extended partner share of '%@' doesn't match partner share of '%@' and quantity of '%@'", reportData.extendedPartnerShare, reportData.partnerShare, reportData.quantity];
					self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];
					
					SEL selector = @selector(reportParserOperationDidFail:);
					[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
					
					[pool drain];
					return;
				}
				
				if (! ([reportData.countryOfSale length] == 2)) {
					NSString *errorDescription = [NSString stringWithFormat:@"Invalid country code of '%@'", reportData.countryOfSale];
					self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];
					
					SEL selector = @selector(reportParserOperationDidFail:);
					[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
					
					[pool drain];
					return;
				}
				
				if (! ([reportData.productName length] > 0) || ! ([reportData.vendorIdentifier length] > 0)) {
					NSString *errorDescription = @"Missing product name or vendor identifier";
					self.reportError = [NSError errorWithCode:ReportParserOperationError filePath:reportPath description:errorDescription];
					
					SEL selector = @selector(reportParserOperationDidFail:);
					[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];

					[pool drain];
					return;
				}
				
				// skip free product sales in older reports
				if (! [reportData.partnerShare isEqualToNumber:[NSDecimalNumber zero]]) {
					[parsedDataValues addObject:reportData];
				}
			}
		}
	}
	
	self.reportDataValues = [NSArray arrayWithArray:parsedDataValues];

	SEL selector = @selector(reportParserOperationDidSucceed:);
	[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
//	DebugLog(@"%s reportDataValues = %@", __PRETTY_FUNCTION__, reportDataValues);
	
	[pool drain];
}

@end
