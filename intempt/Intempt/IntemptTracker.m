//
//  IntemptTracker.m
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IntemptTracker.h"
#import "JRSwizzle.h"
#import "IntemptTouchTracker.h"
#import "IntemptNotificationCenterTracker.h"
#import "UIApplication+IntemptActionTracker.h"
#import "UIViewController+IntemptActionTracker.h"
#import "IntemptConstants.h"
#import "IntemptClient.h"
#import "UIResponder+IntemptAction.h"

#if TARGET_OS_IPHONE
    #import <objc/runtime.h>
    #import <objc/message.h>
#else
    #import <objc/objc-class.h>
#endif

@implementation IntemptTracker
static IntemptNotificationCenterTracker* notificationsClient;
static ITGeoLocationState geoLocationState = GEO_ENABLED_ALWAYS;

//Store given orgId, trackerId and token for subsequent use
static NSString *_orgId;
static NSString *_trackerId;
static NSString *_token;

+ (void)trackingWithOrgId:(NSString*)orgId withSourceId:(NSString*)sourceId withToken:(NSString*)token withConfig:(id)settings onCompletion:(CompletionHandler)handler {

    @autoreleasepool {
        
        if (orgId == nil || orgId.length == 0 || sourceId == nil || sourceId.length == 0 || token == nil || token .length == 0) {
            NSError *error = [NSError errorWithDomain:@"Origanization ID or source ID or token must not be blank." code:1001 userInfo:nil];
            handler(NO, nil, error);
            NSAssert(NULL, @"Origanization ID or source ID or token must not be blank.");
        }
        
        //TBLog(@"Init was called with orgId \"%@\", trackerId \"%@\" and token \"%@\"", orgId, sourceId, token);
        _orgId = orgId;
        _trackerId = sourceId;
        _token = token;
        
        // initialize the tracking
        // first, adjust geolocation settings
        switch (geoLocationState) {
            case GEO_ENABLED_ALWAYS:
                [IntemptClient authorizeGeoLocationAlways];
                //[IntemptClient enableGeoLocation];
                break;
            case GEO_ENABLED_IN_USE:
                [IntemptClient authorizeGeoLocationWhenInUse];
                //[IntemptClient enableGeoLocation];
            default: // disabled by default
                //[IntemptClient disableGeoLocation];
                break;
        }
     
        #ifdef DEBUG
            [IntemptClient enableLogging];
        #endif
        [IntemptClient sharedClientWithOrganizationId:_orgId withTrackerId:_trackerId withToken:_token withConfig:settings  withCompletion:handler];
        [[IntemptClient sharedClient]validateTrackingSession];
        //launch event should affter session and profile
        [[IntemptClient sharedClient] refreshCurrentLocation];
        
        // UISceneDelegate tracker initialization
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
            // Actions tracker initialization
            static dispatch_once_t actionTrackingToken;
            dispatch_once(&actionTrackingToken, ^{
                NSError *error;
                BOOL result = [UIApplication jr_swizzleMethod:@selector(sendAction:to:from:forEvent:) withMethod:@selector(intempt_sendAction:to:from:forEvent:) error:&error];
                if (!result || error) {
                    TBLog(@"Can't swizzle methods - %@", [error description]);
                }
            });
            
            static dispatch_once_t sceneTrackingToken;
            dispatch_once(&sceneTrackingToken, ^{
                if (@available(iOS 13.0, *)) {
                    
                    ////we created category using UIResponder interface UIResponder+IntemptAction
                    Class class = objc_getClass("UIResponder");
                    Class connectedScene = [[[[[UIApplication sharedApplication]connectedScenes]allObjects]firstObject].delegate class];
                    if(class && connectedScene){
                        SEL originalSelector = @selector(sceneWillEnterForeground:);
                        SEL swizzledSelector = @selector(intempt_sceneWillEnterForeground:);

                        Method originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
                        
                        ///incase developer has not overrided the sceneWillEnterForeground of UISceneDelegate then we must have  to inject method
                        if(!originalMethod){
                            
                            ///we implemented a method in UIResponder+IntemptAction with the name sceneWillEnterForeground, we get that implementation and inject in UISceneDelegate
                            Method swizzledOriginalMethod = class_getInstanceMethod(class, originalSelector);
                            class_addMethod(connectedScene,
                                            originalSelector,
                                            class_getMethodImplementation(class, originalSelector),
                                            method_getTypeEncoding(swizzledOriginalMethod));
                            
                            ////as we just injected method so get reference again to swizzle
                            originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                        }
                        method_exchangeImplementations(originalMethod, swizzledMethod);
                    }
                    if(class && connectedScene){
                        SEL originalSelector = @selector(sceneDidEnterBackground:);
                        SEL swizzledSelector = @selector(intempt_sceneDidEnterBackground:);

                        Method originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
                        
                        ///incase developer has not overrided the sceneDidEnterBackground of UISceneDelegate then we must have  to inject method
                        if(!originalMethod){
                            
                            ///we implemented a method in UIResponder+IntemptAction with the name sceneDidEnterBackground, we get that implementation and inject in UISceneDelegate
                            Method swizzledOriginalMethod = class_getInstanceMethod(class, originalSelector);
                            class_addMethod(connectedScene,
                                            originalSelector,
                                            class_getMethodImplementation(class, originalSelector),
                                            method_getTypeEncoding(swizzledOriginalMethod));
                            
                            ////as we just injected method so get reference again to swizzle
                            originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                        }
                        method_exchangeImplementations(originalMethod, swizzledMethod);
                    }
                }
            });
            
            // AppDelegate delegates tracker initialization
            static dispatch_once_t appTrackingToken;
            dispatch_once(&appTrackingToken, ^{
                
                ////we created category using UIResponder interface UIResponder+IntemptAction
                Class class = objc_getClass("UIResponder");
                Class connectedScene = [[[UIApplication sharedApplication]delegate]class];
                if(class && connectedScene){
                    SEL originalSelector = @selector(applicationWillEnterForeground:);
                    SEL swizzledSelector = @selector(intempt_applicationWillEnterForeground:);

                    Method originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
                    
                    ///incase developer has not overrided the applicationWillEnterForeground of AppDelegate then we must have  to inject method
                    if(!originalMethod){
                        
                        ///we implemented a method in UIResponder+IntemptAction with the name applicationWillEnterForeground, we get that implementation and inject in AppDelegate
                        Method swizzledOriginalMethod = class_getInstanceMethod(class, originalSelector);
                        class_addMethod(connectedScene,
                                        originalSelector,
                                        class_getMethodImplementation(class, originalSelector),
                                        method_getTypeEncoding(swizzledOriginalMethod));
                        
                        ////as we just injected method so get reference again to swizzle
                        originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                    }
                    method_exchangeImplementations(originalMethod, swizzledMethod);
                }
                
                if(class && connectedScene){
                    SEL originalSelector = @selector(applicationDidEnterBackground:);
                    SEL swizzledSelector = @selector(intempt_applicationDidEnterBackground:);

                    Method originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
                    
                    ///incase developer has not overrided the applicationWillTerminate of AppDelegate then we must have  to inject method
                    if(!originalMethod){
                        
                        ///we implemented a method in UIResponder+IntemptAction with the name applicationWillTerminate, we get that implementation and inject in AppDelegate
                        Method swizzledOriginalMethod = class_getInstanceMethod(class, originalSelector);
                        class_addMethod(connectedScene,
                                        originalSelector,
                                        class_getMethodImplementation(class, originalSelector),
                                        method_getTypeEncoding(swizzledOriginalMethod));
                        
                        ////as we just injected method so get reference again to swizzle
                        originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                    }
                    method_exchangeImplementations(originalMethod, swizzledMethod);
                }
                
                if(class && connectedScene){
                    SEL originalSelector = @selector(applicationWillTerminate:);
                    SEL swizzledSelector = @selector(intempt_applicationWillTerminate:);

                    Method originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
                    
                    ///incase developer has not overrided the applicationWillTerminate of AppDelegate then we must have  to inject method
                    if(!originalMethod){
                        
                        ///we implemented a method in UIResponder+IntemptAction with the name applicationWillTerminate, we get that implementation and inject in AppDelegate
                        Method swizzledOriginalMethod = class_getInstanceMethod(class, originalSelector);
                        class_addMethod(connectedScene,
                                        originalSelector,
                                        class_getMethodImplementation(class, originalSelector),
                                        method_getTypeEncoding(swizzledOriginalMethod));
                        
                        ////as we just injected method so get reference again to swizzle
                        originalMethod = class_getInstanceMethod(connectedScene, originalSelector);
                    }
                    method_exchangeImplementations(originalMethod, swizzledMethod);
                }
                
            });
                        
            // Touch tracker initialization
            IntemptTouchTracker *recognizer = [[IntemptTouchTracker alloc] initWithTarget:nil action:nil];
            [recognizer setCancelsTouchesInView:NO];
            
            UIApplication *application = [UIApplication sharedApplication];
            NSArray *appWindows = [NSArray arrayWithArray:application.windows];
            if (appWindows){
                if(appWindows.count > 0){
                    UIWindow *mainWindow = [appWindows objectAtIndex:0];
                    [mainWindow addGestureRecognizer:recognizer];
                }
             }
            
        });
        
        // View tracker initialization
        static dispatch_once_t viewTrackingToken;
        dispatch_once(&viewTrackingToken, ^{
            NSError *error;
            BOOL result = [UIViewController jr_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(intempt_viewDidAppear:) error:&error];
            if (!result || error) {
                TBLog(@"Can't swizzle methods - %@", [error description]);
            }
        });
        
        NSString *msg = [NSString stringWithFormat:@"Init was called with orgId \"%@\", trackerId \"%@\" and token \"%@\"", orgId, sourceId, token];
        handler(YES, [NSDictionary dictionaryWithObject:msg forKey:@"info"] , nil);
        //Initialize notifications center listener. Text input capture is enabled by default.
        //notificationsClient = [[IntemptNotificationCenterTracker alloc] init];
        //[self disableTextInput:[IntemptClient sharedClient].config.isInputTextCaptureDisabled];
    }
}


/*+ (void)disableTextInput:(BOOL)status {
    if(status) {
        if(notificationsClient != nil) {
            [[NSNotificationCenter defaultCenter] removeObserver:notificationsClient name:UITextFieldTextDidChangeNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:notificationsClient name:UITextViewTextDidChangeNotification object:nil];
            notificationsClient = nil;
        }
    }
    else {
        notificationsClient = [[IntemptNotificationCenterTracker alloc] init];
    }
}*/

+ (void)enableGeoLocationAlways {
    geoLocationState = GEO_ENABLED_ALWAYS;
}

+ (void)enableGeoLocationInUse {
    geoLocationState = GEO_ENABLED_IN_USE;
}

+ (void)identify:(NSString*)identity withProperties:(NSDictionary*)userProperties onCompletion:(CompletionHandler)handler {

    IntemptClient *client = [IntemptClient sharedClient];
    if (!client) {
        [NSException raise:@"IdentifyBeforeTrackingStart" format:@"identifyVisitor was called before tracking was started"];
    }
    
    return [client identify:identity withProperties:userProperties withCompletion:handler];
}

/*+ (BOOL)addEvent:(NSDictionary*)event toEventCollection:(NSString*)eventCollection error:(NSError**)error {
    
    if(event == nil || event.count == 0) {
        NSLog(@"Event can't not be blank.");
        return NO;
    }
    
    IntemptClient *client = [IntemptClient sharedClient];
    if (!client) {
        [NSException raise:@"AddEventBeforeTrackingStart" format:@"addEvent was called before tracking was started"];
    }
    
    return [client addEvent:event toEventCollection:@"" error:error];
}*/

+ (void)track:(NSString*)collectionName withProperties:(NSArray*)userProperties onCompletion:(CompletionHandler)handler {
    
    if (collectionName == nil || [collectionName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        TBLog(@"Collection name can not be blank.");
        return;
    }
    
    IntemptClient *client = [IntemptClient sharedClient];
    if (!client) {
        [NSException raise:@"IdentifyBeforeTrackingStart" format:@"identifyVisitor was called before tracking was started"];
    }
       
    return [client track:collectionName withProperties:userProperties withCompletion:handler];
}

+ (void)beaconWithOrgId:(NSString*)orgId andSourceId:(NSString*)sourceId andToken:(NSString*)token andDeviceUUID:(NSString*)uuid onCompletion:(CompletionHandler)handler {
    
    if (orgId == nil || orgId.length == 0 || sourceId == nil || sourceId.length == 0 || token == nil || token .length == 0 || uuid == nil || uuid.length == 0) {
        NSAssert(NULL, @"Origanization ID or source ID or token or device uuid must not be blank.");
    }
    TBLog(@"Beacon initialized with orgId %@, trackerId %@, token %@ and uuid %@", orgId, sourceId, token,uuid);
    
    TBLog(@"--------------- orgId %@, trackerId %@, token %@", _orgId, _trackerId, _token);
    [IntemptClient sharedClientWithOrganizationId:_orgId withTrackerId:_trackerId withToken:_token withConfig:nil withCompletion:handler];
    
    IntemptClient *client = [IntemptClient sharedClient];
    if (!client) {
        [NSException raise:@"IdentifyBeforeTrackingStart" format:@"identifyVisitor was called before tracking was started"];
    }
       
    return [client withOrgId:orgId andSourceId:sourceId andToken:token uuidString:uuid withCompletion:handler];
}

+ (void)identifyUsingBeaconWith:(NSString*)identity withProperties:(NSDictionary*)userProperties onCompletion:(CompletionHandler)handler {

    IntemptClient *client = [IntemptClient sharedClient];
    if (!client) {
        [NSException raise:@"IdentifyBeforeTrackingStart" format:@"identifyVisitor was called before tracking was started"];
    }
    
    return [client identifyUsingBeaconWith:identity withProperties:userProperties withCompletion:handler];
}

@end
