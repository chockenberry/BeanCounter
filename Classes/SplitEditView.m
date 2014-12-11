//
//  SplitEditView.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/19/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "SplitEditView.h"

#import "DebugLog.h"

@implementation SplitEditView

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		_selected = YES;
	}
	
	return self;
}

- (void)setSelected:(BOOL)flag
{
	_selected = flag;
}

- (BOOL)isSelected
{
	return _selected;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (_selected) {
		[[NSColor alternateSelectedControlColor] set];
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect([self bounds], 4.0, 4.0)];
		[path setLineWidth:2.0];
		[path stroke];
		
//		NSRectFill(dirtyRect);
	}
}

/*
- (id)animationForKey:(NSString *)key
{
	DebugLog(@"%s key = %@", __PRETTY_FUNCTION__, key);
	
	if ([key isEqualToString:@"alphaValue"]) {
		CAAnimation *animation = [super animationForKey:key];
		DebugLog(@"%s duration = %f", __PRETTY_FUNCTION__, [animation duration]);
		return animation;
	}
	else {
		return [super animationForKey:key];
	}
}
*/

@end
