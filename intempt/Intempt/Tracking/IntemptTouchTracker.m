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
#import "UIView+RecurrenceSubviews.h"

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
    
    if([IntemptClient isTrackingEnabled] == YES){
        for (UITouch *touch in touches) {
        
            CGPoint touchPoint = [touch locationInView:touch.view];
            TBLog(@"touch=%f,%f", touchPoint.x, touchPoint.y);
            NSString *val = NSStringFromClass([touch.view.superclass class]);
            if ([val isEqualToString:@"UIControl"] || [touch.view isKindOfClass:[UISwitch class]] ){
                ////UIButton and other Actions which are inherited from UIControl are recorded by IntemptActionTracker, so we should avoid duplicate events gernerating
                TBLog(@"IntemptActionTracker will log:-------%@",[val class]);
            }else{
                //[self createEventDictionaryWith:touch.view];
                
                if (touch.view != nil){
                    NSString *entityClass = NSStringFromClass([touch.view class]);
                    TBLog(@"entityClass super=%@",entityClass);
                    ////UITextView take touch itself, so we need to check it first
                    if ([touch.view isKindOfClass:[UITextView class]]){
                        [self createEventDictionaryWith:touch.view];
                    }else{
                        ////Additionally extract all Labels as by default UILabel are not clickable
                        NSMutableArray *arrViews = [NSMutableArray array];
                        [arrViews addObject:touch.view];
                        NSArray *arrSubViews = [touch.view recurrenceAllSubviews];
                        [arrViews addObjectsFromArray:arrSubViews];
                        if(arrViews.count > 0) {
                             for (UIView *view in arrViews) {
                                 ////track only  which are tapped by checking touch point intersect with subviews
                                 //TBLog(@"view frame=%f,%f,%f,%f",view.frame.origin.x,view.frame.origin.y, view.frame.size.width, view.frame.size.height);
                                 //NSString *entityClass = NSStringFromClass([view class]);
                                 //TBLog(@"entityClass=%@",entityClass);
                                 if(CGRectContainsPoint(view.frame, touchPoint)){
                                     if([view isKindOfClass:[UILabel class]] || [view isKindOfClass:[UIImageView class]] || [view isKindOfClass:[UITextView class]]){
                                         [self createEventDictionaryWith:view];
                                     }
                                 }
                             }
                        }
                    }
                }
            }
        }
    }else{
        TBLog(@"Tracking disabled - Not tracking touches");
    }
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
}

- (void)ignoreTouch:(UITouch *)touch forEvent:(UIEvent *)event {
    //	Overriding this prevents touchesMoved:withEvent:
    //	not being called after moving a certain threshold
    
}

- (void)createEventDictionaryWith:(UIView *)subview {
    
    if(subview == nil)
        return;
    
    NSDictionary *serializedView = [IntemptUIViewDerivativesSerializer serializeUIViewDerivative:subview];
    //TBLog(@"serializedView:-------%@",serializedView);
    
    if (serializedView) {
        NSMutableDictionary *eventDictionary = [[NSMutableDictionary alloc] init];
        
        NSString * alpha = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"alpha"]];
        NSString * class = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"class"]];
        NSString * path = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"path"]];
        NSString * tag = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"tag"]];
        NSString * viewController = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"viewController"]];
        
        //TBLog(@"CLASS NAME: %@",class);
        
        NSMutableDictionary *elementDictionary = [[NSMutableDictionary alloc] init];
        if(alpha == (id)[NSNull null] || alpha.length == 0 || [alpha isEqualToString:@"(null)"]) {
            [elementDictionary setValue:@"0" forKey:@"alpha"];
        }
        else {
            [elementDictionary setValue:alpha forKey:@"alpha"];
        }
        [elementDictionary setValue:class forKey:@"class"];
        [elementDictionary setValue:path forKey:@"path"];
        [elementDictionary setValue:tag forKey:@"tag"];
        [elementDictionary setValue:@"" forKey:@"ActionName"];
        
        if ([subview isKindOfClass:[UILabel class]]) {
            NSString *titleLabel = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"text"]];
            
            if(titleLabel == (id)[NSNull null] || titleLabel.length == 0 || [titleLabel isEqualToString:@"(null)"]) {
                [elementDictionary setValue:@"" forKey:@"text"];
            }
            else {
                //TBLog(@"Label: %@",titleLabel);
                [elementDictionary setValue:titleLabel forKey:@"text"];
            }
        }else if ([subview isKindOfClass:[UITextView class]]) {
            NSString *titleLabel = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"text"]];
            
            if(titleLabel == (id)[NSNull null] || titleLabel.length == 0 || [titleLabel isEqualToString:@"(null)"]) {
                [elementDictionary setValue:@"" forKey:@"text"];
            }
            else {
                //TBLog(@"Label: %@",titleLabel);
                [elementDictionary setValue:titleLabel forKey:@"text"];
            }
        }else if ([subview isKindOfClass:[UITextField class]]) {
            NSString *titleLabel = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"text"]];
            
            if(titleLabel == (id)[NSNull null] || titleLabel.length == 0 || [titleLabel isEqualToString:@"(null)"]) {
                [elementDictionary setValue:@"" forKey:@"text"];
            }
            else {
                //TBLog(@"Label: %@",titleLabel);
                [elementDictionary setValue:titleLabel forKey:@"text"];
            }
        }
        else if ([subview isKindOfClass:[UIButton class]]) {
            NSString *titleLabel = [NSString stringWithFormat:@"%@",[serializedView objectForKey:@"text"]];
            
            if(titleLabel == (id)[NSNull null] || titleLabel.length == 0 || [titleLabel isEqualToString:@"(null)"]) {
                [elementDictionary setValue:@"" forKey:@"text"];
            }
            else {
                //TBLog(@"Button: %@",titleLabel);
                [elementDictionary setValue:titleLabel forKey:@"text"];
            }
            
            /*NSArray *arrBtnContents = [[serializedView objectForKey:@"titleLabel"] componentsSeparatedByString:@";"];
            for (NSString *element in arrBtnContents) {
                if([element containsString:@"text"]){
                    NSString *title = [[element stringByReplacingOccurrencesOfString:@"text = '" withString:@""] stringByReplacingOccurrencesOfString:@"'" withString:@""];
                    [elementDictionary setValue:[title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"text"];
                    break;
                }
            }*/
        }
        else {
            [elementDictionary setValue:@"" forKey:@"text"];
        }
        
        [elementDictionary setValue:viewController forKey:@"viewController"];
        [eventDictionary setObject:elementDictionary forKey:@"element"];
        
        [eventDictionary setObject:@"touch" forKey:@"type"];
        
        //NSError *error = nil;
        BOOL wasAdded = [[IntemptClient sharedClient] addEvent:eventDictionary toEventCollection:@"interaction" withCompletion:[IntemptClient sharedClient].completion];
        if (!wasAdded) {
            TBLog(@"Failed to add event %@ to \"interaction\" collection", eventDictionary);
        }
    }
}

@end
