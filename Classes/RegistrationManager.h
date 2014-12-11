//
//  RegistrationManager.h
//  Ostrich
//
//  Created by Craig Hockenberry on 12/31/10.
//  Copyright 2010 The Iconfactory. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//#import "Serial.h"
//#import "ATimeLimit.h"

typedef enum {
	RegistrationEmpty = 0,
	RegistrationInvalid,
	RegistrationValid,
} RegistrationState;

@interface RegistrationManager : NSObject
{
#if !MAC_APP_STORE
//	Serial *serial;
//	ATimeLimit *timeLimit;
#endif

	RegistrationState registrationState;
}

+ (RegistrationManager *)sharedRegistrationManager;

- (void)updateRegistration;
- (RegistrationState)registrationState;
- (BOOL)isRegistered;
- (NSUInteger)licenseCount;

- (NSInteger)trialDaysRemaining;
- (BOOL)trialHasExpired;

@end
