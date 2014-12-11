//
//  Split.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/19/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Product;

@interface Split : NSManagedObject

@property (nonatomic, retain) NSDate * fromDate;
@property (nonatomic, retain) NSDecimalNumber * percentage;
@property (nonatomic, retain) Product *Product;

@property (nonatomic, assign) NSNumber * beginning;

@end
