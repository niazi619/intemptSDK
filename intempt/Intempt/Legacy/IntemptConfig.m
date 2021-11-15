//
//  IntemptConfig.m
//  Intempt
//
//  Created by Appsbee LLC on 20/02/21.
//  Copyright © 2021 Intempt. All rights reserved.
//

#import "IntemptConfig.h"
#import "IntemptConstants.h"

@implementation IntemptConfig

- (instancetype)init {
    self = [self initWithQueueEnabled:kEnableQueue withItemsInQueue:kItemsInQueue withTimeBuffer:kTimeBuffer withInitialDelay:kInitialDelay withInputTextCaptureDisabled:kDisableTextInput];
    return self;
}

- (instancetype)initWithQueueEnabled:(BOOL) enabled withItemsInQueue:(int) items withTimeBuffer:(NSTimeInterval) bufferTime withInitialDelay:(NSTimeInterval) initialDelay withInputTextCaptureDisabled:(BOOL) status {
    self = [super init];
    if (self) {
        _queueEnabled = enabled;
        _itemsInQueue = items;
        _timeBuffer = bufferTime;
        _retryLimit = kRetryLimit;
        _initialDelay = initialDelay;
        _isInputTextCaptureDisabled = status;
    }
    return self;
}

@end
