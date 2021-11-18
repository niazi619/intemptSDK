//
//  IntemptConstants.m
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#import "IntemptConstants.h"
#import <UIKit/UIScreen.h>

//DO NOT CHANGE HERE. Go to IntemptConstants.h and set PRODUCTION value 0 for satging and 1 for live
#if PRODUCTION == 1
    NSString * const kIntemptServerAddress = @"https://api.intempt.com/v1/";
#else
    NSString * const kIntemptServerAddress = @"https://api.staging.intempt.com/v1/";
#endif

NSString * const kIntemptApiVersion = @"1.0";
NSString * const kPlatform = @"iOS";

BOOL const kTrackingEnable = YES;
BOOL const kEnableQueue = YES;
int const kItemsInQueue = 5;
double const kTimeBuffer = 5;

int const kRetryLimit = 10;
double const kInitialDelay = 0.2;
double const kRetryDelay = 0.1;
BOOL const kcaptureTextInput = YES;
BOOL const kDisableTextInput = NO;
