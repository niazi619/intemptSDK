//
//  UIScene+IntempAction.m
//  Intempt
//
//  Created by MacBook on 19/11/2021.
//  Copyright © 2021 Intempt. All rights reserved.
//

#import "UIScene+IntemptAction.h"
#import "IntemptClient.h"

@implementation UIScene (IntemptAction)

- (void)intempt_sceneWillEnterForeground:(UIScene *)scene{
    
    if([IntemptClient isTrackingEnabled] == YES){
        [[IntemptClient sharedClient]refreshCurrentLocation];
    }
    return [self intempt_sceneWillEnterForeground:scene];
}

@end
