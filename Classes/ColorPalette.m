//
//  ColorPalette.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/30/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "ColorPalette.h"

@interface ColorPalette ()

@property (nonatomic, retain) NSArray *colors;

@end

@implementation ColorPalette


@synthesize colors;

#pragma mark Thread-safe Singleton

// from: http://eschatologist.net/blog/?p=178

static ColorPalette *sharedColorPalette = nil;

+ (void)initialize
{
    if (self == [ColorPalette class]) {
        sharedColorPalette = [[self alloc] init];
    }
}

+ (ColorPalette *)sharedColorPalette
{
    return sharedColorPalette;
}

- (id)init 
{
    self = [super init];
    if (self != nil) {
		colors = [[NSArray arrayWithObjects:
				[NSColor colorWithCalibratedRed:0.98 green:1.00 blue:0.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.96 green:0.84 blue:0.47 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.95 green:0.44 blue:1.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.93 green:0.57 blue:0.05 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.93 green:0.47 blue:0.47 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.93 green:0.00 blue:1.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.92 green:0.00 blue:0.57 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.91 green:0.00 blue:0.08 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.85 green:1.00 blue:0.47 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.80 green:0.44 blue:1.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.64 green:1.00 blue:0.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.61 green:1.00 blue:1.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.60 green:1.00 blue:0.83 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.58 green:1.00 blue:0.47 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.57 green:0.83 blue:1.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.56 green:0.00 blue:1.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.51 green:0.44 blue:1.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.46 green:1.00 blue:1.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.42 green:1.00 blue:0.56 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.41 green:1.00 blue:0.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.32 green:0.55 blue:1.00 alpha:1.0],
				[NSColor colorWithCalibratedRed:0.24 green:0.00 blue:1.00 alpha:1.0],
				nil] retain];
		
		srand(time(0));
	}
    return self;
}

- (NSUInteger)paletteCount
{
	return [colors count];
}

- (NSColor *)colorAtIndex:(NSUInteger)index
{
	NSUInteger max = self.paletteCount;
	return [colors objectAtIndex:(index % max)];
}

int RandomUnder(int topPlusOne)
{
	unsigned two31 = 1U << 31;
	unsigned maxUsable = (two31 / topPlusOne) * topPlusOne;
	
	while (1) {
		unsigned num = random();
		if(num < maxUsable)
			return num % topPlusOne;
	}
}

- (NSColor *)randomColor
{
	NSUInteger randomIndex = RandomUnder(self.paletteCount);
	return [colors objectAtIndex:randomIndex];
}

- (NSColor *)nextColor
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSUInteger colorPaletteCounter = [userDefaults integerForKey:@"colorPaletteCounter"];
	NSUInteger index = colorPaletteCounter;
	colorPaletteCounter += 1;
	[userDefaults setInteger:colorPaletteCounter forKey:@"colorPaletteCounter"];

	return [self colorAtIndex:index];
}

@end
