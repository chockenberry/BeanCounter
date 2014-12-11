//
//  ErrorCodeValueTransformer.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "ErrorCodeValueTransformer.h"

@implementation ErrorCodeValueTransformer

+ (Class)transformedValueClass
{
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	NSImage *result = nil;
	
	if (value && [value isKindOfClass:[NSNumber class]]) {
		NSInteger integerValue = [value integerValue];
		if (integerValue == 0) {
			result = [NSImage imageNamed:@"info.png"];
		}
		else if ([value integerValue] < 0) {
			result = [NSImage imageNamed:@"error.png"];
		}
		else {
			result = [NSImage imageNamed:@"warning.png"];
		}
	}

    return result;
}


@end
