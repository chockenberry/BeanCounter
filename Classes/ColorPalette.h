//
//  ColorPalette.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/30/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ColorPalette : NSObject
{
	NSArray *colors;
}

+ (ColorPalette *)sharedColorPalette;

- (NSUInteger)paletteCount;
- (NSColor *)colorAtIndex:(NSUInteger)index;

- (NSColor *)randomColor;
- (NSColor *)nextColor;

@end
