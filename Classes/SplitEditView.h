//
//  SplitEditView.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/19/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SplitEditView : NSView
{
	BOOL _selected;
}

- (void)setSelected:(BOOL)flag;
- (BOOL)isSelected;

@end
