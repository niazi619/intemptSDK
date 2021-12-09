//
//  IntemptClient.h
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

@import Foundation;
@import CoreLocation;

#import <Intempt/IntemptConfig.h>

typedef void(^CompletionHandler)(BOOL status, id result, NSError *error);

@interface IntemptClient : NSObject

@property (strong, nonatomic) CLLocation *currentLocation;

/** An Intempt configuartion which can be configured by user. For more details please look into `IntemptConfig` class.
 */
@property(strong, nonatomic) IntemptConfig *config;

/**
 Retuns a fully initialzed `IntemptClient` object
 @param organizationId Organization Id
 @param trackerId  Tracker Id
 @param token Source token
*/
+ (IntemptClient *)sharedClientWithOrganizationId:(NSString *)organizationId withTrackerId:(NSString *)trackerId withToken:(NSString *)token withConfig:(id)settings withCompletion:(CompletionHandler)handler;

/**
 Retuns a fully initialzed `IntemptClient` object
*/
+ (IntemptClient *)sharedClient;

/**
 Call this to authorize geo location always (iOS 8 and above). You must also add NSLocationAlwaysUsageDescription string to Info.plist to
 authorize geo location always (foreground and background), call this BEFORE doing anything else with ITClient.
 @note From iOS 13 user can't grant location tracking 'always' from app. A user need to go to app settings to manually enable it.
 */
+ (void)authorizeGeoLocationAlways;

/**
 Call this to authorize geo location when in use (iOS 8 and above). You must also add NSLocationWhenInUsageDescription string to Info.plist to
 authorize geo location when in use (foreground), call this BEFORE doing anything else with ITClient.
 */
+ (void)authorizeGeoLocationWhenInUse;

/**
 Call this to disable tracking, By default tracking is enabled. NOTE: this settings is persistent, once disabled it will remain disabled even app is killed and relaucnhed, To renable tracking 'enableTracking' function should be called.
  NOTE: IntemptSDK respect  and follow Apple rules,  so if Device->Settings->Privacy->Tracking is disabled, then intemptSDK will  not track anything, its  on Developer to ask the user to enable the tracking in appropriate way, e.g showing a nice screen by explaning why user should allow tracking.
 */
+ (void)disableTracking;

/**
 Call this to enable tracking. By default it's enabled.
 */
+ (void)enableTracking;

/**
 Returns whether or not tracking is currently enabled.
 
 @return true if tracking is enabled, false if disabled.
 */
+ (Boolean)isTrackingEnabled;

/**
 Call this to disable debug logging.
 */
+ (void)disableLogging;

/**
 Call this to enable debug logging. By default it's disabled.
 */
+ (void)enableLogging;

/**
 Returns whether or not logging is currently enabled.
 
 @return true if logging is enabled, false if disabled.
 */
+ (Boolean)isLoggingEnabled;
/**
 Call this if your code needs to use more than one Intempt project.  By convention, if you
 call this, you're responsible for releasing the returned instance once you're finished with it.
 
 Otherwise, just use [IntemptClient sharedClient].
 
 @param organizationId Your Intempt Organization ID.
 @param trackerId Your Intempt Tracker ID.
 @param token Your Intempt Tracker security token.
 @return An initialized instance of ITClient.
 */
- (id)initWithOrganizationId:(NSString *)organizationId withTrackerId:(NSString *)trackerId withToken:(NSString *)token withConfig:(id)settings withCompletion:(CompletionHandler)handler;

/**
 Call this if your code needs to use more than one Intempt project along with some extra properties & properties overrides. By convention, if you
 call this, you're responsible for releasing the returned instance once you're finished with it.
 @param organizationId Your Intempt Organization ID.
 @param sourceId Your Intempt Tracker ID.
 @param token Your Intempt Tracker security token.
 @param propertiesOverrides A property Dictonary
 @param propertiesOverridesBlock A completion block
 @return An initialized instance of ITClient.
 */
-(id)initWithOrganizationId:(NSString *)organizationId withTrackerId:(NSString *)sourceId withToken:(NSString *)token withConfig:(id)settings withPropertiesOverrides:(NSDictionary *)propertiesOverrides withPropertiesOverridesBlock:(NSDictionary *(^)(NSString *))propertiesOverridesBlock withCompletion:(CompletionHandler)handler;

/**
Use this Instance method when you want to add a specific event
@param event A Dictionary
@param eventCollection A event collection name
@return If event is added it will return YES otherwise NO
*/
- (BOOL)addEvent:(NSDictionary *)event toEventCollection:(NSString *)eventCollection withCompletion:(CompletionHandler)handler;

/**
Use this Instance method when you want to set a unique identifier (email or phone no.) for your app.
@param identity An Identity i.e, email address or phone number
@param userProperties A dictionary of user properties (set accroding to your custom schema's parameters on intempt developer site)
*/
- (void)identify:(NSString*)identity withProperties:(NSDictionary *)userProperties withCompletion:(CompletionHandler)handler;

/**
Use this Instance method when you specific tracking information to server. Creating custom Schema is mandatory to use this method. Go to your project on https://app.intempt.com and click on `Visit Schema` to add custom Schema
@param collectionName Custom Schema name (Exclude the unique id)
@param userProperties An Array of user properties which should be the same parameters you added in your custom schema
*/
- (void)track:(NSString*)collectionName withProperties:(NSArray *)userProperties withCompletion:(CompletionHandler)handler;


/**
 Call this method in order to reset tracking session.
 */
- (void)validateTrackingSession;

/**
 Call this method to end the tracking session. it will not create new session automatically, developer is responsible to create new session using startTrackingSession
 */
- (void)endTrackingSession;

/**
 Call this method to star the new tracking session.
 */
- (void)startTrackingSession;


/**
 Call this to initialize CLLocationManager if not initialized and start updating location
*/
- (void)refreshCurrentLocation;

/**
Get Intempt Visitor ID
@return visitior ID
*/
- (NSString *)getVisitorId;

/**
 Get Intempt SDK Version
 @return The current SDK version.
 */
+ (NSString *)sdkVersion;

+ (NSNumber*)addTimestamp;

@property (nonatomic, copy) CompletionHandler completion;

// defines the TBLog macro
#define INTEMPT_LOGGING_ENABLED [IntemptClient loggingEnabled]
#define TBLog(message, ...)if([IntemptClient isLoggingEnabled]) NSLog(message, ##__VA_ARGS__)

@end

