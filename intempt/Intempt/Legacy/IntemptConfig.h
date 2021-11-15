//
//  IntemptConfig.h
//  Intempt
//
//  Created by Appsbee LLC on 20/02/21.
//  Copyright © 2021 Intempt. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IntemptConfig : NSObject

/**  If queue should be used to send events to server. This queue sends batched events at a time. Default is YES.
 */
@property (nonatomic,assign, readonly) BOOL queueEnabled;

/**  No of items in the queue. FYI, This feature will only work if `queueEnabled` is set to `YES`. Default is 5. Set `0` if queue is disabled.
 */
@property (nonatomic,assign) int itemsInQueue;

/**  Send events periodically. Measured in seconds. Default is 5.
 */
@property (nonatomic,assign) NSTimeInterval timeBuffer;

/**  How many times retry to send an event to server if fails initially.
 */
@property (nonatomic,assign, readonly) int retryLimit;

/**  Initial delay between consecutive calls. Measured in seconds. Default is 0.2.
 */
@property (nonatomic,assign, readonly) NSTimeInterval initialDelay;

/** Each next retry will be delayed by (2^retries_count * 100) milliseconds.
 */
//@property (nonatomic,assign, readonly) NSTimeInterval retryDelay;

/**If you want to disable capturing input texts like UItextField, UItextView. Secure entries are excluded for privacy. Set `NO` to disable. Default is `YES`.
 */
@property (nonatomic,assign, readonly) BOOL isInputTextCaptureDisabled;

- (instancetype)initWithQueueEnabled:(BOOL) enabled withItemsInQueue:(int) items withTimeBuffer:(NSTimeInterval) bufferTime withInitialDelay:(NSTimeInterval) initialDelay withInputTextCaptureDisabled:(BOOL) status;

@end

NS_ASSUME_NONNULL_END
