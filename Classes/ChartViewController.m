//
//  ChartViewController.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/30/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "ChartViewController.h"

#import "NSMutableDictionary+Settings.h"
#import "CPTCalendarFormatter.h"

#import "DebugLog.h"

@interface ChartViewController ()

- (void)initializeChart;

- (void)updateFilterPopUpButton;

@end


@implementation ChartViewController

@synthesize graphHostingView;
@synthesize filterPopUpButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		_operationQueue = [[NSOperationQueue alloc] init];
		[_operationQueue setMaxConcurrentOperationCount:1];
		
		_chartVariablesCache = [[NSMutableDictionary dictionary] retain];
		_chartMaximumCache = [[NSNumber numberWithInteger:0] retain];
	}
    
    return self;
}

- (void)dealloc
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);

	[_operationQueue cancelAllOperations];
	
	[_operationQueue release];
	[_chartVariablesCache release];
	[_chartMaximumCache release];
	
	[settings removeObserver:self forKeyPath:@"chartCategory"];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[graphHostingView release];

	[super dealloc];
}

- (void)awakeFromNib
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[self initializeChart];

	[self updateFilterPopUpButton];
}

- (void)viewDidAppear
{
	if (self.graphHostingView.window) {
		self.graphHostingView.hostedGraph.contentsScale = self.graphHostingView.window.backingScaleFactor;
	}
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	DebugLog(@"%s keyPath = %@, object = %@", __PRETTY_FUNCTION__, keyPath, object);
	
	if ([keyPath isEqualToString:@"chartCategory"]) {
		[self willChangeValueForKey:@"filterChoices"];
		[self didChangeValueForKey:@"filterChoices"];
		
		[self updateFilterPopUpButton];
	}
}


#pragma mark - Accessors

- (void)setSettings:(NSMutableDictionary *)newSettings
{
	if (newSettings != settings) {
		[settings removeObserver:self forKeyPath:@"chartCategory"];

		[settings release];
		settings = [newSettings retain];
	
		[settings addObserver:self forKeyPath:@"chartCategory" options:0 context:NULL];
	}
}

- (NSArray *)filterChoices
{
	NSArray *result = nil;
	
	NSInteger chartCategory = [self.settings integerForKey:@"chartCategory"];
	switch (chartCategory) {
		default:
		case 0:
		{
			NSMutableArray *choices = [NSMutableArray array];
			[choices addObject:[NSDictionary dictionaryWithObject:@"All" forKey:@"name"]];
			[choices addObjectsFromArray:[Product fetchAllInManagedObjectContext:managedObjectContext]];
			result = [NSArray arrayWithArray:choices];
		}
			break;
		case 1:
		{
			NSMutableArray *choices = [NSMutableArray array];
			[choices addObject:[NSDictionary dictionaryWithObject:@"All" forKey:@"name"]];
			[choices addObjectsFromArray:[Group fetchAllInManagedObjectContext:managedObjectContext]];
			result = [NSArray arrayWithArray:choices];
		}
			break;
		case 2:
		{
			NSMutableArray *choices = [NSMutableArray array];
			[choices addObject:[NSDictionary dictionaryWithObject:@"All" forKey:@"name"]];
			[choices addObjectsFromArray:[Partner fetchAllInManagedObjectContext:managedObjectContext]];
			result = [NSArray arrayWithArray:choices];
		}
			break;
	}
	
	return result;
}

- (NSInteger)filterChoiceIndex
{
	NSInteger chartCategory = [self.settings integerForKey:@"chartCategory"];
	NSInteger result;
	switch (chartCategory) {
		default:
		case 0:
			result = [self.settings integerForKey:@"chartFilterProducts"];
			if (result > [[Product fetchAllInManagedObjectContext:managedObjectContext] count]) {
				result = 0;
			}
			break;
		case 1:
			result = [self.settings integerForKey:@"chartFilterGroup"];
			if (result > [[Group fetchAllInManagedObjectContext:managedObjectContext] count]) {
				result = 0;
			}
			break;
		case 2:
			result = [self.settings integerForKey:@"chartFilterPartner"];
			if (result > [[Partner fetchAllInManagedObjectContext:managedObjectContext] count]) {
				result = 0;
			}
			break;
	}
	
	return result;
}

- (NSString *)filterChoice
{
	NSString *result = nil;

	NSInteger index = [self filterChoiceIndex];
	NSArray *filterChoices = [self filterChoices];
	id filterChoice = [filterChoices objectAtIndex:index];
	
	NSInteger chartCategory = [self.settings integerForKey:@"chartCategory"];
	switch (chartCategory) {
		default:
		case 0:
			result = [filterChoice vendorId];
			break;
		case 1:
			result = [filterChoice groupId];
			break;
		case 2:
			result = [filterChoice partnerId];
			break;
	}

	return result;
}

- (NSArray *)regionChoices
{
	return [Region fetchAllInManagedObjectContext:self.managedObjectContext];
}

- (NSInteger)regionChoiceIndex
{
	return [self.settings integerForKey:@"chartRegion"];
}

- (Region *)regionChoice
{
	Region *result = nil;
	
	NSInteger index = [self regionChoiceIndex];
	NSArray *regionChoices = [self regionChoices];
	if (index >= 0 && index < [regionChoices count]) {
		result = [regionChoices objectAtIndex:index];
	}
	
	return result;
}

#pragma mark - Utility

- (NSDate *)earliestDateForChartPeriod:(NSUInteger)chartPeriod
{
	NSDate *result = nil;

#if 0
	// this will make sense if chart period is adjusted to fit the product...
	NSArray *products = [Product fetchAllInManagedObjectContext:self.managedObjectContext];
	if (products && [products count] > 0) {
		result = [NSDate distantFuture];
		
		for (Product *product in products) {
			NSDate *minimumSaleDate = [Sale minimumDateInManagedObjectContext:self.managedObjectContext forProduct:product];
			result = [result earlierDate:minimumSaleDate];
		}
	}
#else
	result = [Sale fastMinimumDateInManagedObjectContext:self.managedObjectContext];
#endif
	
	// move the date to the beginning of the year
	NSDateComponents *normalizedDateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:result];
	normalizedDateComponents.month = 1;
	result = [[NSCalendar currentCalendar] dateFromComponents:normalizedDateComponents];
	
	return result;
}

- (NSDate *)latestDateForChartPeriod:(NSUInteger)chartPeriod
{
	NSDate *result = nil;

#if 0
	// this will make sense if chart period is adjusted to fit the product...
	NSArray *products = [Product fetchAllInManagedObjectContext:self.managedObjectContext];
	if (products && [products count] > 0) {
		result = [NSDate distantPast];
		
		for (Product *product in products) {
			NSDate *maximumSaleDate = [Sale maximumDateInManagedObjectContext:self.managedObjectContext forProduct:product];
			result = [result laterDate:maximumSaleDate];
		}
	}
#else
	result = [Sale fastMaximumDateInManagedObjectContext:self.managedObjectContext];
#endif
	
	if (chartPeriod == 1) {
		// if chart period is a year, move the date to the beginning of the year
		NSDateComponents *normalizedDateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:result];
		normalizedDateComponents.month = 1;
		result = [[NSCalendar currentCalendar] dateFromComponents:normalizedDateComponents];
	}
	
	return result;
}

- (NSCalendarUnit)calendarUnitForChartPeriod:(NSUInteger)chartPeriod
{
	NSCalendarUnit result = 0;
	switch (chartPeriod) {
		default:
		case 0:
			// month
			result = NSCalendarUnitMonth;
			break;
		case 1:
			// year
			result = NSCalendarUnitYear;
			break;
	}
	
	return result;
}

- (NSUInteger)intervalCountForChartPeriod:(NSUInteger)chartPeriod
{
	NSUInteger result = 0;
	
	NSCalendarUnit calendarUnit = [self calendarUnitForChartPeriod:chartPeriod];
	NSDate *earliestDate = [self earliestDateForChartPeriod:chartPeriod];
	NSDate *latestDate = [self latestDateForChartPeriod:chartPeriod];
	if (earliestDate && latestDate) {
		NSDateComponents *components = [[NSCalendar currentCalendar] components:calendarUnit fromDate:earliestDate toDate:latestDate options:0];
		switch (chartPeriod) {
			default:
			case 0:
				// month
				result = components.month + 1;
				break;
			case 1:
				// year
				result = components.year + 1;
				break;
		}
	}
	
	return result;
}

- (CPTScatterPlot *)plotWithIdentifier:(NSString *)identifier usingTitle:(NSString *)title andColor:(NSColor *)color
{
	CPTScatterPlot *result = [[[CPTScatterPlot alloc] init] autorelease];
	
	CPTColor *plotColor = [CPTColor colorWithComponentRed:[color redComponent] green:[color greenComponent] blue:[color blueComponent] alpha:1.0];
	
	CPTPlotSymbol *plotSymbol = [[[CPTPlotSymbol alloc] init] autorelease];
	plotSymbol.symbolType = CPTPlotSymbolTypeRectangle;
	plotSymbol.lineStyle = nil;
	plotSymbol.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
	plotSymbol.size = CGSizeMake(10.0, 10.0);
	
	result.plotSymbol = plotSymbol;
	
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.lineWidth = 2.0f;
	lineStyle.lineColor = plotColor;
	lineStyle.lineJoin = kCGLineJoinBevel;
	result.dataLineStyle = lineStyle;
	
	result.title = title;
	
	result.dataSource = nil; // no data source until the operation completes
	result.delegate = self;
	result.identifier = identifier;
	
	return result;
}

#pragma mark - Overrides

- (BOOL)usesRegion
{
	return NO;
}

- (NSOperation *)operationForChartCategory:(NSUInteger)category usingObject:(NSManagedObject *)object inRegion:(Region *)region asTotal:(BOOL)total withPeriod:(NSUInteger)period count:(NSUInteger)count from:(NSDate *)fromDate
{
	return nil;
}

- (NSNumberFormatter *)numberFormatterInRegion:(Region *)region
{
	NSNumberFormatter *result = [[[NSNumberFormatter alloc] init] autorelease];
	result.numberStyle = NSNumberFormatterDecimalStyle;
	
	return result;
}

- (NSString *)chartTitleInRegion:(Region *)region
{
	return @"";
}

#pragma mark - Methods

- (void)initializeChart
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	
	[_operationQueue cancelAllOperations];
	
	NSUInteger chartPeriod = [self.settings integerForKey:@"chartPeriod"];
	BOOL chartShowTotal = [self.settings boolForKey:@"chartShowTotal"];
	NSUInteger chartCategory = [self.settings integerForKey:@"chartCategory"];
	
	NSString *chartCategoryFilter = nil;
	if ([self filterChoiceIndex] != 0) {
		chartCategoryFilter = [self filterChoice];
	}

#if 0
	Region *region = [self regionChoice];
	// TODO: this prevents a crash, but looks ugly as hell
	if (! region) {
		return;
	}
#else
	NSUInteger productCount = [Product countAllInManagedObjectContext:self.managedObjectContext];
	// TODO: this looks ugly as hell
	if (productCount == 0) {
		return;
	}
#endif
	
	Region *region = [self regionChoice];
	
	NSDate *earliestDate = [self earliestDateForChartPeriod:chartPeriod];
	NSUInteger intervalCount = [self intervalCountForChartPeriod:chartPeriod];
	
	NSUInteger plotCount = 0;
	
	CGRect bounds = NSRectToCGRect(self.graphHostingView.bounds);
	
	CPTGraph *graph = [[[CPTXYGraph alloc] initWithFrame:bounds] autorelease];
	self.graphHostingView.hostedGraph = graph;
	
	[graph applyTheme:[CPTTheme themeNamed:kCPTPlainBlackTheme]];

	// line styles
	CPTMutableLineStyle *majorLineStyle = [CPTMutableLineStyle lineStyle];
	majorLineStyle.lineWidth = 1.0f;
	majorLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.75];
	
	CPTMutableLineStyle *minorLineStyle = [CPTMutableLineStyle lineStyle];
	minorLineStyle.lineWidth = 1.0f;
	minorLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.25];
	
	CPTMutableLineStyle *clearLineStyle = [CPTMutableLineStyle lineStyle];
	clearLineStyle.lineWidth = 1.0f;
	clearLineStyle.lineColor = [CPTColor clearColor];
	
	CPTMutableLineStyle *brightLineStyle = [CPTMutableLineStyle lineStyle];
	brightLineStyle.lineWidth = 1.0f;
	brightLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.25];
	
	CPTMutableLineStyle *dimLineStyle = [CPTMutableLineStyle lineStyle];
	dimLineStyle.lineWidth = 1.0f;
	dimLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
	
	// title
	{
		graph.title = [self chartTitleInRegion:region];
		CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
		textStyle.color = [CPTColor lightGrayColor];
		textStyle.fontName = [NSFont systemFontOfSize:20.0f weight:NSFontWeightMedium].fontName;
		textStyle.fontSize = 20.0f;
		graph.titleTextStyle = textStyle;
		graph.titleDisplacement = CGPointMake(0.0f, 20.0f);
		graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
	}
	
	// padding
	{
		//	float boundsPadding = round(bounds.size.width / 20.0f); // Ensure that padding falls on an integral pixel
		float boundsPadding = 20.0f;
		graph.paddingLeft = boundsPadding;
		
		if (graph.titleDisplacement.y > 0.0) {
			graph.paddingTop = graph.titleDisplacement.y * 2;
		}
		else {
			graph.paddingTop = boundsPadding;
		}
		
		graph.paddingRight = boundsPadding;
		graph.paddingBottom = boundsPadding;    
	}
	
	// plot frame
	{
		graph.plotAreaFrame.paddingTop = 20.0;
		graph.plotAreaFrame.paddingRight = 250.0;
		graph.plotAreaFrame.paddingBottom = 50.0;
		graph.plotAreaFrame.paddingLeft = 100.0;
		
		graph.plotAreaFrame.borderLineStyle = clearLineStyle;
	}
	
	// initial plot space
	CPTXYPlotSpace *plotSpace = [[[CPTXYPlotSpace alloc] init] autorelease];
	{
		plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-0.5) length:CPTDecimalFromInteger(intervalCount)];
		plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(0)];
		[graph addPlotSpace:plotSpace];
	}
	
	// axes
	{
		CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
		
		CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
		textStyle.color = [CPTColor grayColor];
		textStyle.fontName = [NSFont systemFontOfSize:12.0f weight:NSFontWeightLight].fontName;
		textStyle.fontSize = 12.0f;
		
		CPTXYAxis *x = axisSet.xAxis;
		{
			x.orthogonalCoordinateDecimal = CPTDecimalFromInteger(0);
			
			if (chartPeriod == 1) {
				// year
				x.majorIntervalLength = CPTDecimalFromInteger(1);
				x.minorTicksPerInterval = 0;
				x.majorGridLineStyle = clearLineStyle;
				x.minorGridLineStyle = clearLineStyle;
			}
			else {
				// month
				x.majorIntervalLength = CPTDecimalFromInteger(12);
				x.minorTicksPerInterval = 3;
				x.majorGridLineStyle = brightLineStyle;
				x.minorGridLineStyle = dimLineStyle;
			}
			
			x.axisLineStyle = nil;
			x.majorTickLineStyle = nil;
			x.minorTickLineStyle = nil;
			
			x.labelOffset = 10.0;
			x.labelRotation = M_PI/2;
			x.labelTextStyle = textStyle;
			
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			dateFormatter.dateFormat = @"yyyy";
			CPTCalendarFormatter *calendarFormatter = [[[CPTCalendarFormatter alloc] initWithDateFormatter:dateFormatter] autorelease];
			calendarFormatter.referenceDate = earliestDate;
			calendarFormatter.referenceCalendarUnit = [self calendarUnitForChartPeriod:chartPeriod];
			x.labelFormatter = calendarFormatter;
			
			x.plotSpace = plotSpace;
		}
		
		CPTXYAxis *y = axisSet.yAxis;
		{
			y.orthogonalCoordinateDecimal = CPTDecimalFromInteger(0);
			
			y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
			
			y.preferredNumberOfMajorTicks = 8;
			y.majorGridLineStyle = majorLineStyle;
			y.minorGridLineStyle = minorLineStyle;
			y.axisLineStyle = nil;
			y.majorTickLineStyle = nil;
			y.minorTickLineStyle = nil;
			
			y.labelOffset = 10.0;
			y.labelRotation = 0;
			y.labelTextStyle = textStyle;
			
			y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
			
			y.labelFormatter = [self numberFormatterInRegion:region];
			
			y.plotSpace = plotSpace;
		}
		
		graph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil];
	}
	
	// bar plot
	if (chartShowTotal) {
		CPTBarPlot *barPlot = [[[CPTBarPlot alloc] init] autorelease];
		barPlot.lineStyle = clearLineStyle;
		barPlot.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0f green:1.0f blue:1.0f alpha:0.25f]];
		barPlot.barBasesVary = NO;
		barPlot.barWidth = CPTDecimalFromFloat(1.0); // percentage of the available space
		barPlot.barCornerRadius = 0.0f;
		barPlot.barsAreHorizontal = NO;
		
		barPlot.title = @"Total";
		
		barPlot.dataSource = nil; // no data source until the operation completes
		barPlot.delegate = self;
		barPlot.identifier = @"__TOTAL__";
		
		[graph addPlot:barPlot toPlotSpace:plotSpace];
		plotCount += 1;
		
		NSOperation *operation = nil;
		switch (chartCategory) {
			default:
			case 0:
				// product
				operation = [self operationForChartCategory:chartCategory usingObject:nil inRegion:region asTotal:YES withPeriod:chartPeriod count:intervalCount from:earliestDate];
				break;
			case 1:
				// group
				if (chartCategoryFilter) {
					Group *group = [Group fetchInManagedObjectContext:self.managedObjectContext withGroupId:chartCategoryFilter];
					operation = [self operationForChartCategory:chartCategory usingObject:group inRegion:region asTotal:YES withPeriod:chartPeriod count:intervalCount from:earliestDate];
				}
				else {
					operation = [self operationForChartCategory:chartCategory usingObject:nil inRegion:region asTotal:YES withPeriod:chartPeriod count:intervalCount from:earliestDate];
				}
				break;
			case 2:
				// partner
				if (chartCategoryFilter) {
					Partner *partner = [Partner fetchInManagedObjectContext:self.managedObjectContext withPartnerId:chartCategoryFilter];
					operation = [self operationForChartCategory:chartCategory usingObject:partner inRegion:region asTotal:YES withPeriod:chartPeriod count:intervalCount from:earliestDate];
				}
				else {
					operation = [self operationForChartCategory:chartCategory usingObject:nil inRegion:region asTotal:YES withPeriod:chartPeriod count:intervalCount from:earliestDate];
				}
				break;
		}
		if (operation) {
			[_operationQueue addOperation:operation];
		}
	}
	
	// line plots
	switch (chartCategory) {
		default:
		case 0:
		{
			// product
			NSArray *products = nil;
			if (chartCategoryFilter) {
				Product *product = [Product fetchInManagedObjectContext:self.managedObjectContext withVendorId:chartCategoryFilter];
				if (product) {
					products = [NSArray arrayWithObject:product];
				}
				else {
					products = [NSArray array];
				}
			}
			else {
				products = [Product fetchAllInManagedObjectContext:self.managedObjectContext];
			}
			for (Product *product in products) {
				CPTScatterPlot *linePlot = [self plotWithIdentifier:product.vendorId usingTitle:product.name andColor:product.color];
				[graph addPlot:linePlot toPlotSpace:plotSpace];
				plotCount += 1;

				NSOperation *operation = [self operationForChartCategory:chartCategory usingObject:product inRegion:region asTotal:NO withPeriod:chartPeriod count:intervalCount from:earliestDate];
				if (operation) {
					[_operationQueue addOperation:operation];
				}
			}
		}
			break;
		case 1:
		{
			// group
			if (chartCategoryFilter) {
				Group *group = [Group fetchInManagedObjectContext:self.managedObjectContext withGroupId:chartCategoryFilter];
				NSArray *products = [Product fetchAllInManagedObjectContext:self.managedObjectContext forGroup:group];
				for (Product *product in products) {
					CPTScatterPlot *linePlot = [self plotWithIdentifier:product.vendorId usingTitle:product.name andColor:product.color];
					[graph addPlot:linePlot toPlotSpace:plotSpace];
					plotCount += 1;
					
					NSOperation *operation = [self operationForChartCategory:chartCategory usingObject:product inRegion:region asTotal:NO withPeriod:chartPeriod count:intervalCount from:earliestDate];
					if (operation) {
						[_operationQueue addOperation:operation];
					}
				}
			}
			else {
				NSArray *groups = [Group fetchAllInManagedObjectContext:self.managedObjectContext];
				for (Group *group in groups) {
					CPTScatterPlot *linePlot = [self plotWithIdentifier:group.groupId usingTitle:group.name andColor:group.color];
					[graph addPlot:linePlot toPlotSpace:plotSpace];
					plotCount += 1;
					
					NSOperation *operation = [self operationForChartCategory:chartCategory usingObject:group inRegion:region asTotal:NO withPeriod:chartPeriod count:intervalCount from:earliestDate];
					if (operation) {
						[_operationQueue addOperation:operation];
					}
				}
			}
		}
			break;
		case 2:
		{
			// partner
			if (chartCategoryFilter) {
				Partner *partner = [Partner fetchInManagedObjectContext:self.managedObjectContext withPartnerId:chartCategoryFilter];
				NSArray *products = [Product fetchAllInManagedObjectContext:self.managedObjectContext forPartner:partner];
				for (Product *product in products) {
					CPTScatterPlot *linePlot = [self plotWithIdentifier:product.vendorId usingTitle:product.name andColor:product.color];
					[graph addPlot:linePlot toPlotSpace:plotSpace];
					plotCount += 1;
					
					NSOperation *operation = [self operationForChartCategory:chartCategory usingObject:product inRegion:region asTotal:NO withPeriod:chartPeriod count:intervalCount from:earliestDate];
					if (operation) {
						[_operationQueue addOperation:operation];
					}
				}
			}
			else {
				NSArray *partners = [Partner fetchAllInManagedObjectContext:self.managedObjectContext];
				for (Partner *partner in partners) {
					CPTScatterPlot *linePlot = [self plotWithIdentifier:partner.partnerId usingTitle:partner.name andColor:partner.color];
					[graph addPlot:linePlot toPlotSpace:plotSpace];
					plotCount += 1;
					
					NSOperation *operation = [self operationForChartCategory:chartCategory usingObject:partner inRegion:region asTotal:NO withPeriod:chartPeriod count:intervalCount from:earliestDate];
					if (operation) {
						[_operationQueue addOperation:operation];
					}
				}
			}
		}
			break;
	}
	
	
	// legend
	{
		CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
		textStyle.color = [CPTColor grayColor];
		textStyle.fontName = [NSFont systemFontOfSize:10.0f weight:NSFontWeightLight].fontName;
		textStyle.fontSize = 10.0f;
		
		CPTLegend *legend = [CPTLegend legendWithGraph:graph];
		legend.numberOfRows = plotCount;
		legend.fill = [CPTFill fillWithColor:[CPTColor colorWithGenericGray:0.10]];
		legend.borderLineStyle = minorLineStyle;
		legend.cornerRadius = 0.0;
		legend.swatchSize = CGSizeMake(10.0, 10.0);
		legend.textStyle = textStyle;
		legend.rowMargin = 10.0;
		legend.paddingLeft = 10.0;
		legend.paddingTop = 10.0;
		legend.paddingRight = 10.0;
		legend.paddingBottom = 10.0;
		legend.columnWidths = [NSArray arrayWithObject:[NSNumber numberWithInteger:150]];
		
		graph.legend = legend;
		graph.legendAnchor = CPTRectAnchorRight;
		graph.legendDisplacement = CGPointMake(-30.0, 0.0);
	}
	
	[_chartVariablesCache release];
	_chartVariablesCache = [[NSMutableDictionary dictionary] retain];
	[_chartMaximumCache release];
	_chartMaximumCache = [[NSNumber numberWithInteger:0] retain];
}

- (void)generateOutput
{
	[self generateChart];
}

- (NSPrintOperation *)printOperationWithPrintInfo:(NSPrintInfo *)printInfo
{
	NSRect printableRect = NSZeroRect;
	printableRect.size.width = (printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin) * printInfo.scalingFactor;
	printableRect.size.height = (printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin) * printInfo.scalingFactor;
	
	graphHostingView.printRect = printableRect;
	return [NSPrintOperation printOperationWithView:graphHostingView printInfo:printInfo];
}

- (void)showChart
{
	CPTGraph *graph = [graphHostingView hostedGraph];

// TODO: this should be optimized to only reload the data that changed
	[graph reloadData];

	//	CPTPlot *plot = [graph plotWithIdentifier:@"Product"];
//	[plot setDataNeedsReloading];
	
//	for (CPTPlot *plot in [graph allPlots]) {
//	}
	
	[graphHostingView setNeedsDisplay:YES];
}

- (void)generateChart
{
	// TODO: kick off operations
//	[self performSelector:@selector(showChart) withObject:nil afterDelay:0.0];
}


#pragma mark -

- (void)updateFilterPopUpButton
{
	NSInteger selectedItem = [self filterChoiceIndex];
	[filterPopUpButton selectItemAtIndex:selectedItem];
}

#pragma mark - Actions

- (IBAction)generateChart:(id)sender
{
//	[self generateChart];
	[self initializeChart];
}

- (IBAction)chooseFilter:(id)sender
{
	DebugLog(@"%s filter = %@", __PRETTY_FUNCTION__, [(NSPopUpButton *)sender titleOfSelectedItem]);
	
	NSInteger selectedItem = [filterPopUpButton indexOfSelectedItem];
	
	NSInteger reportCategory = [self.settings integerForKey:@"chartCategory"];
	switch (reportCategory) {
		default:
		case 0:
			[self.settings setInteger:selectedItem forKey:@"chartFilterProducts"];
			break;
		case 1:
			[self.settings setInteger:selectedItem forKey:@"chartFilterGroup"];
			break;
		case 2:
			[self.settings setInteger:selectedItem forKey:@"chartFilterPartner"];
			break;
	}
	
//	[self generateChart];
	[self initializeChart];
}

#pragma mark - CPTScatterPlotDelegate

-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
{
	NSNumber *value = [self numberForPlot:plot field:CPTScatterPlotFieldY recordIndex:index];
	
	DebugLog(@"%s %@ plot was selected at index %d, value = %f", __PRETTY_FUNCTION__, plot.identifier, (int)index, [value floatValue]);
}

#pragma mark - CPTBarPlotDelegate

-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index
{
	NSNumber *value = [self numberForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
	
	DebugLog(@"%s total bar was selected at index %d, value = %f", __PRETTY_FUNCTION__, (int)index, [value floatValue]);
}

#pragma mark - CPTPlotDataSource

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSNumber *result = nil;
	
	if (fieldEnum == CPTBarPlotFieldBarLocation || fieldEnum == CPTScatterPlotFieldX) {
		// location
		result = [NSDecimalNumber numberWithInt:index];
	}
	else if (fieldEnum == CPTBarPlotFieldBarTip || fieldEnum == CPTScatterPlotFieldY) {
		// length
		NSArray *chartVariables = [_chartVariablesCache objectForKey:(NSString *)plot.identifier];
		if (chartVariables) {
			NSNumber *value = [chartVariables objectAtIndex:index];
			if ([value integerValue] != NSIntegerMin) {
				result = value;
			}
		}
	}
	else {
		// base
		if ([plot.identifier isEqual:@"__TOTAL__"]) {
			result = [NSDecimalNumber numberWithInt:0];
		}
		else {
			result = [NSDecimalNumber numberWithInt:index];
		}
	}
	
	return result;
}

#pragma mark - CPTBarPlotDataSource

/*
 -(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index
 {
 return nil;
 }
 
 -(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index 
 {
 return nil;
 }
 */

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	NSUInteger chartPeriod = [self.settings integerForKey:@"chartPeriod"];
	
	NSUInteger intervalCount = [self intervalCountForChartPeriod:chartPeriod];
	
	return intervalCount;
}

#pragma mark - Operation callback

- (void)updatePlotWithOperationObject:(NSManagedObject *)object variables:(NSArray *)variables maximum:(NSNumber *)maximum category:(NSUInteger)category total:(BOOL)total
{
	NSString *chartCategoryFilter = nil;
	if ([self filterChoiceIndex] != 0) {
		chartCategoryFilter = [self filterChoice];
	}
	
	NSString *plotIdentifier = nil;
	if (total) {
		plotIdentifier = @"__TOTAL__";
	}
	else {
		switch (category) {
			default:
			case 0: // product
				plotIdentifier = ((Product *)object).vendorId;
				break;
			case 1: // group
				if (chartCategoryFilter) {
					if ([object isKindOfClass:[Product class]]) {
						plotIdentifier = ((Product *)object).vendorId;
					}
				}
				else {
					if ([object isKindOfClass:[Group class]]) {
						plotIdentifier = ((Group *)object).groupId;
					}
				}
				break;
			case 2: // partner
				if (chartCategoryFilter) {
					if ([object isKindOfClass:[Product class]]) {
						plotIdentifier = ((Product *)object).vendorId;
					}
				}
				else {
					if ([object isKindOfClass:[Partner class]]) {
						plotIdentifier = ((Partner *)object).partnerId;
					}
				}
				break;
		}
	}
	if (plotIdentifier) {
		[_chartVariablesCache setObject:variables forKey:plotIdentifier];
		DebugLog(@"%s set variables for %@", __PRETTY_FUNCTION__, plotIdentifier);
		
		CPTGraph *graph = self.graphHostingView.hostedGraph;
		
		if ([maximum compare:_chartMaximumCache] == NSOrderedDescending) {
			// round maximum value
			double originalMaximum = [maximum doubleValue];
#if 0
			double exponent = floor(log10(originalMaximum));
			double fraction = originalMaximum / pow(10.0, exponent);
			
#if 0
			double roundedFraction;
			if ( fraction <= 1.0 ) {
				roundedFraction = 1.0;
			}
			else if ( fraction <= 2.0 ) {
				roundedFraction = 2.0;
			}
			else if ( fraction <= 5.0 ) {
				roundedFraction = 5.0;
			}
			else {
				roundedFraction = 10.0;
			}
#else
			double roundedFraction;
			if ( fraction > 5.0 ) {
				roundedFraction = 10.0;
			}
			else if ( fraction > 2.0 ) {
				roundedFraction = 5.0;
			}
			else if ( fraction > 1.0 ) {
				roundedFraction = 2.0;
			}
			else {
				roundedFraction = 1.0;
			}
#endif
			double roundedMaximum = roundedFraction * pow(10.0, exponent);
#else		
			//		double rounding = pow(10.0, floor(log10(originalMaximum)) - 1.0); // 110 -> 120, 1,100 -> 1,200, 11,000 -> 12,000, ...
			double rounding = pow(10.0, floor(log10(originalMaximum))); // 110 -> 200, 1,100 -> 2,000, 11,000 -> 20,000, ...
			double roundedMaximum = ceil(originalMaximum / rounding) * rounding;
#endif
			
			[_chartMaximumCache release];
			_chartMaximumCache = [[NSNumber numberWithDouble:roundedMaximum] retain];
			
			DebugLog(@"%s set chart maximum to %@", __PRETTY_FUNCTION__, _chartMaximumCache);
			
			NSUInteger intervalCount = [variables count];
			
			// adjust plot space
			CPTXYPlotSpace *plotSpace = [[[CPTXYPlotSpace alloc] init] autorelease];
			{
				plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-0.5) length:CPTDecimalFromInteger(intervalCount)];
				plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:[_chartMaximumCache decimalValue]];
				[graph addPlotSpace:plotSpace];
			}
			
			for (CPTPlot *plot in graph.allPlots) {
				plot.plotSpace = plotSpace;
				[plot setNeedsDisplay];
			}
			
			CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
			axisSet.xAxis.plotSpace = plotSpace;
			axisSet.yAxis.plotSpace = plotSpace;
		}
		
		// load the plot with new data
		CPTPlot *plot = [graph plotWithIdentifier:plotIdentifier];
		plot.dataSource = self;
		[plot reloadData];
	}
}

@end
