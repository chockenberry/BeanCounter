//
//  ProductEarningsChartViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/2/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "ChartViewController.h"

#import "ProductEarningsChartOperation.h"

#import "CorePlot/CorePlot.h"

@interface ProductEarningsChartViewController : ChartViewController <CPTPlotSpaceDelegate, CPTPlotDataSource, CPTBarPlotDelegate, CPTScatterPlotDelegate, ProductEarningsChartOperationDelegate>
{
}

@end
