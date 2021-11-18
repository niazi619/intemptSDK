//
//  UIApplication+IntemptActionTracker.m
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#import "UIApplication+IntemptActionTracker.h"
#import "IntemptUIViewDerivativesSerializer.h"
#import "IntemptClient.h"

@implementation UIApplication (ITActionTracker)
@end

@implementation UIApplication (IntemptActionTracker)
- (BOOL)intempt_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    
    if([IntemptClient isTrackingEnabled] == YES){
        __block SEL _action = action;
        __block id _target = target;
        __block id _sender = sender;
        NSMutableDictionary *actionPayload = [[NSMutableDictionary alloc] init];
        [actionPayload setObject:NSStringFromSelector(_action) forKey:@"ActionName"];
        NSDictionary *serializedSender = [IntemptUIViewDerivativesSerializer serializeUIViewDerivative:_sender];
        NSString * alpha = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"alpha"]];
        NSString * class = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"class"]];
        NSString *path, *tag, *viewController, *titleLabel, *text ;
        if ([class isEqualToString:@"UIButton"]) {
            TBLog(@"Executed from UIApplication category");
            path = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"path"]];
            tag = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"tag"]];
            viewController = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"viewController"]];
            if ([serializedSender objectForKey:@"titleLabel"]) {
                titleLabel = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"titleLabel"]];
                text = [self stringByReplacing:titleLabel];
            }
            else if ([serializedSender objectForKey:@"currentTitle"]) {
                titleLabel = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"currentTitle"]];
                text = [self stringByReplacing:titleLabel];
            }else if ([serializedSender objectForKey:@"text"]) {
                titleLabel = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"text"]];
                text = [self stringByReplacing:titleLabel];
            }
            else {
                text = @"";
            }
        }
        else if ([class isEqualToString:@"UISegmentedControl"]) {
            path = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"path"]];
            tag = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"tag"]];
            viewController = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"viewController"]];
            text = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"selectedSegmentTitle"]];
            
        }else if ([class isEqualToString:@"UIStepper"]) {
            path = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"path"]];
            tag = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"tag"]];
            viewController = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"viewController"]];
            text = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"value"]];
            
        }
        else {
            path = @"";
            tag = @"";
            viewController = @"";
            text = @"";
            if([serializedSender objectForKey:@"viewController"] != NULL && [serializedSender objectForKey:@"viewController"] != nil){
                viewController = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"viewController"]];
            }
            if([serializedSender objectForKey:@"path"] != NULL && [serializedSender objectForKey:@"path"] != nil){
                path = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"path"]];
            }
            if([serializedSender objectForKey:@"tag"] != NULL && [serializedSender objectForKey:@"tag"] != nil){
                tag = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"tag"]];
            }
            if([serializedSender objectForKey:@"text"] != NULL && [serializedSender objectForKey:@"text"] != nil){
                text = [NSString stringWithFormat:@"%@",[serializedSender objectForKey:@"text"]];
            }
        }
        
        if (serializedSender) {}
        
        NSDictionary *serializedTarget = [IntemptUIViewDerivativesSerializer serializeUIViewDerivative:_target];
        
        if(serializedTarget) {}
        
        [actionPayload setValue:alpha forKey:@"alpha"];
        [actionPayload setValue:class forKey:@"class"];
        [actionPayload setValue:path forKey:@"path"];
        [actionPayload setValue:tag forKey:@"tag"];
        [actionPayload setValue:text ? text : @"" forKey:@"text"];
        [actionPayload setValue:viewController forKey:@"viewController"];
        NSMutableDictionary *eventDictionary = [[NSMutableDictionary alloc] init];
        [eventDictionary setObject:actionPayload forKey:@"element"];
        [eventDictionary setObject:@"action" forKey:@"type"];
        //NSError *error = nil;
        BOOL wasAdded = [[IntemptClient sharedClient] addEvent:eventDictionary toEventCollection:@"interaction" withCompletion:[IntemptClient sharedClient].completion];
        if (!wasAdded) {
            TBLog(@"Failed to add event %@ to \"interaction\" collection", eventDictionary);
        }
    }else{
        TBLog(@"Tracking disabled - Not tracking actions");
    }
    
    return [self intempt_sendAction:action to:target from:sender forEvent:event];
}

- (NSString*)stringByReplacing:(NSString*)text {
    
    NSArray *ary = [text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    NSString *newString;
    if([ary containsObject:@"alpha"]) {
        NSUInteger index = [ary indexOfObject:@"alpha"];
        NSArray *subArray = [ary subarrayWithRange:NSMakeRange(10,index)];
        NSUInteger index1 = [subArray indexOfObject:@"alpha"];
        NSArray *subArray1 = [subArray subarrayWithRange:NSMakeRange(0,index1)];
        NSString *joinedString = [subArray1 componentsJoinedByString:@" "];
        NSString *prefixToRemove = @"'";
        newString = [joinedString copy];
        if ([joinedString hasPrefix:prefixToRemove])
            newString = [joinedString substringFromIndex:[prefixToRemove length]];
        newString = [newString substringToIndex:(newString.length - 2)];
    }
    else if([ary containsObject:@"opaque"]) {
        NSUInteger index = [ary indexOfObject:@"opaque"];
        NSArray *subArray = [ary subarrayWithRange:NSMakeRange(10,index)];
        NSUInteger  index1 = [subArray indexOfObject:@"opaque"];
        NSArray *subArray1 = [subArray subarrayWithRange:NSMakeRange(0,index1)];
        NSString *joinedString = [subArray1 componentsJoinedByString:@" "];
        NSString *prefixToRemove = @"'";
        newString = [joinedString copy];
        if ([joinedString hasPrefix:prefixToRemove])
            newString = [joinedString substringFromIndex:[prefixToRemove length]];
        newString = [newString substringToIndex:(newString.length - 2)];
    }
    else{
        newString = text;
    }
    
    return newString;
}

@end
