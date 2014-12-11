//
//  GraphHostingView.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/13/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <CorePlot/CorePlot.h>

@interface GraphHostingView : CPTGraphHostingView
{
	NSRect printRect;
}

@property (nonatomic, assign) NSRect printRect;

@end
