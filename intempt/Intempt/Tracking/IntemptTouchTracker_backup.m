//
//  IntemptTouchTracker.m
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#import "IntemptTouchTracker.h"

#import "IntemptUIViewDerivativesSerializer.h"
#import "IntemptClient.h"


#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation IntemptTouchTracker

- (id)init {
    if (self = [super init])  {
        // do init here
        //self.notaion = NTH_CHILD;
        //self.pathType = CSS_PATH;
    }

    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    __block NSSet *_touches = [touches copy];
    
    // dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //  dispatch_async(queue, ^{
    for (UITouch* touch in _touches) {
        //CGPoint location = [touch locationInView:self.view];
        //UIView* v = [self.view hitTest:location withEvent:nil];
        UIView* v = touch.view;
        
        NSDictionary* serializedView = [IntemptUIViewDerivativesSerializer serializeUIViewDerivative:v];
        
        if (serializedView) {
            NSMutableDictionary *eventDictionary = [[NSMutableDictionary alloc] init];

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
            [eventDictionary setObject:elementDictionary forKey:@"element"];
            
            [eventDictionary setObject:@"touch" forKey:@"type"];
            
            NSError *error;
            BOOL wasAdded = [[IntemptClient sharedClient] addEvent:eventDictionary toEventCollection:@"interaction" error:&error];
            if (!wasAdded || error) {
                NSLog(@"Failed to add event %@ to \"interaction\" collection with error: %@", eventDictionary, error);
            }
        }
    }
    // });
    
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
}

- (void)ignoreTouch:(UITouch *)touch forEvent:(UIEvent *)event {
    //	Overriding this prevents touchesMoved:withEvent:
    //	not being called after moving a certain threshold
}

@end
