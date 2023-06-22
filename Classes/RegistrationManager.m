//
//  RegistrationManager.m
//  Ostrich
//
//  Created by Craig Hockenberry on 12/31/10.
//  Copyright 2010 The Iconfactory. All rights reserved.
//

#import "RegistrationManager.h"

#if MAC_APP_STORE
//#import "ValidateReceipt.h"
#endif

@interface RegistrationManager () 

- (RegistrationState)checkRegistration;

@end


@implementation RegistrationManager

#pragma mark Singleton

static RegistrationManager *sharedRegistrationManager = nil;
 
+ (RegistrationManager *)sharedRegistrationManager
{
	if (sharedRegistrationManager == nil) {
		sharedRegistrationManager = [[super allocWithZone:NULL] init];
	}
	return sharedRegistrationManager;
}
 
+ (id)allocWithZone:(NSZone *)zone
{
	return [[self sharedRegistrationManager] retain];
}
 
- (id)copyWithZone:(NSZone *)zone
{
	return self;
}
 
- (id)retain
{
	return self;
}
 
- (NSUInteger)retainCount
{
	return NSUIntegerMax;  // denotes an object that cannot be released
}
 
- (oneway void)release
{
	// do nothing
}
 
- (id)autorelease
{
	return self;
}

#pragma mark Instance

- (id)init
{
    self = [super init];
    if (self) {
#if !MAC_APP_STORE
//		serial = [[Serial alloc] initWithProduct:"FL"];
//		timeLimit = [[ATimeLimit alloc] initWithDayLimit:15];
#endif

		registrationState = [self checkRegistration];
    }
    return self;
}

#if MAC_APP_STORE

- (RegistrationState)checkRegistration
{
	return RegistrationValid;

//	RegistrationState result = RegistrationInvalid;
//	if (validReceipt()) {
//		result = RegistrationValid;
//	}
//
//	return result;
}

#else

// TODO: implement registration for BeanCounter

- (RegistrationState)checkRegistration
{
	/*
	NSString *name = [serial userDefaultsName];
	NSString *number = [serial userDefaultsCode];
	
	RegistrationState result = RegistrationEmpty;
	if ([name length] > 0 && [number length] > 11) {
		if ([serial checkKeyFromUserDefaults]) {
			result = RegistrationValid;
		}
		else {
			result = RegistrationInvalid;
		}
	}
	
	return result;
	 */
	return RegistrationValid;
}

#endif

- (void)updateRegistration
{
	RegistrationState newRegistrationState = [self checkRegistration];
	if (newRegistrationState != registrationState) {
		registrationState = newRegistrationState;
	}
}

- (RegistrationState)registrationState
{
	return registrationState;
}

- (BOOL)isRegistered
{
	return (registrationState == RegistrationValid);
}

- (NSUInteger)licenseCount
{
#if MAC_APP_STORE
	return 1;
#else
//	return [serial licensesFromUserDefaults];
	return 1;
#endif
}

- (NSInteger)trialDaysRemaining
{
#if MAC_APP_STORE
	return 0;
#else
//	return [timeLimit limitLeft];
	return 0;
#endif
}

- (BOOL)trialHasExpired;
{
	return ([self trialDaysRemaining] <= 0);
}


@end
