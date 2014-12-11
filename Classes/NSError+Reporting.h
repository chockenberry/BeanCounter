//
//  NSError+Reporting.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/29/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Reporting)

+ (id)errorWithCode:(NSInteger)code filePath:(NSString *)filePath description:(NSString *)description;

- (NSString *)errorFilePath;
- (NSString *)errorFileName;

- (NSNumber *)codeNumber;

@end
