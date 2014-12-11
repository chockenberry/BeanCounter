//
//  ReportData.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/16/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ReportData : NSObject
{
	NSString *regionId;
	NSDate *periodDate;
	NSDate *startDate;
	NSDate *endDate;
	NSString *vendorIdentifier;
	NSNumber *quantity;
	NSDecimalNumber *partnerShare;
	NSDecimalNumber *extendedPartnerShare;
	NSString *currency;
	BOOL isReturn;
	NSNumber *appleIdentifier;
	NSString *developerName;
	NSString *productName;
	NSString *productType;
	NSString *countryOfSale;
}

@property (nonatomic, retain) NSString *regionId;
@property (nonatomic, retain) NSDate *periodDate;
@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSString *vendorIdentifier;
@property (nonatomic, retain) NSNumber *quantity;
@property (nonatomic, retain) NSDecimalNumber *partnerShare;
@property (nonatomic, retain) NSDecimalNumber *extendedPartnerShare;
@property (nonatomic, retain) NSString *currency;
@property (nonatomic, assign) BOOL isReturn;
@property (nonatomic, retain) NSNumber *appleIdentifier;
@property (nonatomic, retain) NSString *developerName;
@property (nonatomic, retain) NSString *productName;
@property (nonatomic, retain) NSString *productType;
@property (nonatomic, retain) NSString *countryOfSale;

@end
