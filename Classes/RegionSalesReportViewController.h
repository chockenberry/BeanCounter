//
//  RegionSalesReportViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 11/12/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ReportViewController.h"

#import "RegionSalesReportOperation.h"


@interface RegionSalesReportViewController : ReportViewController <RegionSalesReportOperationDelegate>
{
}

@end