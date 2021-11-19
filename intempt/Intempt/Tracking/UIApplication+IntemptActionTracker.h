//
//  UIApplication+IntemptActionTracker.h
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

@import UIKit;

@interface UIApplication (IntemptActionTracker)

- (BOOL)intempt_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event;
- (void)intempt_applicationWillEnterForeground:(UIApplication *)application;

@end
