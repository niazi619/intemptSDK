//
//  ModelEvent.m
//  Intempt
//
//  Created by Appsbee LLC on 22/02/21.
//  Copyright © 2021 Intempt. All rights reserved.
//

#import "ModelEvent.h"

@implementation ModelEvent

-(id)init {
    if (self=[super init]) {
        self.eventId=@"";
        self.eventContent= [NSDictionary new];
        self.eventType=@"";
        self.isSync=NO;
    }
    return self;
}

-(id)initWithEventId:(NSString*)eventId withContent:(NSDictionary*)dictContent withType:(NSString*)eventType {
    self = [super init];
    if (self) {
        self.eventId = eventId;
        self.eventContent = dictContent;
        self.eventType = eventType;
    }
    return self;
}

@end
