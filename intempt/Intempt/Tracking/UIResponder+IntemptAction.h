//
//  UIScene+IntempAction.h
//  Intempt
//
//  Created by MacBook on 19/11/2021.
//  Copyright © 2021 Intempt. All rights reserved.
//

@import UIKit;

@interface UIResponder (IntemptAction)
- (void)intempt_sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0));
- (void)intempt_sceneDidEnterBackground:(UIScene *)scene API_AVAILABLE(ios(13.0));
- (void)intempt_applicationWillTerminate:(UIApplication *)application;
- (void)intempt_applicationWillEnterForeground:(UIApplication *)application;
- (void)intempt_applicationDidEnterBackground:(UIApplication *)application;


- (void)sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0));
- (void)sceneDidEnterBackground:(UIScene *)scene API_AVAILABLE(ios(13.0));
- (void)applicationWillEnterForeground:(UIApplication *)application;
- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationWillTerminate:(UIApplication *)application;
@end
