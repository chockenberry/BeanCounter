//
//  NSError+Reporting.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "NSError+Reporting.h"

@implementation NSError (Reporting)

+ (id)errorWithCode:(NSInteger)code filePath:(NSString *)filePath description:(NSString *)description
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
	if (filePath) {
		[userInfo setObject:filePath forKey:NSFilePathErrorKey];
	}
	
	return [NSError errorWithDomain:@"com.iconfactory.BeanCounter" code:code userInfo:userInfo];
}

- (NSString *)errorFilePath
{
	return [[self userInfo] objectForKey:NSFilePathErrorKey];
}

- (NSString *)errorFileName
{
	return [[self errorFilePath] lastPathComponent];
}

- (NSNumber *)codeNumber
{
	return [NSNumber numberWithInteger:[self code]];
}


@end
