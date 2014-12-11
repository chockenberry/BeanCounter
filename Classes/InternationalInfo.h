//
//  InternationalInfo.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface InternationalInfo : NSObject
{
	NSDictionary *_countryCodes;
	NSDictionary *_countryNames;
	
	NSDictionary *_regionInfo;
}

+ (InternationalInfo *)sharedInternationalInfo;

- (NSString *)countryCodeForName:(NSString *)countryName;
- (NSString *)countryNameForCode:(NSString *)countryCode;

- (NSString *)regionNameForId:(NSString *)regionId;
- (NSString *)regionCurrencyForId:(NSString *)regionId;
- (NSString *)regionCurrencySymbolForId:(NSString *)regionId;

- (NSUInteger)regionCurrencyDigitsForId:(NSString *)regionId;


@end
