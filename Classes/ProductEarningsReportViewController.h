//
//  ProductEarningsReportViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 11/12/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ReportViewController.h"

#import "ProductEarningsReportOperation.h"


#define ROUND_DECIMALS 0

@interface ProductEarningsReportViewController : ReportViewController <ProductEarningsReportOperationDelegate>
{
#if ROUND_DECIMALS
	NSDecimalNumberHandler *_roundingBehavior;
#endif
}

@end