//
//  EditAccountViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/1/12.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import "EditAccountViewController.h"

#import "DebugLog.h"


@interface EditAccountViewController ()

@end


@implementation EditAccountViewController

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

- (void)awakeFromNib
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

#pragma mark - Methods

#pragma mark - Actions

#pragma mark - Utility

@end
