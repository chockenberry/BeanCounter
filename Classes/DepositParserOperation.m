//
//  DepositParserOperation.m
//  BeanCounter
//
//  Created by Craig Hockenberry on 1/20/11.
//  Copyright 2011 The Iconfactory. All rights reserved.
//

#import "DepositParserOperation.h"

#import "DepositData.h"
#import "DebugLog.h"
#import "NSError+Reporting.h"

@implementation DepositParserOperation

@synthesize reportError;
@synthesize reportPath;
@synthesize reportDataValues;

- (id)initWithDepositPath:(NSString *)initialDepositPath delegate:(NSObject <DepositParserDelegate> *)theDelegate;
{
	if ((self = [super init])) {
		reportPath = [initialDepositPath copy];
		_delegate = theDelegate;
	}
	
	return self;
}

- (void)dealloc
{
	[reportError release];
	[reportPath release];
	[reportDataValues release];

	_delegate = nil;
	
	[super dealloc];
}

- (void)main
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	self.reportDataValues = nil;

	NSError *error = nil;
	NSString *fileData = [NSString stringWithContentsOfFile:reportPath encoding:NSUTF8StringEncoding error:&error];
	if (! fileData) {
		self.reportError = error;
		ReleaseLog(@"%s failed to open report, error = %@", __PRETTY_FUNCTION__, error);

		SEL selector = @selector(depositParserOperationDidFail:);
		[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
		
		[pool drain];
		return;
	}

	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	numberFormatter.lenient = YES;
	numberFormatter.format = @"###0.00;-###0.00";
	numberFormatter.generatesDecimalNumbers = YES;
	
	NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:2 raiseOnExactness:FALSE raiseOnOverflow:TRUE raiseOnUnderflow:TRUE raiseOnDivideByZero:TRUE];
	
	NSMutableArray *parsedDataValues = [NSMutableArray array];
	
	BOOL firstLine = YES;
	NSArray *lines = [fileData componentsSeparatedByString:@"\n"];
	if ([lines count] == 1) {
		// lines aren't terminated with a newline, try a return
		lines = [fileData componentsSeparatedByString:@"\r"];
	}
	for (NSString *line in lines) {
		NSArray *columns = [line componentsSeparatedByString:@"\t"];
		if (firstLine) {
			//DebugLog(@"%s headers = %@", __PRETTY_FUNCTION__, columns);
			if (! ([columns count] == 6)) {
				NSString *errorDescription = [NSString stringWithFormat:@"The file has %ld headers, but there should be 6", (long)[columns count]];
				self.reportError = [NSError errorWithCode:DepositParserOperationError filePath:reportPath description:errorDescription];
					
				SEL selector = @selector(depositParserOperationDidFail:);
				[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
				
				[pool drain];
				return;
			}
			else {
				if (! ([[columns objectAtIndex:0] isEqualToString:@"Year"] &&
						[[columns objectAtIndex:1] isEqualToString:@"Month"] &&
						[[columns objectAtIndex:2] isEqualToString:@"Region"] &&
						[[columns objectAtIndex:3] isEqualToString:@"Balance"] &&
					    [[columns objectAtIndex:4] isEqualToString:@"Deposit"] &&
						[[columns objectAtIndex:5] isEqualToString:@"Adjustments"])) {
					NSString *errorDescription = [NSString stringWithFormat:@"The file has invalid column headers"];
					self.reportError = [NSError errorWithCode:DepositParserOperationError filePath:reportPath description:errorDescription];
					
					SEL selector = @selector(depositParserOperationDidFail:);
					[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
					
					[pool drain];
					return;
				}
			}

			firstLine = NO;
		}
		else {
			if ([columns count] == 6) {
				NSString *yearString = [columns objectAtIndex:0];
				NSString *monthString = [columns objectAtIndex:1];
				NSString *regionIdString = [columns objectAtIndex:2];
				NSString *balanceString = [columns objectAtIndex:3];
				NSString *depositString = [columns objectAtIndex:4];
				NSString *adjustmentsString = [columns objectAtIndex:5];
				
				DepositData *depositData = [[[DepositData alloc] init] autorelease];
				depositData.regionId = regionIdString;
				
				NSDateComponents *dateComponents = [[[NSDateComponents alloc] init] autorelease];
				dateComponents.year = [yearString integerValue];
				dateComponents.month = [monthString integerValue];
				depositData.date = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
				
				NSDecimalNumber *balanceUnformatted = (NSDecimalNumber *)[numberFormatter numberFromString:balanceString];
				depositData.balance = [balanceUnformatted decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
				
				NSDecimalNumber *depositUnformatted = (NSDecimalNumber *)[numberFormatter numberFromString:depositString];
				depositData.deposit = [depositUnformatted decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
				
				NSDecimalNumber *adjustmentsUnformatted = (NSDecimalNumber *)[numberFormatter numberFromString:adjustmentsString];
				depositData.adjustments = [adjustmentsUnformatted decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
				
				//DebugLog(@"%s date = %@, region = %@, balance = %@, deposit = %@, adjustments = %@", __PRETTY_FUNCTION__, date, regionIdString, balance, deposit, adjustments);
				
				[parsedDataValues addObject:depositData];
			}
			else {
				// ignore newlines (single empty column) in data, otherwise report bad number of columns
				if (! ([columns count] == 1 && [[columns objectAtIndex:0] length] == 0)) {
					NSString *errorDescription = [NSString stringWithFormat:@"The file has %ld columns, but there should be 6", (long)[columns count]];
					self.reportError = [NSError errorWithCode:DepositParserOperationError filePath:reportPath description:errorDescription];
					
					SEL selector = @selector(depositParserOperationDidFail:);
					[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
					
					[pool drain];
					return;					
				}
			}
		}
	}
	
	NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"regionId" ascending:YES], nil];
	self.reportDataValues = [parsedDataValues sortedArrayUsingDescriptors:sortDescriptors];
	
	SEL selector = @selector(depositParserOperationDidSucceed:);
	[_delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
//	DebugLog(@"%s reportDataValues = %@", __PRETTY_FUNCTION__, reportDataValues);
	
	[pool drain];
}

@end
