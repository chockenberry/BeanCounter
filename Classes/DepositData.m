//
//  DepositData.m
//  BeanCounter
//
//  Created by Craig Hockenberry onm 2/26/12.
//  Copyright 2012 The Iconfactory. All rights reserved.
//

#import "DepositData.h"


@implementation DepositData

@synthesize regionId;
@synthesize date;
@synthesize balance;
@synthesize sales;
@synthesize adjustments;
@synthesize rate;
@synthesize deposit;


- (NSDecimalNumber *)subtotal
{
	return [balance decimalNumberByAdding:[sales decimalNumberByAdding:adjustments]];
}

- (NSDecimalNumber *)computedRate
{
	return [deposit decimalNumberByDividingBy:[self subtotal]];
}

- (NSString *)description
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	
	return [NSString stringWithFormat:@"%@ %@: %@ balance + %@ sales + %@ adj = %@ = %@ @ %@",
			regionId, [dateFormatter stringFromDate:date],
			balance, sales, adjustments, [self subtotal], deposit, rate];
}

#pragma mark - NSCoding methods

-(void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.regionId forKey:@"regionId"];
	[coder encodeObject:self.date forKey:@"date"];
	[coder encodeObject:self.balance forKey:@"balance"];
	[coder encodeObject:self.sales forKey:@"sales"];
	[coder encodeObject:self.adjustments forKey:@"adjustments"];
	[coder encodeObject:self.rate forKey:@"rate"];
	[coder encodeObject:self.deposit forKey:@"deposit"];
}

-(id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super init])) {
		regionId = [[coder decodeObjectForKey:@"regionId"] retain];
		date = [[coder decodeObjectForKey:@"date"] retain];
		balance	= [[coder decodeObjectForKey:@"balance"] retain];
		sales = [[coder decodeObjectForKey:@"sales"] retain];
		adjustments = [[coder decodeObjectForKey:@"adjustments"] retain];
		rate = [[coder decodeObjectForKey:@"rate"] retain];
		deposit = [[coder decodeObjectForKey:@"deposit"] retain];
	}
	return self;
}

@end
