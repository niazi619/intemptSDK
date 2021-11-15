//
//  IntemptTracker.m
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#import "IntemptTracker.h"
#import "JRSwizzle.h"
#import "IntemptTouchTracker.h"
#import "IntemptNotificationCenterTracker.h"
#import "UIApplication+IntemptActionTracker.h"
#import "UIViewController+IntemptActionTracker.h"
#import "IntemptConstants.h"
#import "IntemptClient.h"

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
            NSAssert(NULL, @"Origanization ID or source ID or token must not be blank.");
        }
        
        TBLog(@"Init was called with orgId \"%@\", trackerId \"%@\" and token \"%@\"", orgId, sourceId, token);
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

        // Actions tracker initialization
        static dispatch_once_t actionTrackingToken;
        dispatch_once(&actionTrackingToken, ^{
            NSError *error;
            BOOL result = [UIApplication jr_swizzleMethod:@selector(sendAction:to:from:forEvent:) withMethod:@selector(intempt_sendAction:to:from:forEvent:) error:&error];
            if (!result || error) {
                TBLog(@"Can't swizzle methods - %@", [error description]);
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
        
        // Touch tracker initialization
        IntemptTouchTracker *recognizer = [[IntemptTouchTracker alloc] initWithTarget:nil action:nil];
        [recognizer setCancelsTouchesInView:NO];
        
        UIApplication *application = [UIApplication sharedApplication];
        NSArray *appWindows = [NSArray arrayWithArray:application.windows];
        UIWindow *mainWindow = [appWindows objectAtIndex:0];
        
        [mainWindow addGestureRecognizer:recognizer];

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
