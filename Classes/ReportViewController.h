//
//  ReportViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 11/12/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OutputViewController.h"

#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"
#import "Group.h"
#import "Partner.h"

#import <WebKit/WebKit.h>

#import "MGTemplateEngine.h"

@interface ReportViewController : OutputViewController <MGTemplateEngineDelegate>
{
	NSOperation *_operation;

	MGTemplateEngine *_templateEngine;
	
//	NSNumberFormatter *_unitsFormatter;
//	NSNumberFormatter *_salesFormatter;
//	NSNumberFormatter *_percentFormatter;
//	NSDateFormatter *_dateFormatter;

	NSProgressIndicator *progressIndicator;
	WebView *webView;
	NSPopUpButton *filterPopUpButton;
}

@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) IBOutlet WebView *webView;
@property (nonatomic, retain) IBOutlet NSPopUpButton *filterPopUpButton;

@property (nonatomic, readonly) NSArray *filterChoices;
@property (nonatomic, readonly) NSInteger filterChoiceIndex;
@property (nonatomic, readonly) NSString *filterChoice;

@property (nonatomic, readonly) NSArray *yearChoices;

// overrides
- (NSString *)reportTemplatePath;
- (NSOperation *)reportOperation;

- (void)generateReport;
- (void)showReport;

- (IBAction)generateReport:(id)sender;
- (IBAction)chooseFilter:(id)sender;

@end

@interface ReportViewController (Private_Utility)

- (void)getReportRangeUsingStartDate:(NSDate **)startDate endDate:(NSDate **)endDate;

- (NSDictionary *)createSalesDictionaryInCountry:(NSString *)country withAmount:(NSDecimalNumber *)amount units:(NSNumber *)units totalUnits:(NSNumber *)totalUnits;

@end
