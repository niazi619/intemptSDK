//
//  UIResponder+IntempAction.m
//  Intempt
//
//  Created by MacBook on 19/11/2021.
//  Copyright © 2021 Intempt. All rights reserved.
//

#import "UIResponder+IntemptAction.h"
#import "IntemptClient.h"
#import "IntemptConstants.h"

@implementation UIResponder (IntemptAction)

UIBackgroundTaskIdentifier taskID;

- (void)intempt_sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0)){
    //TBLog(@"intempt_sceneWillEnterForeground");
    
    // Tell the system that the task has ended.
    if (taskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:taskID];
        taskID =  UIBackgroundTaskInvalid;
    }
    [self checkIfNeedToStartSession];

    if ([self respondsToSelector:@selector(intempt_sceneWillEnterForeground:)]){
        return [self intempt_sceneWillEnterForeground:scene];
    }
}


- (void)intempt_sceneDidEnterBackground:(UIScene *)scene API_AVAILABLE(ios(13.0)){
    //TBLog(@"intempt_sceneDidEnterBackground");
    
    double timestampaAppWentBackground = [[NSDate date] timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setValue: [NSNumber numberWithDouble:timestampaAppWentBackground] forKey:@"timestampaAppWentBackground"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Dispatch to a background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        // Tell the system that you want to start a background task
        taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            /// sometimes even before ending task, expiryhandler called,
            /// so we need to end task here as well to avoid warning
            //TBLog(@"task completion handler");
            if (taskID) {
                //TBLog(@"ending background inside handler");
                [[UIApplication sharedApplication] endBackgroundTask:taskID];
                taskID =  UIBackgroundTaskInvalid;
            }
            /*
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
                    [[IntemptClient sharedClient]endTrackingSession];
                }
            });*/
        }];
        // Sleep the block for xx seconds
        [NSThread sleepForTimeInterval:TRACKING_SESSION_TIME_OUT];

        //TBLog(@"going to end session");
        // Call the method if the app is backgrounded (and not just inactive)
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
                [self checkIfNeedToEndSession];
            }
        });
        // Tell the system that the task has ended.
        if (taskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:taskID];
            taskID =  UIBackgroundTaskInvalid;
        }

    });
    
    if ([self respondsToSelector:@selector(intempt_sceneDidEnterBackground:)]){
        return [self intempt_sceneDidEnterBackground:scene];
    }
}

- (void)intempt_applicationDidEnterBackground:(UIApplication *)application{
    //TBLog(@"intempt_applicationDidEnterBackground");
    
    double timestampaAppWentBackground = [[NSDate date] timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setValue: [NSNumber numberWithDouble:timestampaAppWentBackground] forKey:@"timestampaAppWentBackground"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Dispatch to a background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        // Tell the system that you want to start a background task
        taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            /// sometimes even before ending task, expiryhandler called,
            /// so we need to end task here as well to avoid warning
            //TBLog(@"task completion handler");
            if (taskID) {
                //TBLog(@"ending background inside handler");
                [[UIApplication sharedApplication] endBackgroundTask:taskID];
                taskID =  UIBackgroundTaskInvalid;
            }
            /*
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
                    [[IntemptClient sharedClient]endTrackingSession];
                }
            });*/
        }];
        // Sleep the block for xx seconds
        [NSThread sleepForTimeInterval:TRACKING_SESSION_TIME_OUT];

        // Call the method if the app is backgrounded (and not just inactive)
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
                [self checkIfNeedToEndSession];
            }
        });
        // Tell the system that the task has ended.
        if (taskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:taskID];
            taskID =  UIBackgroundTaskInvalid;
        }

    });
    
    if ([self respondsToSelector:@selector(intempt_applicationDidEnterBackground:)]){
        return [self intempt_applicationDidEnterBackground:application];
    }
}

- (void)intempt_applicationWillEnterForeground:(UIApplication *)application{
    //TBLog(@"intempt_applicationWillEnterForeground");
    
    // Tell the system that the task has ended.
    if (taskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:taskID];
        taskID =  UIBackgroundTaskInvalid;
    }
    [self checkIfNeedToStartSession];
    
    if ([self respondsToSelector:@selector(intempt_applicationWillEnterForeground:)]){
        return [self intempt_applicationWillEnterForeground:application];
    }
}


- (void)intempt_applicationWillTerminate:(UIApplication *)application{
  
    //TBLog(@"intempt_applicationWillTerminate");
    [[IntemptClient sharedClient]endTrackingSession];
    if ([self respondsToSelector:@selector(intempt_applicationWillTerminate:)]){
        return [self intempt_applicationWillTerminate:application];
    }
}

- (void)checkIfNeedToEndSession{
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"timestampaAppWentBackground"]) {
        NSNumber *timestampaAppWentBackground = [[NSUserDefaults standardUserDefaults] valueForKey:@"timestampaAppWentBackground"];
        double timestampNow = [[NSDate date] timeIntervalSince1970];
        if (timestampNow - [timestampaAppWentBackground doubleValue] >= TRACKING_SESSION_TIME_OUT){
            TBLog(@"reseting session due to time limit exceeded in background");
            [[IntemptClient sharedClient]endTrackingSession];
        }
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"timestampaAppWentBackground"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)checkIfNeedToStartSession{
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"sessionId"]) {
        if([[NSUserDefaults standardUserDefaults] valueForKey:@"timestampaAppWentBackground"]) {
            NSNumber *timestampaAppWentBackground = [[NSUserDefaults standardUserDefaults] valueForKey:@"timestampaAppWentBackground"];
            double timestampNow = [[NSDate date] timeIntervalSince1970];
            if (timestampNow - [timestampaAppWentBackground doubleValue] >= TRACKING_SESSION_TIME_OUT){
                TBLog(@"app remain longer in background, ending old session");
                
                NSString *previousSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"sessionId"];
                NSNumber *sessionWasStartedAt = [[NSUserDefaults standardUserDefaults] valueForKey:@"sessionStartedAt"];
                NSNumber *nowTime = [NSNumber numberWithDouble:[sessionWasStartedAt doubleValue] + TRACKING_SESSION_TIME_OUT];
                 
                NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
                [newEvent setValue:previousSessionId forKey:@"sessionId"];
                [newEvent setValue:sessionWasStartedAt forKey:@"session_start"];
                [newEvent setValue:nowTime forKey:@"session_end"];
                [newEvent setValue:[NSNumber numberWithInt:TRACKING_SESSION_TIME_OUT] forKey:@"duration"];
                [[IntemptClient sharedClient] addEvent:newEvent toEventCollection:@"session" withCompletion:nil];
                [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"sessionId"];
                [[NSUserDefaults standardUserDefaults]synchronize];
                
                [[IntemptClient sharedClient]startTrackingSession];
                
            }else{
                TBLog(@"session already live");
            }
        }else{
            TBLog(@"session already live");
        }
    }else{
        [[IntemptClient sharedClient]startTrackingSession];
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"timestampaAppWentBackground"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**this method is just in case developer has not overrided in UISceneDelegate
 */
- (void)sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0)){
    //TBLog(@"sceneWillEnterForeground inside intempt");
}
/**this method is just in case developer has not overrided in UISceneDelegate
 */
- (void)sceneDidEnterBackground:(UIScene *)scene API_AVAILABLE(ios(13.0)){
    //TBLog(@"sceneDidEnterBackground inside intempt");
}
/**this method is just in case developer has not overrided in AppDelegate
 */
- (void)applicationWillEnterForeground:(UIApplication *)application{
    //TBLog(@"applicationWillEnterForeground inside intempt");
}
- (void)applicationDidEnterBackground:(UIApplication *)application{
    //TBLog(@"applicationDidEnterBackground inside intempt");
}
- (void)applicationWillTerminate:(UIApplication *)application{
  
    //TBLog(@"applicationWillTerminate inside intempt");
}
@end
