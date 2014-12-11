//
//  ProductSalesChartViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 3/2/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

#import "ChartViewController.h"

#import "ProductSalesChartOperation.h"

#import "CorePlot/CorePlot.h"

@interface ProductSalesChartViewController : ChartViewController <CPTPlotSpaceDelegate, CPTPlotDataSource, CPTBarPlotDelegate, CPTScatterPlotDelegate, ProductSalesChartOperationDelegate>
{
}

@end
