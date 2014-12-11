//
//  OutputViewController.h
//  BeanCounter
//
//  Created by Craig Hockenberry on 11/27/11.
//  Copyright (c) 2011 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Product.h"
#import "Region.h"
#import "Sale.h"
#import "Earning.h"
#import "Group.h"
#import "Partner.h"

@interface OutputViewController : NSViewController
{
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	
	NSMutableDictionary *settings;
}

@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSMutableDictionary *settings;

- (void)saveSettings;
- (void)generateOutput;
- (NSPrintOperation *)printOperationWithPrintInfo:(NSPrintInfo *)printInfo;

//- (NSArray *)salesInRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
//- (NSArray *)salesForProduct:(Product *)product inRegion:(Region *)region startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
//- (Earning *)earningInRegion:(Region *)region toDate:(NSDate *)toDate;
//- (Earning *)earningInRegion:(Region *)region onDate:(NSDate *)date;
//- (NSArray *)earningsInRegion:(Region *)region fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
//- (Region *)regionWithId:(NSString *)regionId;

//- (NSArray *)allGroups;
//- (NSArray *)allProductsByGroup:(Group *)group;
//- (NSArray *)allProductsWithoutGroup;
//- (NSArray *)allProductsByGroup;

//- (NSArray *)allPartners;
//- (NSArray *)allProductsByPartner:(Partner *)partner;
//- (NSArray *)allProductsWithoutPartner;
//- (NSArray *)allProductsByPartner;

//- (NSArray *)allProducts;
//- (NSArray *)allRegions;

@end
