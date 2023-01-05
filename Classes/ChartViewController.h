//
//  ChartViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/30/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OutputViewController.h"

#import "Region.h"

#import "CorePlot/CorePlot.h"
#import "GraphHostingView.h"

@interface ChartViewController : OutputViewController <CPTPlotDataSource>
{
	NSOperationQueue *_operationQueue;
	NSMutableDictionary *_chartVariablesCache;
	NSNumber *_chartMaximumCache;

    GraphHostingView *graphHostingView;
	NSPopUpButton *filterPopUpButton;
}

@property (nonatomic, retain) IBOutlet GraphHostingView *graphHostingView;
@property (nonatomic, retain) IBOutlet NSPopUpButton *filterPopUpButton;

@property (nonatomic, readonly) NSArray *filterChoices;
@property (nonatomic, readonly) NSInteger filterChoiceIndex;
@property (nonatomic, readonly) NSString *filterChoice;

@property (nonatomic, readonly) NSArray *regionChoices;
@property (nonatomic, readonly) NSInteger regionChoiceIndex;
@property (nonatomic, readonly) Region *regionChoice;

// utility (for subclasses)
- (NSDate *)earliestDateForChartPeriod:(NSUInteger)chartPeriod onlyLatest:(BOOL)onlyLatest;
- (NSDate *)latestDateForChartPeriod:(NSUInteger)chartPeriod;
- (NSCalendarUnit)calendarUnitForChartPeriod:(NSUInteger)chartPeriod;
- (NSUInteger)intervalCountForChartPeriod:(NSUInteger)chartPeriod onlyLatest:(BOOL)onlyLatest;
- (CPTScatterPlot *)plotWithIdentifier:(NSString *)identifier usingTitle:(NSString *)title andColor:(NSColor *)color;

// overrides
- (BOOL)usesRegion;
- (NSOperation *)operationForChartCategory:(NSUInteger)category usingObject:(NSManagedObject *)object inRegion:(Region *)region asTotal:(BOOL)total withPeriod:(NSUInteger)period count:(NSUInteger)count from:(NSDate *)fromDate;
- (NSNumberFormatter *)numberFormatterInRegion:(Region *)region;
- (NSString *)chartTitleInRegion:(Region *)region;

- (void)initializeChart;
- (void)generateChart;

- (IBAction)generateChart:(id)sender;
- (IBAction)chooseFilter:(id)sender;

// operation callback
- (void)updatePlotWithOperationObject:(NSManagedObject *)object variables:(NSArray *)variables maximum:(NSNumber *)maximum category:(NSUInteger)category total:(BOOL)total;

@end
