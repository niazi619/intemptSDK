//
//  IntemptTracker.h
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#ifndef IntemptTracker_h
#define IntemptTracker_h
@import UIKit;

typedef void(^CompletionHandler)(BOOL status, id result, NSError *error);

@interface IntemptTracker : NSObject

@property (nonatomic, copy) CompletionHandler completion;

/**
 Call this method from ScenseDelegate's `scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions)` or AppDelegate's  `application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)` for your app to start tracker during launch. Alternatively you can call this method at any ViewController's  `viewDidLoad` method. Wherever you call it will initilaze & track the whole app.
 @param orgId  Your Intempt Organization ID generated from intempt developer console
 @param sourceId Your Intempt Source ID generated from intempt developer console
 @param token Your Intempt Source Token generated from intempt developer console
 @param settings A configuration object specifying settings like queueEnabled, timeBuffer, retryLimit, initialDelay, retryDelay, isInputTextCaptureEnabled. For more details please look into `IntemptConfig` class.
 @note iOS 13 above should implement it on ScenseDelegate
*/
+ (void)trackingWithOrgId:(NSString*)orgId withSourceId:(NSString*)sourceId withToken:(NSString*)token withConfig:(id)settings onCompletion:(CompletionHandler)handler;

/**
 Use this method when you want to set a unique identifier (email or phone no.) for your app.
 @param identity An Identity i.e, email address or phone number
 @param userProperties A dictionary of user properties (set accroding to your custom schema's parameters on intempt developer site)
 @note In Swift you can pass Error object instead of NSError as error
*/
+ (void)identify:(NSString*)identity withProperties:(NSDictionary*)userProperties onCompletion:(CompletionHandler)handler;

/**
 Use this method when you specific tracking information to server. Creating custom Schema is mandatory to use this method. Go to your project on https://app.intempt.com and select organization and then select source and click on `Visit Schema` to add custom Schema
 Without adding collection in schema on https://app.intempt.com custom events will not be saved, also make sure properties added in schema have same data types as your data, if you will try sending string data but field data type is int then you will get error
 @param collectionName Custom Schema name (Exclude the unique id)
 @param userProperties An Array of user properties which should be the same parameters you added in your custom schema
 @note In Swift you can pass Error object instead of NSError as error
*/
+ (void)track:(NSString*)collectionName withProperties:(NSArray*)userProperties onCompletion:(CompletionHandler)handler;



@end

#endif
