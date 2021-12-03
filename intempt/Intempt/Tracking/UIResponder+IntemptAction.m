//
//  UIResponder+IntempAction.m
//  Intempt
//
//  Created by MacBook on 19/11/2021.
//  Copyright © 2021 Intempt. All rights reserved.
//

#import "UIResponder+IntemptAction.h"
#import "IntemptClient.h"

@implementation UIResponder (IntemptAction)

- (void)intempt_sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0)){
    TBLog(@"intempt_sceneWillEnterForeground");
    
    ////we can do any task here, e.g sending updated location etc
    /*
    if([IntemptClient isTrackingEnabled] == YES){
        [[IntemptClient sharedClient]refreshCurrentLocation];
    }*/
    
    if ([self respondsToSelector:@selector(intempt_sceneWillEnterForeground:)]){
        return [self intempt_sceneWillEnterForeground:scene];
    }
}
/**this method is just in case developer has not overrided in UISceneDelegate
 */
- (void)sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0)){
    TBLog(@"sceneWillEnterForeground inside intempt");
}

- (void)intempt_applicationWillEnterForeground:(UIApplication *)application{
    TBLog(@"intempt_applicationWillEnterForeground");
    
    ////we can do any task here, e.g sending updated location etc
    /*
    if([IntemptClient isTrackingEnabled] == YES){
        [[IntemptClient sharedClient]refreshCurrentLocation];
    }*/
    
    if ([self respondsToSelector:@selector(intempt_applicationWillEnterForeground:)]){
        return [self intempt_applicationWillEnterForeground:application];
    }
}

/**this method is just in case developer has not overrided in AppDelegate
 */
- (void)applicationWillEnterForeground:(UIApplication *)application{
    TBLog(@"applicationWillEnterForeground inside intempt");
}

@end
