//
//  IntemptConstants.h
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

@import Foundation;

#define kIntemptSdkVersion @"0.1.0"

#ifndef PRODUCTION
    #define PRODUCTION 1   //set value 1 for live & 0 for staging, change this line only
#endif

extern NSString * const kIntemptServerAddress;
extern NSString * const kIntemptApiVersion;
extern NSString * const kPlatform;
extern NSString * const kIntemptErrorDomain;

extern BOOL const kEnableQueue;
extern int const kItemsInQueue;
extern double const kTimeBuffer;
extern BOOL const kcaptureTextInput;
extern int const kRetryLimit;
extern double const kInitialDelay;
extern double const kRetryDelay;
extern BOOL const kDisableTextInput;

typedef enum geoLocationStateType {
    GEO_DISABLED = 0,
    GEO_ENABLED_IN_USE = 1,
    GEO_ENABLED_ALWAYS = 2
} ITGeoLocationState;

//IntemptConstants
