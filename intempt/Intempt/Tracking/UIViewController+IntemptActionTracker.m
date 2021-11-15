//
//  UIViewController+IntemptActionTracker.m
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#import "UIViewController+IntemptActionTracker.h"
#import "JRSwizzle.h"

#import "IntemptUIViewDerivativesSerializer.h"
#import "IntemptClient.h"

@implementation UIViewController (ITActionTracker)

- (void)intempt_viewDidAppear:(BOOL)animated {
    NSString* viewClassString = NSStringFromClass([self class]);
    if ([viewClassString hasPrefix:@"UI"]) {
        return;
    }
    
    __block UIView *_view = self.view;
    
//  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
//  dispatch_async(queue, ^{
    NSDictionary *serializedView = [IntemptUIViewDerivativesSerializer serializeUIViewDerivative:_view];
    NSString * alpha = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"alpha"]];
    NSString * class = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"class"]];
    NSString * path = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"path"]];
    NSString * tag = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"tag"]];
    NSString * viewController = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"viewController"]];

    NSMutableDictionary *elementDictionary = [[NSMutableDictionary alloc] init];
    [elementDictionary setValue:alpha forKey:@"alpha"];
    [elementDictionary setValue:class forKey:@"class"];
    [elementDictionary setValue:path forKey:@"path"];
    [elementDictionary setValue:tag forKey:@"tag"];
    [elementDictionary setValue:@"" forKey:@"ActionName"];
    [elementDictionary setValue:@"" forKey:@"text"];
    [elementDictionary setValue:viewController forKey:@"viewController"];

    if (serializedView) {
        NSMutableDictionary *eventDictionary = [[NSMutableDictionary alloc] init];
        [eventDictionary setObject:elementDictionary forKey:@"element"];
        //NSError *error = nil;
        BOOL wasAdded = [[IntemptClient sharedClient] addEvent:eventDictionary toEventCollection:@"App" withCompletion:[IntemptClient sharedClient].completion];
        if (!wasAdded) {
            TBLog(@"Failed to add event %@ to \"view\" collection", eventDictionary);
        }
    }
 // });
}

@end
