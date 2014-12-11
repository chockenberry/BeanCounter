//
//  GraphHostingView.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/13/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "GraphHostingView.h"

@implementation GraphHostingView

@synthesize printRect;

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	if (! [NSGraphicsContext currentContextDrawingToScreen]) {
		NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
		
		[graphicsContext saveGraphicsState];

		NSRect destinationRect = self.printRect;
		NSRect sourceRect = self.frame;
		
		// scale the view isotropically so that it fits on the printed page
		CGFloat widthScale = destinationRect.size.width / sourceRect.size.width;
		CGFloat heightScale = destinationRect.size.height / sourceRect.size.height;
		CGFloat scale = MIN(widthScale, heightScale);
		
		// position the view so that its centered on the printed page
		CGPoint offset = NSZeroPoint;
		offset.x = ((destinationRect.size.width - (sourceRect.size.width * scale)) / 2.0) + destinationRect.origin.x;
		offset.y = ((destinationRect.size.height - (sourceRect.size.height * scale)) / 2.0) + destinationRect.origin.y;

		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform translateXBy:offset.x yBy:offset.y];
		[transform scaleBy:scale];
		[transform concat];
		
		// render CPTLayers recursively into the graphics context used for printing (thanks to Brad for the tip: http://stackoverflow.com/a/2791305/132867 )
		CGContextRef context = [graphicsContext graphicsPort];
		[self.hostedGraph recursivelyRenderInContext:context];

		[graphicsContext restoreGraphicsState];
	}
}

- (BOOL)knowsPageRange:(NSRangePointer)rangePointer
{
    rangePointer->location = 1;
    rangePointer->length = 1;
	
    return YES;
}

- (NSRect)rectForPage:(NSInteger)pageNumber
{
	return self.printRect;
}

@end
