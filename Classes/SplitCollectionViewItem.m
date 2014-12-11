//
//  SplitCollectionViewItem.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/19/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "SplitCollectionViewItem.h"

#import "Split.h"

#import "SplitEditView.h"

#import "DebugLog.h"


@interface SplitCollectionViewItem ()

@end

@implementation SplitCollectionViewItem

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[super dealloc];
}

#pragma mark - Overrides

- (void)setSelected:(BOOL)flag
{
    [super setSelected:flag];

    [(SplitEditView*)[self view] setSelected:flag];
    [(SplitEditView*)[self view] setNeedsDisplay:YES];
}

#pragma mark - Accessors

@end
