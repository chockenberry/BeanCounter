//
//  SourceListOutlineView.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 2/24/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "SourceListOutlineView.h"

@implementation SourceListOutlineView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (BOOL)acceptsFirstResponder
{
	// don't accept the first responder in the source list because it takes it away from the controller of the output view
	return NO;
}

@end
