//
//  ModelEvent.h
//  Intempt
//
//  Created by Appsbee LLC on 22/02/21.
//  Copyright © 2021 Intempt. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ModelEvent : NSObject
@property (nonatomic,strong) NSString *eventId;
@property (nonatomic,strong) NSDictionary *eventContent;
@property (nonatomic,strong) NSString *eventType;
@property (nonatomic,assign) BOOL isSync;
-(id)initWithEventId:(NSString*)eventId withContent:(NSDictionary*)dictContent withType:(NSString*)eventType;
@end

NS_ASSUME_NONNULL_END
