//
//  IntemptClient.m
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

@import UIKit;
#include <math.h>
#import "IntemptClient.h"
//#import "JRSwizzle.h"
#import "Reachability.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "IntemptConstants.h"
#import "NSMutableArray+QueueAdditions.h"
#import "IntemptNotificationCenterTracker.h"
#import "DBManager.h"
#import "ModelEvent.h"

typedef void(^RetryCompletion)(NSData *data, NSURLResponse *response, NSError *error);

static IntemptClient *sharedClient;
static IntemptNotificationCenterTracker* notificationsClient;
static BOOL authorizedGeoLocationAlways = NO;
static BOOL authorizedGeoLocationWhenInUse = NO;
static BOOL geoLocationEnabled = NO;
static BOOL loggingEnabled = NO;
static BOOL trackingEnabled = YES;


@interface IntemptClient ()<CLLocationManagerDelegate> {
    NSString *visitorId, *cfBundleIdentifier, *parentId, *eventId, *brand, *strMajor;
    int exitFlag;
    NSMutableDictionary *profileDic, *sceneDic, *interactionDic, *deviceDic, *geoDic, *appDic, *launchDic, *screenDic;
    NSMutableArray *arrProfile, *arrLaunch, *arrScreen, *arrInteraction;
    NSMutableDictionary *dictValue;
    NSString *region, *country, *city;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    
    NSString *sessionId;
    
    /*NSMutableArray *arrBeacon;
     double latitude;
     double longitude;
     NSString *proximityVisitorId;*/
}

// The project ID for this particular client.
@property (nonatomic, strong) NSString *organizationId;

// The Write Key for this particular client.
@property (nonatomic, strong) NSString *sourceId;

// The Read Key for this particular client.
@property (nonatomic, strong) NSString *token;

// NSLocationManager
@property (nonatomic, strong) CLLocationManager *locationManager;

// A dispatch queue used for uploads.
@property (nonatomic) dispatch_queue_t uploadQueue;


@property (assign, nonatomic) NSInteger currentState;
@property (strong, nonatomic) NSMutableArray *majorArrayData;
@property (strong, nonatomic) NSMutableArray *filterBuffer;
@property (strong, nonatomic) NSMutableArray *entryArray;
@property (strong, nonatomic) NSMutableArray *exitArray;
@property (strong, nonatomic) NSDictionary *propertiesOverridesDictionary;

@property(nonatomic,strong) NSTimer *timerSync;
/**
 Initializes IntemptClient without setting its project ID or API key.
 @returns An instance of IntemptClient.
 */
- (id)init;

/**
 Validates that the given organization ID is valid.
 @param orgId The Intempt organization ID.
 @returns YES if project id is valid, NO otherwise.
 */
+ (BOOL)validateOrganizationId:(NSString *)orgId;

/**
 Validates that the given key is valid.
 @param key The key to check.
 @returns YES if key is valid, NO otherwise.
 */
+ (BOOL)validateTrackerId:(NSString *)key;

/**
 Validates that the given token is valid.
 @param key The key to check.
 @returns YES if key is valid, NO otherwise.
 */
+ (BOOL)validateToken:(NSString *)key;


@end


@implementation IntemptClient

@synthesize organizationId=_organizationId;
@synthesize sourceId=_sourceId;
@synthesize token=_token;
@synthesize locationManager=_locationManager;
@synthesize currentLocation=_currentLocation;
@synthesize propertiesOverridesDictionary=_propertiesOverridesDictionary;
@synthesize uploadQueue;

# pragma mark - Class lifecycle


- (id)init {
    self = [super init];
    
    #ifdef DEBUG
        loggingEnabled = YES;
    #endif
    trackingEnabled = YES;
    // log the current version number
    NSLog(@"IntemptClient-iOS %@", kIntemptSdkVersion);
    //create database on start
    [DBManager shared];
    /*_completion = ^(BOOL status, id result, NSError *error) {
     };*/
    
    //TBLog(@"VisitorId-------------------------------: %@",visitorId);
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if([userDefault valueForKey:@"Intempt_Tracking_Flag"]){
        NSString *valTracking = [userDefault valueForKey:@"Intempt_Tracking_Flag"];
        if([valTracking isEqualToString:@"NO"]){
            trackingEnabled = NO;
            NSLog(@"Intempt Tracking Disabled");
        }
    }

    brand = @"Apple";
    /*----*/
    //arrInteraction = [[NSMutableArray alloc] init];
    //arrBeacon = [[NSMutableArray alloc] init];
    country = @"";
    city = @"";
    region = @"";
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"visitorId"]) {
        visitorId = [[NSUserDefaults standardUserDefaults] valueForKey:@"visitorId"];
    }else{
        visitorId = [self generateUUIDNoDashes];
        [[NSUserDefaults standardUserDefaults] setValue:visitorId forKey:@"visitorId"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.uploadQueue = dispatch_queue_create("intempt.uploader", DISPATCH_QUEUE_SERIAL);
    self.currentState = 0;
    self.filterBuffer = [[NSMutableArray alloc] init];
    self.entryArray = [[NSMutableArray alloc] init];
    self.exitArray = [[NSMutableArray alloc] init];
    self.majorArrayData = [[NSMutableArray alloc] init];
    
    //TBLog(@"Main Initialization============================%@", self);
    return self;
}

- (void)validateTrackingSession{
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"sessionId"]) {
        NSString *previousSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"sessionId"];
        NSNumber *sessionWasStartedAt = [[NSUserDefaults standardUserDefaults] valueForKey:@"sessionStartedAt"];
        NSNumber *nowTime = [IntemptClient addTimestamp];
        NSNumber *diffTime =  [NSNumber numberWithDouble:[nowTime doubleValue] - [sessionWasStartedAt doubleValue]];
         
        NSLog(@"session ending with Id = %@ of duration = %f", previousSessionId, [diffTime doubleValue]);
        
        NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
        [newEvent setValue:previousSessionId forKey:@"sessionId"];
        [newEvent setValue:sessionWasStartedAt forKey:@"session_start"];
        [newEvent setValue:nowTime forKey:@"session_end"];
        [newEvent setValue:diffTime forKey:@"duration"];
        [self addEvent:newEvent toEventCollection:@"session" withCompletion:nil];
        
        //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
        //});
        
        sessionId = [self generateUUIDNoDashes];
        [[NSUserDefaults standardUserDefaults] setValue:sessionId forKey:@"sessionId"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSNumber *sessionStartedAt = [IntemptClient addTimestamp];
        [[NSUserDefaults standardUserDefaults] setValue:sessionStartedAt forKey:@"sessionStartedAt"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"session started with Id = %@ at %@", sessionId, [NSDate dateWithTimeIntervalSince1970:([sessionStartedAt doubleValue]/1000)]);
        
        // add start new session event
        NSMutableDictionary *newEventSession = [NSMutableDictionary dictionary];
        [newEventSession setValue:sessionId forKey:@"sessionId"];
        [newEventSession setValue:sessionStartedAt forKey:@"session_start"];
        [newEventSession setValue:[NSNumber numberWithDouble:0] forKey:@"session_end"];
        [newEventSession setValue:[NSNumber numberWithDouble:0] forKey:@"duration"];
        [self addEvent:newEventSession toEventCollection:@"session" withCompletion:nil];
        
    }else{
        sessionId = [self generateUUIDNoDashes];
        [[NSUserDefaults standardUserDefaults] setValue:sessionId forKey:@"sessionId"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSNumber *sessionStartedAt = [IntemptClient addTimestamp];
        [[NSUserDefaults standardUserDefaults] setValue:sessionStartedAt forKey:@"sessionStartedAt"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"session started with Id = %@ at %@", sessionId, [NSDate dateWithTimeIntervalSince1970:([sessionStartedAt doubleValue]/1000)]);
        //first add profile event with new sessionId
        [self addEvent:[NSMutableDictionary dictionary] toEventCollection:@"profile" withCompletion:nil];
        
        //then add start session event
        NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
        [newEvent setValue:sessionId forKey:@"sessionId"];
        [newEvent setValue:sessionStartedAt forKey:@"session_start"];
        [newEvent setValue:[NSNumber numberWithDouble:0] forKey:@"session_end"];
        [newEvent setValue:[NSNumber numberWithDouble:0] forKey:@"duration"];
        [self addEvent:newEvent toEventCollection:@"session" withCompletion:nil];
    }
    
}
- (void)endTrackingSession{
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"sessionId"]) {
        NSString *previousSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"sessionId"];
        NSNumber *sessionWasStartedAt = [[NSUserDefaults standardUserDefaults] valueForKey:@"sessionStartedAt"];
        NSNumber *nowTime = [IntemptClient addTimestamp];
        NSNumber *diffTime =  [NSNumber numberWithDouble:[nowTime doubleValue] - [sessionWasStartedAt doubleValue]];
         
        NSLog(@"session ending with Id = %@ of duration = %f", previousSessionId, [diffTime doubleValue]);
        
        NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
        [newEvent setValue:previousSessionId forKey:@"sessionId"];
        [newEvent setValue:sessionWasStartedAt forKey:@"session_start"];
        [newEvent setValue:nowTime forKey:@"session_end"];
        [newEvent setValue:diffTime forKey:@"duration"];
        [self addEvent:newEvent toEventCollection:@"session" withCompletion:nil];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"sessionId"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        sessionId = @"";
    }
}

- (void)startTrackingSession{
    
    sessionId = [self generateUUIDNoDashes];
    [[NSUserDefaults standardUserDefaults] setValue:sessionId forKey:@"sessionId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSNumber *sessionStartedAt = [IntemptClient addTimestamp];
    [[NSUserDefaults standardUserDefaults] setValue:sessionStartedAt forKey:@"sessionStartedAt"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"session started with Id = %@ at %@", sessionId, [NSDate dateWithTimeIntervalSince1970:([sessionStartedAt doubleValue]/1000)]);
    //first add profile event with new sessionId
    [self addEvent:[NSMutableDictionary dictionary] toEventCollection:@"profile" withCompletion:nil];
    
    //then add start session event
    NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
    [newEvent setValue:sessionId forKey:@"sessionId"];
    [newEvent setValue:sessionStartedAt forKey:@"session_start"];
    [newEvent setValue:[NSNumber numberWithDouble:0] forKey:@"session_end"];
    [newEvent setValue:[NSNumber numberWithDouble:0] forKey:@"duration"];
    [self addEvent:newEvent toEventCollection:@"session" withCompletion:nil];
}

+ (void)initialize {
    // initialize the cached client exactly once.

    if (self != [IntemptClient class]) {
        /*
         Without this extra check, your initializations could run twice if you ever have a subclass that
         doesn't implement its own +initialize method. This is not just a theoretical concern, even if
         you don't write any subclasses. Apple's Key-Value Observing creates dynamic subclasses which
         don't override +initialize.
         */
        
        return;
    }
    
    //[IntemptClient enableLogging];
    //[IntemptClient enableGeoLocation];
}

+ (void)disableTracking {
    
    NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
    [newEvent setValue:@"App" forKey:@"regulation"];
    [newEvent setValue:@"Tracking disabled" forKey:@"purpose"];
    [newEvent setValue:[NSNumber numberWithBool:NO] forKey:@"consented"];
    NSMutableArray *consentArray = [[NSMutableArray alloc]init];
    [consentArray addObject:newEvent];
    NSMutableDictionary *dictEvent = [NSMutableDictionary dictionary];
    [dictEvent setValue:consentArray forKey:@"consents"];
    [[IntemptClient sharedClient] addEvent:dictEvent toEventCollection:@"consents" withCompletion:nil];
    
    trackingEnabled = NO;
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setValue:@"NO" forKey:@"Intempt_Tracking_Flag"];
    [userDefault synchronize];
}

+ (void)enableTracking {
    trackingEnabled = YES;
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setValue:@"YES" forKey:@"Intempt_Tracking_Flag"];
    [userDefault synchronize];
    
    NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
    [newEvent setValue:@"App" forKey:@"regulation"];
    [newEvent setValue:@"Tracking enabled" forKey:@"purpose"];
    [newEvent setValue:[NSNumber numberWithBool:YES] forKey:@"consented"];
    NSMutableArray *consentArray = [[NSMutableArray alloc]init];
    [consentArray addObject:newEvent];
    NSMutableDictionary *dictEvent = [NSMutableDictionary dictionary];
    [dictEvent setValue:consentArray forKey:@"consents"];
    [[IntemptClient sharedClient] addEvent:dictEvent toEventCollection:@"consents" withCompletion:nil];
}

+ (Boolean)isTrackingEnabled {
    return trackingEnabled;
}

+ (void)disableLogging {
    loggingEnabled = NO;
}

+ (void)enableLogging {
    loggingEnabled = YES;
}

+ (Boolean)isLoggingEnabled {
    return loggingEnabled;
}

+ (void)authorizeGeoLocationAlways {
    authorizedGeoLocationAlways = YES;
}

+ (void)authorizeGeoLocationWhenInUse {
    authorizedGeoLocationWhenInUse = YES;
}

+ (void)enableGeoLocation {
    geoLocationEnabled = YES;
}

+ (void)disableGeoLocation {
    geoLocationEnabled = NO;
}

+ (BOOL)validateOrganizationId:(NSString *)orgId {
    // validate that organization ID is acceptable
    if (!orgId || [orgId length] == 0) {
        return NO;
    }
    return YES;
}

+ (BOOL)validateTrackerId:(NSString *)key {
    // for now just use the same rules as organization ID
    return [IntemptClient validateOrganizationId:key];
}

+ (BOOL)validateToken:(NSString *)key {
    // for now just use the same rules as organization ID
    return [IntemptClient validateOrganizationId:key];
}

- (id)initWithOrganizationId:(NSString *)organizationId withTrackerId:(NSString *)trackerId withToken:(NSString *)token withConfig:(id)settings withCompletion:(CompletionHandler)handler {
    
    return [self initWithOrganizationId:organizationId withTrackerId:trackerId withToken:token withConfig:settings withPropertiesOverrides:nil withPropertiesOverridesBlock:nil withCompletion:handler];
}

- (id)initWithOrganizationId:(NSString *)organizationId withTrackerId:(NSString *)sourceId withToken:(NSString *)token withConfig:(id)settings withPropertiesOverrides:(NSDictionary *)propertiesOverrides withPropertiesOverridesBlock:(NSDictionary *(^)(NSString *))propertiesOverridesBlock withCompletion:(CompletionHandler)handler {
    if (![IntemptClient validateOrganizationId:organizationId]) {
        return nil;
    }
    
    self = [self init];
    if (self) {
        self.organizationId = organizationId;
        
        if (sourceId) {
            if (![IntemptClient validateOrganizationId:sourceId]) {
                return nil;
            }
            self.sourceId = sourceId;
        }
        if (token) {
            if (![IntemptClient validateTrackerId:token]) {
                return nil;
            }
            self.token = token;
        }
    }
    self.propertiesOverridesDictionary = propertiesOverrides;
    if ([settings isKindOfClass:[IntemptConfig class]]) {
        self.config = (IntemptConfig*)settings;
    }
    else if (self.config != nil) {
    }
    else {
        self.config = [[IntemptConfig alloc] init];
    }
    [self disableTextInput:self.config.isInputTextCaptureDisabled];
    if (self.config.itemsInQueue <= 0) {
        self.config.itemsInQueue = kItemsInQueue;
        TBLog(@"You can't set `itemsInQueue` value to 0 or negative. Resetting value to 5.");
    }
    else if (self.config.itemsInQueue > 30) {
        self.config.itemsInQueue = kItemsInQueue;
        TBLog(@"For performance issue, you can't set `itemsInQueue` value greater than 30. Resetting value to 5.");
    }
    
    self.completion = handler;
    
    //Send data to server periodically
    [self startTimer];
    
    return self;
}

- (void)disableTextInput:(BOOL)status {
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
}

# pragma mark - Get a shared client

+ (IntemptClient *)sharedClient {
    if (!sharedClient) {
        sharedClient = [[IntemptClient alloc] init];
    }
    //TBLog(@"sharedClient============================%@", sharedClient);
    return sharedClient;
}

+ (IntemptClient *)sharedClientWithOrganizationId:(NSString *)organizationId withTrackerId:(NSString *)trackerId withToken:(NSString *)token withConfig:(id)settings withCompletion:(CompletionHandler)handler {
    
    return [IntemptClient sharedClientWithOrganizationId:organizationId withTrackerId:trackerId withToken:token withConfig:settings withPropertiesOverrides:nil withPropertiesOverridesBlock:nil withCompletion:handler];
}

+ (IntemptClient *)sharedClientWithOrganizationId:(NSString *)organizationId withTrackerId:(NSString *)sourceId withToken:(NSString *)token withConfig:(id)settings withPropertiesOverrides:(NSDictionary *)propertiesOverrides withPropertiesOverridesBlock:(NSDictionary *(^)(NSString *))propertiesOverridesBlock withCompletion:(CompletionHandler)handler {
    if (![IntemptClient validateOrganizationId:organizationId] || (![IntemptClient validateTrackerId:sourceId])) {
        return nil;
    }
    else {
        sharedClient =  [IntemptClient sharedClient]; //[[IntemptClient alloc] init];
        //TBLog(@"sharedClientWithOrganizationId============================%@", sharedClient);
        sharedClient.organizationId = organizationId;
        
        sharedClient.sourceId = sourceId;
        
        if (token) {
            // only validate a non-nil value
            if (![IntemptClient validateToken:token]) {
                return nil;
            }
        }
        sharedClient.token = token;
        if ([settings isKindOfClass:[IntemptConfig class]]) {
            sharedClient.config = (IntemptConfig*)settings;
        }
        else if (sharedClient.config != nil) {
        }
        else {
            sharedClient.config = [[IntemptConfig alloc] init];
        }
        
        [sharedClient disableTextInput:sharedClient.config.isInputTextCaptureDisabled];
        if (sharedClient.config.itemsInQueue <= 0) {
            sharedClient.config.itemsInQueue = kItemsInQueue;
            TBLog(@"You can't set `itemsInQueue` value to 0 or negative. Resetting value to 5.");
        }
        else if (sharedClient.config.itemsInQueue > 30) {
            sharedClient.config.itemsInQueue = kItemsInQueue;
            
            TBLog(@"Due to performance issue, you can't set `itemsInQueue` value greater than 30. Resetting value to 5.");
            
        }
        
        sharedClient.propertiesOverridesDictionary = propertiesOverrides;
        sharedClient.completion = handler;
        
        //Send data to server periodically
        [sharedClient startTimer];
    }
    
    return sharedClient;
}

# pragma mark - Geo stuff

- (void)refreshCurrentLocation {
    // only do this if geo is enabled
    TBLog(@"refreshCurrentLocation");
    geocoder = [[CLGeocoder alloc] init];
    if (_locationManager == nil){
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.delegate = self;
    
    }
    /** Intempt SDK should get location only if app user has granted permission,
     Intempt itself will not ask for location permission
     */
    BOOL statusLocationPermission = [CLLocationManager locationServicesEnabled];
    CLAuthorizationStatus auth = [CLLocationManager authorizationStatus];
    if(statusLocationPermission == NO || auth == kCLAuthorizationStatusNotDetermined || auth == kCLAuthorizationStatusRestricted || auth == kCLAuthorizationStatusDenied){
        TBLog(@"CLLocationManager.locationServicesEnabled=%d",statusLocationPermission);
        TBLog(@"CLLocationManager.authorizationStatus=%d",auth);
        NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
        TBLog(@"notAllow");
        BOOL wasAdded = [[IntemptClient sharedClient] addEvent:newEvent toEventCollection:@"notAllow" withCompletion:_completion];
        if (!wasAdded ){
            TBLog(@"Failed to add event to \"view\" collection.");
        }
    }else{
        if(auth == kCLAuthorizationStatusAuthorizedAlways){
            TBLog(@"requestAlwaysAuthorization");
            [_locationManager requestAlwaysAuthorization];
        }else{
            TBLog(@"requestWhenInUseAuthorization");
            [_locationManager requestWhenInUseAuthorization];
        }
    }
    
}

// Delegate method from the CLLocationManagerDelegate protocol.

#pragma mark - CLLocationManager delegate methods

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        /// The user denied authorization
        NSLog(@"The user denied location authorization");
        if(arrLaunch.count == 0) {
            NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
            //BOOL wasAdded = [[IntemptClient sharedClient] addEvent:newEvent toEventCollection:@"notAllow" withCompletion:NULL];
            BOOL wasAdded = [[IntemptClient sharedClient] addEvent:newEvent toEventCollection:@"notAllow" withCompletion:_completion];
            if (!wasAdded ) {
                TBLog(@"Failed to add event to \"view\" collection.");
            }
        }

        NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
        [newEvent setValue:@"Location" forKey:@"regulation"];
        [newEvent setValue:@"The user denied location authorization" forKey:@"purpose"];
        [newEvent setValue:[NSNumber numberWithBool:NO] forKey:@"consented"];
        NSMutableArray *consentArray = [[NSMutableArray alloc]init];
        [consentArray addObject:newEvent];
        NSMutableDictionary *dictEvent = [NSMutableDictionary dictionary];
        [dictEvent setValue:consentArray forKey:@"consents"];
        [[IntemptClient sharedClient] addEvent:dictEvent toEventCollection:@"consents" withCompletion:nil];
    }
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // The user accepted authorization only when in use
        if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]){
            [_locationManager requestWhenInUseAuthorization];
        }
        
        [_locationManager startUpdatingLocation];
        
        NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
        [newEvent setValue:@"Location" forKey:@"regulation"];
        [newEvent setValue:@"The user granted location authorization as WhenInUseAuthorization" forKey:@"purpose"];
        [newEvent setValue:[NSNumber numberWithBool:YES] forKey:@"consented"];
        NSMutableArray *consentArray = [[NSMutableArray alloc]init];
        [consentArray addObject:newEvent];
        NSMutableDictionary *dictEvent = [NSMutableDictionary dictionary];
        [dictEvent setValue:consentArray forKey:@"consents"];
        [[IntemptClient sharedClient] addEvent:dictEvent toEventCollection:@"consents" withCompletion:nil];
    }
    else if (status == kCLAuthorizationStatusAuthorizedAlways) {
        // The user accepted authorization at any time
        [_locationManager startUpdatingLocation];
        
        NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
        [newEvent setValue:@"Location" forKey:@"regulation"];
        [newEvent setValue:@"The user granted location authorization as AlwaysAuthorization" forKey:@"purpose"];
        [newEvent setValue:[NSNumber numberWithBool:YES] forKey:@"consented"];
        NSMutableArray *consentArray = [[NSMutableArray alloc]init];
        [consentArray addObject:newEvent];
        NSMutableDictionary *dictEvent = [NSMutableDictionary dictionary];
        [dictEvent setValue:consentArray forKey:@"consents"];
        [[IntemptClient sharedClient] addEvent:dictEvent toEventCollection:@"consents" withCompletion:nil];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    //TBLog(@"didUpdateLocations");
    CLLocation *newLocation = [locations lastObject];
    NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
    if (![IntemptClient validateOrganizationId:sharedClient.organizationId]) {
        return;
    }
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        TBLog(@"Placemark:%@",placemarks);
        if (error == nil && [placemarks count] > 0) {
            self->placemark = [placemarks lastObject];
            self->region = self->placemark.thoroughfare;
            self->country = self->placemark.country;
            self->city = self->placemark.locality;
            
            if(self->arrLaunch.count == 0) {
                //BOOL wasAdded = [[IntemptClient sharedClient] addEvent:newEvent toEventCollection:@"geoLocation" withCompletion:NULL];
                BOOL wasAdded = [[IntemptClient sharedClient] addEvent:newEvent toEventCollection:@"geoLocation" withCompletion:self->_completion];
                if (!wasAdded || error) {
                    TBLog(@"Failed to add event to \"view\" collection");
                }
            }
        } else {
            TBLog(@"Failed to retrive address via reverseGeocodeLocation: %@", [error localizedDescription]);
        }
    } ];
    
    // Turn off the location manager to save power.
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    //TBLog(@"didFailWithLocations");
    if(arrLaunch.count == 0) {
        NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
        //BOOL wasAdded = [[IntemptClient sharedClient] addEvent:newEvent toEventCollection:@"notAllow" withCompletion:NULL];
        BOOL wasAdded = [[IntemptClient sharedClient] addEvent:newEvent toEventCollection:@"notAllow" withCompletion:_completion];
        if (!wasAdded || error) {
            TBLog(@"Failed to add event to \"view\" collection with error: %@", error);
        }
    }
    TBLog(@"Cannot find the location.");
}


# pragma mark - Identify

- (void)identify:(NSString*)identity withProperties:(NSDictionary *)userProperties withCompletion:(CompletionHandler)handler {
    
    if(identity != nil || [identity stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0){
        if ([self isValidEmail:identity] || [self isValidPhoneNumber:identity]){
            NSMutableDictionary *event = [[NSMutableDictionary alloc] initWithDictionary:userProperties];
            [event setObject:identity forKey:@"identifier"];
            
            
            [[NSUserDefaults standardUserDefaults] setValue:identity forKey:@"identifier"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            BOOL wasAdded = [self addEvent:event toEventCollection:@"identify" withCompletion:handler];
            if (!wasAdded) {
                TBLog(@"Failed to add event for %@", identity);
                NSError *error = [NSError errorWithDomain:@"Failed to add event for" code:200 userInfo:nil];
                if (handler != NULL){
                    handler(NO, nil, error);
                }
            }else{
                if (handler != NULL){
                    handler(YES, nil, nil);
                }
            }
        }
        else{
            TBLog(@"Please provide a valid identity(email, phone)");
            if (handler != NULL){
                NSError *error = [NSError errorWithDomain:@"Please provide a valid identity(email, phone)" code:200 userInfo:nil];
                handler(NO, nil, error);
            }
        }
    }
    else {
        TBLog(@"Identity field can't be empty");
        if (handler != NULL){
            NSError *error = [NSError errorWithDomain:@"Identity field can't be empty" code:200 userInfo:nil];
            handler(NO, nil, error);
        }
    }
}

# pragma mark - Track

- (void)track:(NSString*)collectionName withProperties:(NSArray *)userProperties withCompletion:(CompletionHandler)handler {
    
    //// in case developer end session and have not started new session then in order to log events we need to start need session
    if([sessionId isEqualToString:@""]){
        [self startTrackingSession];
    }
    NSMutableArray *aryData = [[NSMutableArray alloc] initWithArray:userProperties];
    [userProperties setValue:sessionId forKey:@"sessionId"];
    eventId = [self generateUUIDNoDashes];
    [userProperties setValue:eventId forKey:@"eventId"];
    [userProperties setValue:[self addTimestamp] forKey:@"timestamp"];
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    [event setValue:aryData forKey:collectionName];
    
    BOOL wasAdded = [self addEvent:event toEventCollection:@"customEvent" withCompletion:handler];
    if (!wasAdded) {
        TBLog(@"Failed to add event for %@", event);
    }
}

# pragma mark - Add events

- (BOOL)addEvent:(NSDictionary *)event toEventCollection:(NSString *)eventCollection withCompletion:(CompletionHandler)handler {
    
    // make sure the tracker ID has been set - can't do anything without that
    if (![IntemptClient validateTrackerId:self.sourceId]) {
        
        //[NSException raise:@"IntemptNoTrackerIdProvided" format:@"You tried to add an event without setting a source Id please set one!"];
        TBLog(@"You tried to add an event without setting tracker source Id please set one!");
        if (handler != NULL){
            NSError *error = [NSError errorWithDomain:@"You tried to add an event without setting tracker source Id please set one!" code:1001 userInfo:nil];
            handler(NO, nil, error);
        }
        return NO;
    }
    
    if (![IntemptClient validateToken:self.token]) {
        
        //[NSException raise:@"IntemptNoTokenProvided" format:@"You tried to add an event without setting a token, please set one!"];
        TBLog(@"You tried to add an event without setting tracker token, please set one!");
        if (handler != NULL){
            NSError *error = [NSError errorWithDomain:@"You tried to add an event without setting tracker token, please set one!" code:1001 userInfo:nil];
            handler(NO, nil, error);
        }
        return NO;
    }
    
    //// in case developer end session and have not started new session then in order to log events we need to start need session
    if([sessionId isEqualToString:@""]){
        [self startTrackingSession];
    }
    
    NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
    [newEvent setValue:[self addTimestamp] forKey:@"timestamp"];
    //[self addTimestamp: newEvent];
    [self addPlatform: newEvent];
    [self addParent: newEvent];
    [self bundleInfo:newEvent];
    
    
    /*if(launchDic == nil)
     launchDic = [[NSMutableDictionary alloc] init];
     if(screenDic == nil)
     screenDic = [[NSMutableDictionary alloc] init];
     if(deviceDic == nil)
     deviceDic = [[NSMutableDictionary alloc] init];
     if(geoDic == nil)
     geoDic = [[NSMutableDictionary alloc] init];
     if(appDic == nil)
     appDic = [[NSMutableDictionary alloc] init];*/
    
    if ([eventCollection isEqualToString:@"profile"]) {
        
        arrProfile = [[NSMutableArray alloc] init];
        dictValue = [[NSMutableDictionary alloc] init];
        profileDic = [[NSMutableDictionary alloc] init];
        eventId = [self generateUUIDNoDashes];
    
        [self->profileDic setValue:self->sessionId forKey:@"sessionId"];
        
        NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
        NSString *strIdentifier = [df valueForKey:@"identifier"];
        if (strIdentifier == nil){
            [self->profileDic setValue:self->visitorId forKey:@"identifier"];
        }else{
            [self->profileDic setValue:strIdentifier forKey:@"identifier"];
        }
        [self->arrProfile addObject:self->profileDic];
        self->dictValue = [[NSMutableDictionary alloc] init];
        [self->dictValue setValue:self->arrProfile forKey:@"profile"];
        TBLog(@"Profile Data:---%@",self->dictValue);
        if(![self connected]) {
            // Not connected
            TBLog(@"Please Check Your Internet Connection");
        }else {
            [[DBManager shared] insertAnalayticsData:self->dictValue withEventType:@"profile"];
        }
        
    }else if ([eventCollection isEqualToString:@"session"]) {
    
        NSMutableDictionary *dictValueLocal = [[NSMutableDictionary alloc]init];
        NSMutableArray *arrLaunchLocal = [[NSMutableArray alloc] init];
        NSMutableDictionary *launchDicLocal = [[NSMutableDictionary alloc] initWithDictionary:event];
        [launchDicLocal setValue:[self generateUUIDNoDashes] forKey:@"eventId"];
        [launchDicLocal setValue:[newEvent valueForKey:@"timestamp"] forKey:@"timestamp"];
        [arrLaunchLocal addObject:launchDicLocal];
        [dictValueLocal setValue:arrLaunchLocal forKey:@"session"];
        TBLog(@"session Data: %@",dictValueLocal);
        [[DBManager shared] insertAnalayticsData:dictValueLocal withEventType:@"session"];
        
    }else if ([[event objectForKey:@"type"] isEqualToString:@"touch"] || [[event objectForKey:@"type"] isEqualToString:@"change"] || [[event objectForKey:@"type"] isEqualToString:@"action"]) {
        
        arrProfile = [[NSMutableArray alloc] init];
        arrLaunch = [[NSMutableArray alloc] init];
        arrScreen = [[NSMutableArray alloc] init];
        dictValue = [[NSMutableDictionary alloc] init];
        profileDic = [[NSMutableDictionary alloc] init];
        sceneDic = [[NSMutableDictionary alloc] init];
        interactionDic = [[NSMutableDictionary alloc] init];
        
        //NSString *timestamp = [newEvent valueForKey:@"timestamp"];
        [interactionDic setValue:sessionId forKey:@"sessionId"];
        [interactionDic setValue:[newEvent valueForKey:@"timestamp"] forKey:@"timestamp"];
        [interactionDic setValue:parentId forKey:@"parentId"];
        
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        //visitorId = [df valueForKey:@"visitorId"];
        parentId = [df valueForKey:@"parentId"];
        
        eventId = [self generateUUIDNoDashes];
        [interactionDic setValue:eventId forKey:@"eventId"];
        //[interactionDic setValue:[event objectForKey:@"type"] forKey:@"type"];
        [interactionDic addEntriesFromDictionary:event];
        //[arrInteraction addObject:interactionDic];
        
        ////Sometimes if scene event is not logged first then parentId is nill and such event gives error in db
        ///It happens when rootviewcontroller is set on window and quickly pressed on some action
        if (parentId != nil){
            [[DBManager shared] insertAnalayticsData:interactionDic withEventType:@"interaction"];
            //[dictValue setValue:arrInteraction forKey:@"interaction"];
            TBLog(@"addEvent Event Data (Touch, Change, Action): %@",interactionDic);
        }else{
            TBLog(@"parentId is nill, can't log event=%@",parentId);
        }
        
    }
    
    else if ([eventCollection isEqualToString:@"identify"]) {
        
        ///first end session and create new session then log event so that new indentity should be saved with new session
        [self validateTrackingSession];
        [profileDic setValue:self->sessionId forKey:@"sessionId"];
        [profileDic setValue:[newEvent valueForKey:@"timestamp"] forKey:@"timestamp"];
        [profileDic setValue:[event objectForKey:@"identifier"] forKey:@"identifier"];
        //[arrProfile addObject:profileDic];
        dictValue = [[NSMutableDictionary alloc] init];
        [dictValue setValue:[NSArray arrayWithObject:profileDic] forKey:@"profile"];
        TBLog(@"Identify Data: %@",dictValue);
        
        [[DBManager shared] insertAnalayticsData:dictValue withEventType:@"profile"];
        //[self sendEvents:dictValue multipleRecordExits:NO withCompletion:handler];
    }
    else if ([eventCollection isEqualToString:@"consents"]) {
        
        NSMutableDictionary *dictValueLocal = [[NSMutableDictionary alloc]init];
        NSMutableArray *arrLaunchLocal = [[NSMutableArray alloc] init];
        NSMutableDictionary *launchDicLocal = [[NSMutableDictionary alloc] initWithDictionary:event];
        
        [launchDicLocal setValue:[self generateUUIDNoDashes] forKey:@"eventId"];
        [launchDicLocal setValue:self->sessionId forKey:@"sessionId"];
        [launchDicLocal setValue:[newEvent valueForKey:@"timestamp"] forKey:@"timestamp"];
        [launchDicLocal setValue:[newEvent valueForKey:@"timestamp"] forKey:@"timestamp_unixtime_ms"];
        [launchDicLocal setValue:@"" forKey:@"document"];
        [launchDicLocal setValue:[[[UIDevice currentDevice]identifierForVendor]UUIDString] forKey:@"hardware_id"];
        if(self->city.length > 1){
            [launchDicLocal setValue:self->city forKey:@"location"];
        }else if(self->country.length > 1){
            [launchDicLocal setValue:self->country forKey:@"location"];
        }else{
            [launchDicLocal setValue:@"" forKey:@"location"];
        }
        [arrLaunchLocal addObject:launchDicLocal];
        [dictValueLocal setValue:arrLaunchLocal forKey:@"consents"];
        TBLog(@"consent Data: %@",dictValueLocal);
        [[DBManager shared] insertAnalayticsData:dictValueLocal withEventType:@"consents"];
        
        
        //[self sendEvents:dictValue multipleRecordExits:NO withCompletion:handler];
    }
    else if ([eventCollection isEqualToString:@"customEvent"]) {
        dictValue = [[NSMutableDictionary alloc] initWithDictionary:event];
        TBLog(@"Custom Event Data: %@",dictValue);
        
        [[DBManager shared] insertAnalayticsData:dictValue withEventType:@"customEvent"];
        //[self sendEvents:dictValue multipleRecordExits:NO withCompletion:handler];
    }
    
    else if ([eventCollection isEqualToString:@"geoLocation"]) {
        
        [self checkAppUpgradeStatus:newEvent];
        self->dictValue = [[NSMutableDictionary alloc]initWithDictionary:event];
        [newEvent setValue:self->region forKey:@"region"];
        [newEvent setValue:self->country forKey:@"country"];
        [newEvent setValue:self->city forKey:@"city"];
        NSString *ipAddress = [self getipAddress];
        if (launchDic == nil) {
            launchDic = [[NSMutableDictionary alloc] init];
        }
        NSMutableDictionary *dictValueLocal =[[NSMutableDictionary alloc]initWithDictionary:event];
        NSMutableDictionary *launchDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *deviceDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *screenDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *geoDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *appDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableArray *arrLaunchLocal = [[NSMutableArray alloc] init];
        
        self->eventId = [self generateUUIDNoDashes];
        //this eventId will be used as fk for scene
        NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
        [df setValue:self->eventId forKey:@"parentId"];
        [df synchronize];

        [launchDicLocal setValue:self->sessionId forKey:@"sessionId"];
        [launchDicLocal setValue:self->eventId forKey:@"eventId"];
        [launchDicLocal setValue:[newEvent valueForKey:@"timestamp"] forKey:@"timestamp"];
        [launchDicLocal setValue:[newEvent valueForKey:@"wifi"] forKey:@"wifi"];
        
        [deviceDicLocal setValue:self->brand forKey:@"brand"];
        [deviceDicLocal setValue:[newEvent valueForKey:@"name"] forKey:@"name"];
        [deviceDicLocal setValue:[newEvent valueForKey:@"type"] forKey:@"type"];
        [deviceDicLocal setValue:[newEvent valueForKey:@"osVersion"] forKey:@"osVersion"];
        [deviceDicLocal setValue:ipAddress forKey:@"ipAddress"];
        
        [screenDicLocal setValue:[newEvent valueForKey:@"height"] forKey:@"height"];
        [screenDicLocal setValue:[newEvent valueForKey:@"width"] forKey:@"width"];
        
        if([newEvent valueForKey:@"region"]){
            [geoDicLocal setValue:[newEvent valueForKey:@"region"] forKey:@"region"];
        }else{
            [geoDicLocal setValue:@"" forKey:@"region"];
        }
        if([newEvent valueForKey:@"country"]){
            [geoDicLocal setValue:[newEvent valueForKey:@"country"] forKey:@"country"];
        }else{
            [geoDicLocal setValue:@"" forKey:@"country"];
        }
        if([newEvent valueForKey:@"city"]){
            [geoDicLocal setValue:[newEvent valueForKey:@"city"] forKey:@"city"];
        }else{
            [geoDicLocal setValue:@"" forKey:@"city"];
        }
    
        [appDicLocal setValue:[newEvent valueForKey:@"appName"] forKey:@"name"];
        [appDicLocal setValue:[newEvent valueForKey:@"version"] forKey:@"version"];
        [appDicLocal setValue:[newEvent valueForKey:@"AppUpgrade"] forKey:@"appUpgrade"];
        
        [self->launchDic setValue:deviceDicLocal forKey:@"device"];
        [self->launchDic setValue:screenDicLocal forKey:@"screen"];
        [self->launchDic setValue:geoDicLocal forKey:@"geo"];
        [self->launchDic setValue:appDicLocal forKey:@"app"];
        [self->arrLaunch addObject:self->launchDic];
        [self->dictValue setValue:self->arrLaunch forKey:@"launch"];
        
        [launchDicLocal setValue:deviceDicLocal forKey:@"device"];
        [launchDicLocal setValue:screenDicLocal forKey:@"screen"];
        [launchDicLocal setValue:geoDicLocal forKey:@"geo"];
        [launchDicLocal setValue:appDicLocal forKey:@"app"];
        [arrLaunchLocal addObject:launchDicLocal];
        [dictValueLocal setValue:arrLaunchLocal forKey:@"launch"];
        
        NSLog(@"Launch Data:---%@",arrLaunchLocal);
        
        if (![self connected]) {
            // Not connected
            TBLog(@"Please Check Your Internet Connection");
        }
        else {
            [[DBManager shared] insertAnalayticsData:dictValueLocal withEventType:@"launch"];
            //[self sendEvents:self->dictValue multipleRecordExits:NO withCompletion:handler];
        }
    }
    
    else if ([eventCollection isEqualToString:@"notAllow"]) {
        [self checkAppUpgradeStatus:newEvent];

        self->dictValue = [[NSMutableDictionary alloc] initWithDictionary:event];
        [newEvent setValue:self->region forKey:@"region"];
        [newEvent setValue:self->country forKey:@"country"];
        [newEvent setValue:self->city forKey:@"city"];
        NSString *ipAddress = [self getipAddress];
        if (launchDic == nil) {
            launchDic = [[NSMutableDictionary alloc] init];
        }
        NSMutableDictionary *dictValueLocal =[[NSMutableDictionary alloc]initWithDictionary:event];
        NSMutableDictionary *launchDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *deviceDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *screenDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *geoDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *appDicLocal = [[NSMutableDictionary alloc] init];
        NSMutableArray *arrLaunchLocal = [[NSMutableArray alloc] init];
        
        self->eventId = [self generateUUIDNoDashes];
        //this eventId will be used as fk for scene
        NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
        [df setValue:self->eventId forKey:@"parentId"];
        [df synchronize];
        
        [launchDicLocal setValue:self->sessionId forKey:@"sessionId"];
        [launchDicLocal setValue:self->eventId forKey:@"eventId"];
        [launchDicLocal setValue:[newEvent valueForKey:@"timestamp"] forKey:@"timestamp"];
        [launchDicLocal setValue:[newEvent valueForKey:@"wifi"] forKey:@"wifi"];
        
        [deviceDicLocal setValue:self->brand forKey:@"brand"];
        [deviceDicLocal setValue:[newEvent valueForKey:@"name"] forKey:@"name"];
        [deviceDicLocal setValue:[newEvent valueForKey:@"type"] forKey:@"type"];
        [deviceDicLocal setValue:[newEvent valueForKey:@"osVersion"] forKey:@"osVersion"];
        [deviceDicLocal setValue:ipAddress forKey:@"ipAddress"];
        
        [screenDicLocal setValue:[newEvent valueForKey:@"height"] forKey:@"height"];
        [screenDicLocal setValue:[newEvent valueForKey:@"width"] forKey:@"width"];
        
        if([newEvent valueForKey:@"region"]){
            [geoDicLocal setValue:[newEvent valueForKey:@"region"] forKey:@"region"];
        }else{
            [geoDicLocal setValue:@"" forKey:@"region"];
        }
        if([newEvent valueForKey:@"country"]){
            [geoDicLocal setValue:[newEvent valueForKey:@"country"] forKey:@"country"];
        }else{
            [geoDicLocal setValue:@"" forKey:@"country"];
        }
        if([newEvent valueForKey:@"city"]){
            [geoDicLocal setValue:[newEvent valueForKey:@"city"] forKey:@"city"];
        }else{
            [geoDicLocal setValue:@"" forKey:@"city"];
        }
        
        [appDicLocal setValue:[newEvent valueForKey:@"appName"] forKey:@"name"];
        [appDicLocal setValue:[newEvent valueForKey:@"version"] forKey:@"version"];
        [appDicLocal setValue:[newEvent valueForKey:@"AppUpgrade"] forKey:@"appUpgrade"];
        
        [self->launchDic setValue:deviceDicLocal forKey:@"device"];
        [self->launchDic setValue:screenDicLocal forKey:@"screen"];
        [self->launchDic setValue:geoDicLocal forKey:@"geo"];
        [self->launchDic setValue:appDicLocal forKey:@"app"];
        
        [launchDicLocal setValue:deviceDicLocal forKey:@"device"];
        [launchDicLocal setValue:screenDicLocal forKey:@"screen"];
        [launchDicLocal setValue:geoDicLocal forKey:@"geo"];
        [launchDicLocal setValue:appDicLocal forKey:@"app"];
        [arrLaunchLocal addObject:launchDicLocal];
        [dictValueLocal setValue:arrLaunchLocal forKey:@"launch"];
        [self->arrLaunch addObject:launchDicLocal];
        [self->dictValue setValue:self->arrLaunch forKey:@"launch"];
        
        //TBLog(@"dictValueLocal=%@",dictValueLocal);
        NSLog(@"Launch Data (Location Access Not Provided):---%@",dictValueLocal);
        if (![self connected]) {
            // Not connected
            TBLog(@"Please Check Your Internet Connection");
        }
        else {
            [[DBManager shared] insertAnalayticsData:dictValueLocal withEventType:@"launch"];
            //[self sendEvents:self->dictValue multipleRecordExits:NO withCompletion:handler];
        }

    }
    else {
        NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
        screenDic = [[NSMutableDictionary alloc] init];
        deviceDic = [[NSMutableDictionary alloc] init];
        geoDic = [[NSMutableDictionary alloc] init];
        appDic = [[NSMutableDictionary alloc] init];
        launchDic = [[NSMutableDictionary alloc] init];
        
        arrProfile = [[NSMutableArray alloc] init];
        arrLaunch = [[NSMutableArray alloc] init];
        arrScreen = [[NSMutableArray alloc] init];
        dictValue = [[NSMutableDictionary alloc] init];
        profileDic = [[NSMutableDictionary alloc] init];
        sceneDic = [[NSMutableDictionary alloc] init];
        interactionDic = [[NSMutableDictionary alloc] init];
        eventId = [self generateUUIDNoDashes];
        
        NSString *lastParentId = [df valueForKey:@"parentId"];
        self->parentId = [df valueForKey:@"parentId"];
        [self->profileDic setValue:self->sessionId forKey:@"sessionId"];
        
        NSString *strIdentifier = [df valueForKey:@"identifier"];
        if (strIdentifier == nil) {
            [self->profileDic setValue:self->visitorId forKey:@"identifier"];
        }else{
            [self->profileDic setValue:strIdentifier forKey:@"identifier"];
        }
        //[self->profileDic setValue:nil forKey:@"identifier"];
        /*------*/
        
        [self->arrProfile addObject:self->profileDic];
        self->dictValue = [[NSMutableDictionary alloc] init];
        [self->dictValue setValue:self->arrProfile forKey:@"profile"];
        //NSString *timestamp = [newEvent valueForKey:@"timestamp"];
        [self->sceneDic addEntriesFromDictionary:event];
        [self->sceneDic setValue:self->eventId forKey:@"eventId"];
        [self->sceneDic setValue:[newEvent valueForKey:@"timestamp"] forKey:@"timestamp"];
        [self->sceneDic setValue:self->sessionId forKey:@"sessionId"];
        
        //eventId of scene will be used a fk for interaction events
        [df setValue:self->eventId forKey:@"parentId"];
        [df synchronize];
        /*------*/
        [self->sceneDic setValue:self->parentId forKey:@"parentId"];
        [self->arrScreen addObject:self->sceneDic];
        [self->dictValue setValue:self->arrScreen forKey:@"scene"];
        TBLog(@"Profile & Scene Data:---%@",self->dictValue);
        if (![self connected]) {
            // Not connected
            TBLog(@"Please Check Your Internet Connection");
        } else {
            if (lastParentId != nil){
                [[DBManager shared] insertAnalayticsData:self->dictValue withEventType:@"scene"];
            }else{
                TBLog(@"Scene event can't be logged because its parentId(Launch event not logged first");
            }
            //[self sendEvents:self->dictValue multipleRecordExits:NO withCompletion:handler];
        }
    }
    if (handler != NULL){
        handler(YES, [NSDictionary dictionaryWithObject:@"event logged successfully" forKey:@"info"], nil);
    }
    return YES;
}

# pragma mark - Helper methods

//Check Network Connection
- (BOOL)connected {
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

//Check Email Address
- (BOOL)isValidEmail:(NSString*)str {
    NSString *emailRegex = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:str];
}

//Check Phone Number
-(BOOL)isValidPhoneNumber:(NSString*)str {
    
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
    
    NSUInteger numberOfMatches = [detector numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])];
    
    if (numberOfMatches == 1)
        return YES;
    else
        return NO;
}

// Get the INTERNAL IP address
- (NSString *)getipAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (void)checkAppUpgradeStatus:(NSMutableDictionary *)event {
    
    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", cfBundleIdentifier]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if(data != nil) {
        NSDictionary *lookup = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if ([lookup[@"resultCount"] integerValue] == 1){
            NSString* appStoreVersion = lookup[@"results"][0][@"version"];
            NSString* currentVersion = infoDictionary[@"CFBundleShortVersionString"];
            if (![appStoreVersion isEqualToString:currentVersion]) {
                TBLog(@"Need to update [%@ != %@]", appStoreVersion, currentVersion);
                [event setValue:@"False" forKey:@"AppUpgrade"];
            }
            else {
                [event setValue:@"True" forKey:@"AppUpgrade"];
            }
        }
        else {
            [event setValue:@"True" forKey:@"AppUpgrade"];
        }
    }
}

- (void)bundleInfo:(NSMutableDictionary *) event {
    NSDictionary * bundleInfo = [[NSBundle mainBundle] infoDictionary];
    
    NSString *appName = [NSString stringWithFormat:@"%@",[bundleInfo objectForKey:@"CFBundleExecutable"]];
    cfBundleIdentifier = [NSString stringWithFormat:@"%@",[bundleInfo objectForKey:@"CFBundleIdentifier"]];
    NSString *CFBundleVersion = [NSString stringWithFormat:@"%@",[bundleInfo objectForKey:@"CFBundleVersion"]];
    NSString *DTPlatformName = [NSString stringWithFormat:@"%@",UIDevice.currentDevice.name];
    NSString *DTPlatformVersion = [NSString stringWithFormat:@"%@",[bundleInfo objectForKey:@"DTPlatformVersion"]];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    [event setValue:appName forKey:@"appName"];
    [event setValue:CFBundleVersion forKey:@"version"];
    [event setValue:DTPlatformName forKey:@"name"];
    [event setValue:DTPlatformVersion forKey:@"osVersion"];
    [event setValue:[NSNumber numberWithInt:height] forKey:@"height"];
    [event setValue:[NSNumber numberWithInt:width] forKey:@"width"];
    
    BOOL isConnectedProperly = ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWiFi);
    if (isConnectedProperly == YES) {
        [event setValue:[NSNumber numberWithBool:true] forKey:@"wifi"];
    }
    else{
        [event setValue:[NSNumber numberWithBool:false] forKey:@"wifi"];
    }
}


NSString *parent = nil;
NSNumber *parentTimestamp = nil;

- (void)addParent:(NSMutableDictionary *) event {
    if(parent) {
        [event setValue:parentTimestamp forKey:@"timestamp"];
    }
}

- (void)addPlatform:(NSMutableDictionary *) event {
    [event setValue:kPlatform forKey:@"type"];
}

- (NSString *)generateUUIDNoDashes {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    NSString *uuidNoDashes = [uuidString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    return [uuidNoDashes lowercaseString];
}

- (NSNumber*)addTimestamp {
    long long timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    return [NSNumber numberWithLongLong:timestamp];
}

+ (NSNumber*)addTimestamp {
    long long timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    return [NSNumber numberWithLongLong:timestamp];
}

# pragma mark - Retry and Exponential Backoff

- (void)requestUrlWithRetryRemaining:(NSInteger)retryRemaining maxRetry:(NSInteger)maxRetry retryInterval:(NSTimeInterval)retryInterval fatalStatusCodes:(NSArray<NSNumber *> *)fatalStatusCodes originalRequest:(NSURLRequest *)request eventIds:(NSArray*)arrEventIds {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    __block __weak NSURLSessionDataTask *postTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error != nil) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if ([fatalStatusCodes containsObject:[NSNumber numberWithLong:statusCode]]) {
                if (retryRemaining > 0) {
                    void (^addRetryOperation)(void) = ^{
                        [self requestUrlWithRetryRemaining:retryRemaining - 1 maxRetry:maxRetry retryInterval:retryInterval fatalStatusCodes:fatalStatusCodes originalRequest:request eventIds:arrEventIds];
                    };
                    
                    if (retryInterval > 0.0) {
                        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryInterval * pow(2, maxRetry - retryRemaining) * NSEC_PER_SEC));
                        TBLog(@"Delaying the next attempt by %.0f seconds …", retryInterval * pow(2, maxRetry - retryRemaining));
                        
                        // Not accurate because of "Timer Coalescing and App Nap" - which helps to reduce power consumption.
                        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                            addRetryOperation();
                        });
                        
                    } else {
                        addRetryOperation();
                    }
                } else {
                    TBLog(@"No more attempts left! Will execute the failure block.");
                }
            }
            else {
                TBLog(@"Failed with error: %@", [error localizedDescription]);
            }
        }
        else {
            //Success
            for (NSString *insertId in arrEventIds) {
                [[DBManager shared] updateRecordsWithEventId:[insertId integerValue] withIsSync:YES];
            }
            [self startTimer];
        }
    }];
    [postTask resume];
}


# pragma mark - HTTP Request and Response Management

-(void)startTimer {
    if (self.timerSync == nil) {
        if (self.config.timeBuffer < kTimeBuffer) {
            self.config.timeBuffer = kTimeBuffer;
            TBLog(@"For performance and efficiancy you cannot sent `timeBuffer` below 5 seconds.");
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timerSync = [NSTimer scheduledTimerWithTimeInterval:self.config.timeBuffer target:self selector:@selector(syncDataWithServer) userInfo:nil repeats:YES];
        });
    }
}

-(void)stopTimer {
    if (self.timerSync) {
        [self.timerSync invalidate];
        self.timerSync = nil;
    }
}

-(void)syncDataWithServer {
    TBLog(@"Fire time: %@",[NSDate date]);
    
    if (self.config.queueEnabled) {
        NSArray *arrAnalyticsDataToSync = [[DBManager shared] fetchAnalayticsDataWithSync:NO useLimit:YES withBatchSize:self.config.itemsInQueue];
        //NSLog(@"=================Batch Size: %d", self.config.itemsInQueue);
        //NSLog(@"=================No of items in the queue: %lu", (unsigned long)arrAnalyticsDataToSync.count);
        if (arrAnalyticsDataToSync.count > 0) {
            if (arrAnalyticsDataToSync.count == self.config.itemsInQueue) {
                //NSLog(@"=================ENTERED=================");
                //NSArray *itemsForAnalyticsData = [arrAnalyticsDataToSync subarrayWithRange: NSMakeRange(0, self.config.itemsInQueue)];
                NSMutableArray *arrInteractionIds = [NSMutableArray new];
                NSMutableArray *arrInteractionItems = [NSMutableArray new];
                
                for (ModelEvent *modelEvent in arrAnalyticsDataToSync) {
                    // create array with `interaction` events
                    if ([modelEvent.eventType isEqualToString:@"interaction"]) {
                        [arrInteractionIds addObject:modelEvent.eventId];
                        [arrInteractionItems addObject:modelEvent.eventContent];
                        
                        //Update `isSync` to `YES` of these records as will be sent to server.
                        [[DBManager shared] updateRecordsWithEventId:[modelEvent.eventId integerValue] withIsSync:YES];
                    }
                    else { //`launch` and `scene` type events should not be sent as batch
                        [self sendEventContent:modelEvent.eventContent eventIds:@[modelEvent.eventId] withCompletion:self.completion];
                        //Update `isSync` to `YES` of these records as will be sent to server.
                        [[DBManager shared] updateRecordsWithEventId:[modelEvent.eventId integerValue] withIsSync:YES];
                    }
                }
                
                if (arrInteractionIds.count > 0 && arrInteractionItems.count > 0) {
                    [self sendEventContent:[NSDictionary dictionaryWithObjectsAndKeys:arrInteractionItems,@"interaction", nil] eventIds:arrInteractionIds withCompletion:self.completion];
                }
            }
        }
    }
    else {
        NSArray *arrAnalyticsDataToSync = [[DBManager shared] fetchAnalayticsDataWithSync:NO useLimit:NO withBatchSize:0];
        if (arrAnalyticsDataToSync.count > 0) {
            for (ModelEvent *modelEvent in arrAnalyticsDataToSync) {
                [self sendEventContent:modelEvent.eventContent eventIds:@[modelEvent.eventId] withCompletion:self.completion];
                //Update `isSync` to `YES` of these records as will be sent to server.
                [[DBManager shared] updateRecordsWithEventId:[modelEvent.eventId integerValue] withIsSync:YES];
            }
        }
    }
}

- (void)sendEventContent:(NSDictionary*)eventsValue eventIds:(NSArray*)insertIds withCompletion:(CompletionHandler)handler {
    
    NSString *sourceDataAddress = [NSString stringWithFormat:@"%@%@/sources/%@/data",kIntemptServerAddress,self.organizationId,self.sourceId];
    TBLog(@"Tracker URL: %@",sourceDataAddress);
    
    NSURLRequest *request = [self prepareRequestWithURL:[NSURL URLWithString:sourceDataAddress] withParams:eventsValue withToken:self.token];
    if(request)
        [self sendDataToServerWithRequest:request eventIds:insertIds withCompletion:handler];
}


- (void)sendEvents:(NSDictionary*)eventsValue multipleRecordExits:(BOOL)status withCompletion:(CompletionHandler)handler {
    
    NSString *sourceDataAddress = [NSString stringWithFormat:@"%@%@/sources/%@/data",kIntemptServerAddress,self.organizationId,self.sourceId];
    TBLog(@"Tracker URL: %@",sourceDataAddress);
    
    NSURLRequest *request = [self prepareRequestWithURL:[NSURL URLWithString:sourceDataAddress] withParams:eventsValue withToken:self.token];
    if(request)
        [self sendDataToServerWithRequest:request multipleRecordExits:status withCompletion:handler];
}


- (void)sendProximitySourceEvents:(NSString*)orgId andSourceId:(NSString*)trackerId andToken:(NSString*)token eventsValue:(NSMutableDictionary*)eventsValue withCompletion:(CompletionHandler)handler {
    
    NSString *sourceDataAddress = [NSString stringWithFormat:@"%@%@/sources/%@/data",kIntemptServerAddress,orgId,trackerId];
    TBLog(@"Beacon URL: %@",sourceDataAddress);
    
    NSURLRequest *request = [self prepareRequestWithURL:[NSURL URLWithString:sourceDataAddress] withParams:eventsValue withToken:self.token];
    if(request)
        [self sendDataToServerWithRequest:request multipleRecordExits:NO withCompletion:handler];
}

-(NSURLRequest*)prepareRequestWithURL:(NSURL*)url withParams:(NSDictionary*)dictParmas withToken:(NSString*)apiToken {
    
    NSString *hearderToken = [NSString stringWithFormat:@"ApiKey %@",apiToken];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:hearderToken forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    
    NSError *error = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:dictParmas options:0 error:&error];
    if(error){
        TBLog(@"Parsing error:------%@",[error localizedDescription]);
        return nil;
    }
    TBLog(@"Post Params:------%@",[[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]);
    
    [request setHTTPBody:postData];
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    return request;
}

- (void)sendDataToServerWithRequest:(NSURLRequest*)request eventIds:(NSArray*)arrInsertIds withCompletion:(CompletionHandler)handler {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data != nil){
                NSMutableDictionary *dictResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                TBLog(@"sendDataToServerWithRequest eventIds Response:------%@",dictResponse);
                if(handler) {
                    if(error) {
                        //Reset `isSync` status to `NO` if failed
                        for (NSString *insertId in arrInsertIds) {
                            [[DBManager shared] updateRecordsWithEventId:[insertId integerValue] withIsSync:NO];
                        }
                        
                        // handle HTTP errors here
                        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                            
                            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                            NSArray *arrFailureStatusCodes = @[@408, @500, @501, @502, @503, @504];
                            
                            if ([arrFailureStatusCodes containsObject:[NSNumber numberWithLong:statusCode]]) {
                                TBLog(@"HTTP status code: %ld", (long)statusCode);
                                
                                // Not working
                                /*NSURLSessionDataTask *taskRetry = [self requestUrlWithRetryRemaining:kRetryLimit maxRetry:kRetryLimit retryInterval:kRetryDelay progressive:true fatalStatusCodes:arrFailureStatusCodes originalRequestCreator:^NSURLSessionDataTask *(void (^retryBlock)(NSURLSessionDataTask *, NSError *)) {
                                 return postDataTask;
                                 } originalFailure:^(NSURLSessionDataTask *task, NSError *error) {
                                 }];
                                 [taskRetry resume];*/
                                
                                // Retry method
                                [self requestUrlWithRetryRemaining:kRetryLimit maxRetry:kRetryLimit retryInterval:kRetryDelay fatalStatusCodes:arrFailureStatusCodes originalRequest:request eventIds:arrInsertIds];
                                
                                [self stopTimer];
                            }
                        }
                        
                        if (handler != NULL){
                            handler(NO, nil, error);
                        }
                    }
                    else {
                        if ([dictResponse valueForKey:@"error"] && [dictResponse valueForKey:@"status"]) {
                            
                            if([[dictResponse valueForKey:@"status"]intValue] == 400){
                                ////delete bad requests data from local db, so that it should not keep throwing and trying to send to server, it is possible developer can generate bad data which is not matching with schema
                                for (NSString *insertId in arrInsertIds) {
                                    TBLog(@"Deleted Bad Request from local queu");
                                    [[DBManager shared] deleteRecordsWithEventId:[insertId integerValue]];
                                }
                            }else{
                                ////Reset `isSync` status to `NO` if failed
                                for (NSString *insertId in arrInsertIds) {
                                    [[DBManager shared] updateRecordsWithEventId:[insertId integerValue] withIsSync:NO];
                                }
                            }
                            
                            NSString *const kIntemptErrorDomain = [[NSBundle mainBundle] bundleIdentifier];
                            NSDictionary *dictUserInfo = @{
                                NSLocalizedDescriptionKey: NSLocalizedString([dictResponse valueForKey:@"error"], nil),
                                NSLocalizedFailureReasonErrorKey: NSLocalizedString([dictResponse valueForKey:@"message"], nil),
                                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"", nil)
                            };
                            
                            NSError *createError = [NSError errorWithDomain:kIntemptErrorDomain code:[[dictResponse valueForKey:@"status"] intValue] userInfo:dictUserInfo];
                            if (handler != NULL){
                                handler(NO, nil, createError);
                            }
                        }
                        else {
                            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                            TBLog(@"success response code=%ld",(long)httpResponse.statusCode);
                            [[DBManager shared] deleteAnalayticsDataWithSync:YES];
                            if (handler != NULL){
                                handler(YES, dictResponse, nil);
                            }
                        }
                    }
                }
            }else{
                //Reset `isSync` status to `NO` if failed
                for (NSString *insertId in arrInsertIds) {
                    [[DBManager shared] updateRecordsWithEventId:[insertId integerValue] withIsSync:NO];
                }
                if (handler != NULL){
                    handler(NO, nil, error);
                }
            }
        });
    }];
    
    [postDataTask resume];
}

- (void)sendDataToServerWithRequest:(NSURLRequest*)request multipleRecordExits:(BOOL)status withCompletion:(CompletionHandler)handler {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (data != nil){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableDictionary *dictResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                TBLog(@"Response:------%@",dictResponse);
                
                if (status == YES) {
                    //Remove used 5 events
                    if(self->arrInteraction.count >= 5){
                        [self->arrInteraction removeObjectsInRange:NSMakeRange(0, 5)];
                        //TBLog(@"5 interaction events removed after sending to server.");
                        
                        //Make sure there is no leftover in the array
                        if (self->arrInteraction.count > 0 && self->arrInteraction.count < 5) {
                            NSArray *items = [self->arrInteraction copy];
                            [self->arrInteraction removeObjectsInArray:items];
                            NSDictionary *dictParams = [NSDictionary dictionaryWithObjectsAndKeys:items,@"interaction", nil];
                            
                            //TBLog(@"Rest %ld interaction events is being batched.", items.count);
                            TBLog(@"sendDataToServerWithRequest  Event Data (Touch, Change, Action): %@",dictParams);
                            
                            //[self sendInteractions:dictParams withCompletion:handler];
                            [self sendEvents:dictParams multipleRecordExits:YES withCompletion:handler];
                        }
                    }
                }
                
                if(handler) {
                    if(error) {
                        handler(NO, nil, error);
                    }
                    else {
                        if ([dictResponse valueForKey:@"error"] && [dictResponse valueForKey:@"status"]) {
                            NSString *const kIntemptErrorDomain = [[NSBundle mainBundle] bundleIdentifier];
                            NSDictionary *dictUserInfo = @{
                                NSLocalizedDescriptionKey: NSLocalizedString([dictResponse valueForKey:@"error"], nil),
                                NSLocalizedFailureReasonErrorKey: NSLocalizedString([dictResponse valueForKey:@"message"], nil),
                                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"", nil)
                            };
                            if (handler != NULL){
                                NSError *createError = [NSError errorWithDomain:kIntemptErrorDomain code:[[dictResponse valueForKey:@"status"] intValue] userInfo:dictUserInfo];
                                handler(NO, nil, createError);
                            }
                        }
                        else {
                            if (handler != NULL){
                                handler(YES, dictResponse, nil);
                            }
                        }
                    }
                }
            });
        }
        
    }];
    
    [postDataTask resume];
}

# pragma mark - visitorId
- (NSString *)getVisitorId {
    return visitorId;
}

# pragma mark - SDK
+ (NSString *)sdkVersion {
    return kIntemptSdkVersion;
}

# pragma mark - Helper Methods

- (BOOL)isErrorFatal:(NSError *)error {
    switch (error.code) {
        case kCFHostErrorHostNotFound:
        case kCFHostErrorUnknown: // Query the kCFGetAddrInfoFailureKey to get the value returned from getaddrinfo; lookup in netdb.h
            // HTTP errors
        case kCFErrorHTTPAuthenticationTypeUnsupported:
        case kCFErrorHTTPBadCredentials:
        case kCFErrorHTTPParseFailure:
        case kCFErrorHTTPRedirectionLoopDetected:
        case kCFErrorHTTPBadURL:
        case kCFErrorHTTPBadProxyCredentials:
        case kCFErrorPACFileError:
        case kCFErrorPACFileAuth:
        case kCFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod:
            // Error codes for CFURLConnection and CFURLProtocol
        case kCFURLErrorUnknown:
        case kCFURLErrorCancelled:
        case kCFURLErrorBadURL:
        case kCFURLErrorUnsupportedURL:
        case kCFURLErrorHTTPTooManyRedirects:
        case kCFURLErrorBadServerResponse:
        case kCFURLErrorUserCancelledAuthentication:
        case kCFURLErrorUserAuthenticationRequired:
        case kCFURLErrorZeroByteResource:
        case kCFURLErrorCannotDecodeRawData:
        case kCFURLErrorCannotDecodeContentData:
        case kCFURLErrorCannotParseResponse:
        case kCFURLErrorInternationalRoamingOff:
        case kCFURLErrorCallIsActive:
        case kCFURLErrorDataNotAllowed:
        case kCFURLErrorRequestBodyStreamExhausted:
        case kCFURLErrorFileDoesNotExist:
        case kCFURLErrorFileIsDirectory:
        case kCFURLErrorNoPermissionsToReadFile:
        case kCFURLErrorDataLengthExceedsMaximum:
            // SSL errors
        case kCFURLErrorServerCertificateHasBadDate:
        case kCFURLErrorServerCertificateUntrusted:
        case kCFURLErrorServerCertificateHasUnknownRoot:
        case kCFURLErrorServerCertificateNotYetValid:
        case kCFURLErrorClientCertificateRejected:
        case kCFURLErrorClientCertificateRequired:
        case kCFURLErrorCannotLoadFromNetwork:
            // Cookie errors
        case kCFHTTPCookieCannotParseCookieFile:
            // Errors originating from CFNetServices
        case kCFNetServiceErrorUnknown:
        case kCFNetServiceErrorCollision:
        case kCFNetServiceErrorNotFound:
        case kCFNetServiceErrorInProgress:
        case kCFNetServiceErrorBadArgument:
        case kCFNetServiceErrorCancel:
        case kCFNetServiceErrorInvalid:
            // Special case
        case 101: // null address
        case 102: // Ignore "Frame Load Interrupted" errors. Seen after app store links.
            return YES;
            
        default:
            break;
    }
    
    return NO;
}

-(NSString*)convertDictionaryToString:(NSDictionary*)dict {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    if (error!= nil) {
        TBLog(@"Failed to convert to data: %@",[error localizedDescription]);
        return nil;
    }
    else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

- (NSDictionary*)convertStringToDictionary:(NSString*)string {
    NSError *error = nil;
    NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictJson = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error!= nil) {
        TBLog(@"Failed to convert to dictionary: %@",[error localizedDescription]);
        return nil;
    }
    else {
        return dictJson;
    }
}

@end



