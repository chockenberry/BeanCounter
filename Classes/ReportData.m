//
//  ReportData.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/16/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ReportData.h"


@implementation ReportData

@synthesize regionId;
@synthesize periodDate;
@synthesize startDate;
@synthesize endDate;
@synthesize vendorIdentifier;
@synthesize quantity;
@synthesize partnerShare;
@synthesize extendedPartnerShare;
@synthesize currency;
@synthesize isReturn;
@synthesize appleIdentifier;
@synthesize developerName;
@synthesize productName;
@synthesize productType;
@synthesize countryOfSale;

- (NSString *)description
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[numberFormatter setMinimumFractionDigits:2];
	//[numberFormatter setCurrencyCode:currency];
	
	return [NSString stringWithFormat:@"%@ %@: %@ (%@, %@) - %s %@ @ %@ %@ (%@)",
			regionId, [dateFormatter stringFromDate:periodDate],
			productName, vendorIdentifier, appleIdentifier,
			(isReturn ? "Refunded" : "Sold"), quantity, [numberFormatter stringFromNumber:partnerShare], currency, countryOfSale];
}

@end
