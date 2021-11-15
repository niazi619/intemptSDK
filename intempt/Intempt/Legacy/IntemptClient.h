//
//  IntemptClient.h
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

@import Foundation;
@import CoreLocation;
@import CoreBluetooth;

#import <Intempt/IntemptConfig.h>

typedef void(^CompletionHandler)(BOOL status, id result, NSError *error);

@protocol intemptDelegate <NSObject>
/**
 Called upon entering the region
 @param beaconData CLBeacon
*/
-(void)didEnterRegion:(CLBeacon*)beaconData;

/**
 Called upon exiting the region
 @param beaconData CLBeacon
*/
-(void)didExitRegion:(CLBeacon*)beaconData;

@end

@interface IntemptClient : NSObject

@property (weak, nonatomic) id<intemptDelegate> delegate;
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
Use this Instance method to initilaze the beacon for the app.
@param orgId Your Intempt Organization ID.
@param trackerId Your Intempt Source ID.
@param token Your Intempt Security Token.
*/
- (void)withOrgId:(NSString*)orgId andSourceId:(NSString*)trackerId andToken:(NSString*)token uuidString:(NSString*)uuid withCompletion:(CompletionHandler)handler;


/**
Use this Instance method when you want to set a unique identifier (email or phone no.) for your app. Its an alternative to default identify method and more likely you didn't enable tracking for the app.
@param identity An Identity i.e, email address or phone number
@param userProperties A dictionary of user properties (set accroding to your custom schema's parameters on intempt developer site)
*/
- (void)identifyUsingBeaconWith:(NSString*)identity withProperties:(NSDictionary *)userProperties withCompletion:(CompletionHandler)handler;

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

@property (nonatomic, copy) CompletionHandler completion;

// defines the TBLog macro
#define INTEMPT_LOGGING_ENABLED [IntemptClient loggingEnabled]
#define TBLog(message, ...)if([IntemptClient isLoggingEnabled]) NSLog(message, ##__VA_ARGS__)

@end

