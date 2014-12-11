//
//  NSPersistentDocument+FileWrapperSupport.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/26/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
	We need to bypass what NSPersistentDocument does in setFileURL:, but we do want to use the functionality provided by NSDocument's implementation of that method.
	To achieve this, we create a simple category on NSPersistentDocument with methods that will call the NSDocument version of the method. Then, our subclass will
	call the category method where it would normally simply call the super implementation.
 */

@interface NSPersistentDocument (FileWrapperSupport)

- (void)simpleSetFileURL:(NSURL *)fileURL;

@end
