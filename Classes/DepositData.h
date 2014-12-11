//
//  DepositData.h
//  BeanCounter
//
//  Created by Craig Hockenberry onm 2/26/12.
//  Copyright 2012 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DepositData : NSObject <NSCoding>
{
	NSString *regionId;
	NSDate *date;
	NSDecimalNumber *balance;
	NSDecimalNumber *sales;
	NSDecimalNumber *adjustments;
	NSDecimalNumber *rate;
	NSDecimalNumber *deposit;
}

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *regionId;
@property (nonatomic, retain) NSDecimalNumber *balance;
@property (nonatomic, retain) NSDecimalNumber *sales;
@property (nonatomic, retain) NSDecimalNumber *adjustments;
@property (nonatomic, retain) NSDecimalNumber *rate;
@property (nonatomic, retain) NSDecimalNumber *deposit;

- (NSDecimalNumber *)subtotal;
- (NSDecimalNumber *)computedRate;

@end
