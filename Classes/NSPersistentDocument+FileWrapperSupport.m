//
//  NSPersistentDocument+FileWrapperSupport.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/26/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "NSPersistentDocument+FileWrapperSupport.h"

@implementation NSPersistentDocument (FileWrapperSupport)

- (void)simpleSetFileURL:(NSURL *)fileURL {
	// forward the message to NSDocument's setFileURL: (skipping NSPersistentDocument's implementation)
    [super setFileURL:fileURL];   
}

@end
