//
//  NSMutableDictionary+Settings.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/25/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "NSMutableDictionary+Settings.h"

@implementation NSMutableDictionary (Settings)

- (NSInteger)integerForKey:(id)key
{
	return [[self objectForKey:key] integerValue];
}

- (void)setInteger:(NSInteger)integer forKey:(id)key
{
	[self setObject:[NSNumber numberWithInteger:integer] forKey:key];
}

- (BOOL)boolForKey:(id)key
{
	return [[self objectForKey:key] boolValue];
}

- (void)setBool:(BOOL)boolean forKey:(id)key
{
	[self setObject:[NSNumber numberWithBool:boolean] forKey:key];
}

@end
