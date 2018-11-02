//
//  InternationalInfo.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/22/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "InternationalInfo.h"

#import "DebugLog.h"


@implementation InternationalInfo

#pragma mark Thread-safe Singleton

// from: http://eschatologist.net/blog/?p=178

static InternationalInfo *sharedInternationalInfo = nil;
 
+ (void)initialize
{
    if (self == [InternationalInfo class]) {
        sharedInternationalInfo = [[self alloc] init];
    }
}

+ (InternationalInfo *)sharedInternationalInfo
{
    return sharedInternationalInfo;
}

#pragma mark Instance

- (id)init 
{
    self = [super init];
    if (self != nil) {
		NSUInteger capacity = [[NSLocale ISOCountryCodes] count] + 10;
		NSMutableDictionary *countryCodes = [NSMutableDictionary dictionaryWithCapacity:capacity];
		NSMutableDictionary *countryNames = [NSMutableDictionary dictionaryWithCapacity:capacity];
		
		// get country codes and names from US English locale (since that's what's used in the iTunes Connect reports)
		NSLocale *locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
		for (NSString *countryCode in [NSLocale ISOCountryCodes]) {
			NSString *countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
			[countryCodes setObject:countryCode forKey:countryName];
			[countryNames setObject:countryName forKey:countryCode];
		}
		
		// these bizarro names appeared in some of the early iTunes Connect reports
		[countryCodes setObject:@"CZ" forKey:@"Czech. Republic"];
		[countryCodes setObject:@"US" forKey:@"USA"];
		[countryCodes setObject:@"GB" forKey:@"Great Britain"];
		[countryCodes setObject:@"HK" forKey:@"Hong Kong"];
		[countryCodes setObject:@"RU" forKey:@"Russian Fed."];
		[countryCodes setObject:@"AE" forKey:@"Unit.Arab Emir."];
		
		_countryCodes = [[NSDictionary dictionaryWithDictionary:countryCodes] retain];
		_countryNames = [[NSDictionary dictionaryWithDictionary:countryNames] retain];

		_regionInfo = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RegionInfo" ofType:@"plist"]] retain];
   }
    return self;
}

- (NSString *)countryCodeForName:(NSString *)countryName
{
	return [_countryCodes objectForKey:countryName];
}

- (NSString *)countryNameForCode:(NSString *)countryCode
{
	return [_countryNames objectForKey:countryCode];
}

- (NSString *)regionNameForId:(NSString *)regionId;
{
	return [[_regionInfo objectForKey:regionId] objectForKey:@"name"];
}

- (NSString *)regionCurrencyForId:(NSString *)regionId
{
	return [[_regionInfo objectForKey:regionId] objectForKey:@"currency"];
}

- (NSString *)regionCurrencySymbolForId:(NSString *)regionId
{
	return [[_regionInfo objectForKey:regionId] objectForKey:@"currencySymbol"];
}

- (NSUInteger)regionCurrencyDigitsForId:(NSString *)regionId
{
	NSArray *noDigitRegionIds = @[ @"JP", @"CL", @"ID", @"KR", @"PK", @"TW", @"VN" ];
	NSUInteger result = 2;
	if ([noDigitRegionIds containsObject:regionId]) {
		result = 0;
	}
	return result;
}

@end

/*

Americas
--------						
Argentina
Brazil
Chile
Colombia
Costa Rica
Dominican Republic
Ecuador
El Salvador
Guatemala
Honduras
Jamaica
Mexico
Nicaragua
Panama
Paraguay
Peru
Uruguay
Venezuela
United States

Euro Zone
---------
Austria
Belgium
Bulgaria
Czech Republic
Denmark
Estonia
Finland
France
Germany
Greece
Hungary
Ireland
Italy
Latvia
Lithuania
Luxembourg
Malta, Republic of
Netherlands
Norway
Poland
Portugal
Romania
Slovakia
Slovenia
Spain
Sweden
Switzerland

Australia
---------
Australia
New Zealand

Canada
------
Canada

Japan
-----
Japan

United Kingdom
--------------
United Kingdom

Rest of World
-------------
Armenia
Botswana
China
Croatia
Egypt
Hong Kong
India
Indonesia
Israel
Jordan
Kazakhstan
Kenya
Korea
Kuwait
Lebanon
Macau
Macedonia
Madagascar
Mali
Malaysia
Mauritius
Moldova
Niger
Pakistan
Philippines
Qatar
Russia
Saudi Arabia
Singapore
Senegal
South Africa
Sri Lanka
Taiwan
Thailand
Tunisia
Turkey
UAE
Uganda
Vietnam

*/
