//
//  NSMutableDictionary+Settings.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/25/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Settings)

- (NSInteger)integerForKey:(id)key;
- (void)setInteger:(NSInteger)integer forKey:(id)key;

- (BOOL)boolForKey:(id)key;
- (void)setBool:(BOOL)boolean forKey:(id)key;

@end
