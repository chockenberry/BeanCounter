//
//  PlotInformation.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/11/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlotInformation : NSObject
{
	id identifier;
	NSString *name;
	NSColor *color;
}

@property (nonatomic, retain) id identifier;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSColor *color;

@end
