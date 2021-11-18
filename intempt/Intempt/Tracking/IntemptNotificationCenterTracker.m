//
//  IntemptNotificationCenterTracker.m
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#import "IntemptNotificationCenterTracker.h"
#import "SpacemanBlocks.h"

#import "IntemptUIViewDerivativesSerializer.h"
#import "IntemptClient.h"

@interface IntemptNotificationCenterTracker () {
    NSMutableDictionary<NSValue *, SMDelayedBlockHandle>* _delayedTextBlockHandles, * _delayedTextViewBlockHandles;
}
@end

@implementation IntemptNotificationCenterTracker

- (id)init {
    if (self = [super init]) {
        _delayedTextBlockHandles = [[NSMutableDictionary alloc] init];
        _delayedTextViewBlockHandles = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChange:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)textFieldDidChange:(NSNotification*)notification {
    UITextField* changedTextField = notification.object;
    NSValue* textFieldValue = [NSValue valueWithNonretainedObject:changedTextField];
    
    if([IntemptClient isTrackingEnabled] == YES){
        Boolean isSecure = changedTextField.secureTextEntry;
        
        if (isSecure) {
            // secure text field changes must not be tracked
            return;
        }
        
        SMDelayedBlockHandle _delayedTextBlockHandler = [_delayedTextBlockHandles objectForKey:textFieldValue];
        if (_delayedTextBlockHandler) {
            // cancel previous block
            
            _delayedTextBlockHandler(YES);
            _delayedTextBlockHandler = nil;
        }
        
        _delayedTextBlockHandler = perform_block_after_delay(.5f, ^{
            // Work
            // let's serialize event
            NSDictionary *serializedTextField = [IntemptUIViewDerivativesSerializer serializeUIViewDerivative:changedTextField];
            NSString * alpha = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"alpha"]];
                
            NSString * text = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"text"]];
            NSString * class = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"class"]];
            NSString * path = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"path"]];
            NSString * tag = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"tag"]];
            NSString * viewController = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"viewController"]];

                 
            NSMutableDictionary *elementDictionary = [[NSMutableDictionary alloc] init];
            [elementDictionary setValue:text forKey:@"text"];
            [elementDictionary setValue:@"" forKey:@"ActionName"];
            [elementDictionary setValue:alpha forKey:@"alpha"];
            [elementDictionary setValue:class forKey:@"class"];
            [elementDictionary setValue:path forKey:@"path"];
            [elementDictionary setValue:tag forKey:@"tag"];
            [elementDictionary setValue:viewController forKey:@"viewController"];

            if (serializedTextField) {
                NSMutableDictionary *eventDictionary = [[NSMutableDictionary alloc] init];
                [eventDictionary setObject:elementDictionary forKey:@"element"];
                
                [eventDictionary setObject:@"change" forKey:@"type"];
                
                //NSError *error = nil;
                BOOL wasAdded = [[IntemptClient sharedClient] addEvent:eventDictionary toEventCollection:@"interaction" withCompletion:[IntemptClient sharedClient].completion];
                if (!wasAdded) {
                    TBLog(@"Failed to add event %@ to \"interaction\" collection", eventDictionary);
                }
            }
       
            [self->_delayedTextBlockHandles removeObjectForKey:textFieldValue];
        });
        
        [_delayedTextBlockHandles setObject:_delayedTextBlockHandler forKey:textFieldValue];
    }
}

- (void)textViewDidChange:(NSNotification*)notification {
    
    if([IntemptClient isTrackingEnabled] == YES){
        UITextView *changedTextView = notification.object;
        NSValue *textViewValue = [NSValue valueWithNonretainedObject:changedTextView];
        
        SMDelayedBlockHandle _delayedTextViewBlockHandler = [_delayedTextBlockHandles objectForKey:textViewValue];
        if (_delayedTextViewBlockHandler) {
            // cancel previous block
            
            _delayedTextViewBlockHandler(YES);
            _delayedTextViewBlockHandler = nil;
        }
        
        _delayedTextViewBlockHandler = perform_block_after_delay(.5f, ^{
            // Work
            // let's serialize event
            NSDictionary *serializedTextField = [IntemptUIViewDerivativesSerializer serializeUIViewDerivative:changedTextView];
            NSString * alpha = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"alpha"]];
                
            NSString * text = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"text"]];
            NSString * class = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"class"]];
            NSString * path = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"path"]];
            NSString * tag = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"tag"]];
            NSString * viewController = [NSString stringWithFormat:@"%@",[serializedTextField objectForKey:@"viewController"]];

                 
            NSMutableDictionary *elementDictionary = [[NSMutableDictionary alloc] init];
            [elementDictionary setValue:text forKey:@"text"];
            [elementDictionary setValue:@"" forKey:@"ActionName"];
            
            [elementDictionary setValue:alpha forKey:@"alpha"];
            [elementDictionary setValue:class forKey:@"class"];
            [elementDictionary setValue:path forKey:@"path"];
            [elementDictionary setValue:tag forKey:@"tag"];
            [elementDictionary setValue:viewController forKey:@"viewController"];

            if (serializedTextField) {
                NSMutableDictionary *eventDictionary = [[NSMutableDictionary alloc] init];
                [eventDictionary setObject:elementDictionary forKey:@"element"];
                
                [eventDictionary setObject:@"change" forKey:@"type"];
                
                //NSError *error = nil;
                BOOL wasAdded = [[IntemptClient sharedClient] addEvent:eventDictionary toEventCollection:@"interaction" withCompletion:[IntemptClient sharedClient].completion];
                if (!wasAdded) {
                    TBLog(@"Failed to add event %@ to \"interaction\" collection", eventDictionary);
                }
            }
       
            [self->_delayedTextBlockHandles removeObjectForKey:textViewValue];
        });
        
        [_delayedTextBlockHandles setObject:_delayedTextViewBlockHandler forKey:textViewValue];
    }

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//
@end
