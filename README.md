
# Intempt iOS Source

## Requirements
- iOS 12.0+
- Minimum Xcode 10.0


## Getting Started

### Integration :
1. At first download code from https://github.com/intempt/ios-sdk.git). Then open the folder ios-source-master -> intempt.

2. Next open **intempt.xcodeproj**, then select `Set the active scheme` to `Generic iOS Device` and build. 
3. Again select `Set the active scheme` to `iPhone 11` and build. (Any Simulator can be selected as target) 
4. Now change `Set the active scheme` to `Intempt-Universal` and `Generic iOS Device`
5. Finally press `Product` ->  `Archieve` from Xcode menu (The idea is here to build a universal framework so that it can be used for real devices and simulators)

6. A Finder will open right when archiving is done. Now right click on `Intempt.Framework` shortcut and press `Show Original Folder`.

7. Drag & Drop `Intempt.Framework` in your iOS app.


8. `Intempt.framework` must set to `Embed & Sign`

	![Embed & Sign](/screenshots/1.png)

9. Open Project-->Edit Scheme->Unclick Debug Executable

	![Embed & Sign](/screenshots/6.png)

10. Next go to app's Info.plist file and add the privacy keys.

| Key | Value |
| ------ | ------ |
| Privacy - Location Always Usage Description | Location used to track where you are |
| Privacy - Location When In Use Usage Description | Location used to track where you are |
| Privacy - Location Always and When In Use Usage Description | Location used to track where you are |


### Swift :
If Xcode 11.3 or above

Goto SceneDelegate.swift file

``` swift
import Intempt
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {       
       IntemptTracker.tracking(withOrgId: "Your Organization Id", andSourceId: "Your Source ID", andToken: "Your Token")
    
       guard let _ = (scene as? UIWindowScene) else { return }
   }
```
Else you will have the `ViewController.swift` file and then paste the copied source snippet into the `viewDidLoad` function: 

``` swift
import Intempt
  override func viewDidLoad() {
        super.viewDidLoad()
        IntemptTracker.tracking(withOrgId: "Your Organization Id", andSourceId: "Your Source ID", andToken: "Your Token")
}
```
### Objective C :

If you are using Xcode 11.3 or above go to `SceneDelegate.m` file and paste the copied source snippet like the following:

``` objectivec
@import Intempt;
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    [IntemptTracker trackingWithOrgId:@"Your Organization Id" andSourceId:@"Your Source ID" andToken:@"Your Token"];
}
```

Else you will have the `ViewController.m` file and then paste the copied source snippet like the following:

``` objectivec
@import Intempt
- (void)viewDidLoad {
    [super viewDidLoad];
    [IntemptTracker trackingWithOrgId:@"Your Organization Id" andSourceId:@"Your Source ID" andToken:@"Your Token"];
}
```
**NOTE**: We used `playground` as Organization ID for testing purpose only. For live app you need to provide an actual Organization ID.

#### Get VisitorId From Framework

``` swift
let visitorId = IntemptClient.shared()?.getVisitorId()
```
#### Identifying Visitors
Provide email or phone number.

``` swift
IntemptTracker.identify("test@example.com", withProperties: nil) { (status, error) in 
	if(status) {
		//Do something
	}
}
```
#### Custom event
On using this a user can create a custom event based on the need of the project and can track the event details with that custom method.

```swift 
let arrayData = [{       
                "flightId" : "1",
                "bookingDate" : "2020-05-26",
                "bookingId": "2",
                "bookingStatus" : "booked"
              }]
IntemptTracker.track("Online Hotel Booking", withProperties: arrHotelBooking as? [Any]) { (status, error) in
	if(status) {
		//Do something
	}
}             
```

#### Disable Text Capture
Call this method if you want to disable capturing input texts like UItextField, UItextView. By default its `false`. Secure entries are also excluded for privacy.

```swift 
IntemptTracker.disableTextInput(true)
```

## Intempt Proximity
### ibeacon does not support Xcode iOS Simulator. You need a real device to test the ibeacon.
Install an Intempt beacon At your preferable place. Add this SDK in your existing application. Thus it will help you to know about your entry and exit range.
This sdk supports any kind of beacon that allows you to change the UUID in the vendors Beacon Manager. The UUID is a unique broadcasting number which allows Intempt to know which types of beacons to look for. You can think of it like tuning to a radio station.

Today, Intempt’s mobile SDK looks for ONE UUID by default. Use any of them with your existing beacons to enable them with Intempt.

### Key components

Intempt Proximity SDK is built on top of two key components: _

- Entry -  when you are enter a region.

- Exit -  when you are exit a region.


Go to app's Info.plist file and add the privacy keys.


| Key | Value |
| ------ | ------ |
| Privacy - Location Always Usage Description | Location used to track where you are |
| Privacy - Location When In Use Usage Description | Location used to track where you are |
| Privacy - Location Always and When In Use Usage Description | Location used to track where you are |
| Privacy - Bluetooth Always Usage Description | This app uses Bluetooth communication to detect nearby beacons |
| Privacy - Bluetooth Peripheral Usage Description | This app uses Bluetooth communication to detect nearby beacons |




### Swift :

ViewController.swift file

``` swift
import Intempt
  override func viewDidLoad() {
        super.viewDidLoad()
        IntemptTracker.beacon(withOrgId: "Your Organization ID", andSourceId: "Your Source ID", andToken: "Your Token", andDeviceUUID:"Beacon device UUID")
        IntemptClient.shared()?.delegate = self
  }
```

Next implement this methods:

``` swift
/*Helps to detect the entry time , when application entered the monitoring region*/
func  didEnterRegion(_ beaconData: CLBeacon!) {
}

/*Helps to detect the exit time , when application exits the monitoring region*/
func  didExitRegion(_ beaconData: CLBeacon!) {
}
```

### Objective C :
ViewController.m file

``` objectivec
@import Intempt;
- (void)viewDidLoad {
    [super viewDidLoad];
    [IntemptTracker beaconWithOrgId:@"Your Organization ID" andSourceId:@"Your Source ID" andToken:@"Your Token" andDeviceUUID:@"Beacon device UUID"];
    IntemptClient.sharedClient.delegate = self;
}
```

Next implement this methods:

``` objectivec
/*Helps to detect the entry time , when application entered the monitoring region*/
- (void)didEnterRegion:(CLBeacon*)beaconData {
}

/*Helps to detect the exit time , when application exits the monitoring region*/
- (void)didExitRegion:(CLBeacon*)beaconData {
}
```


#### Identifying Visitors (Optional)
Provide email or phone number.

``` swift
IntemptTracker.identifyUsingBeacon("test@example.com", withProperties: nil) { (status, error) in 
	if(status) {
		//Do something
	}
}
```
Use this method when you want to identify using beacon API separately.  
##How to test beacon functionality using Beacon Android simulator?
### Installation :
* At first Download App from https://play.google.com/store/apps/details?id=net.alea.beaconsimulator&hl=en_IN

* Then open the iOS app you integrated Intempt framework.

* Next set up beacon simulator in each room.
The room you go to will get the entry and exit value of the room.


## DemoTracking App
1. Add the framework in the application. once it launches, it will show the following pop up. click on "Allow While Using App". Thus you are enabling the keys to track your location details.

	![Allow While Using App](/screenshots/2.png)

2. In the following demo application, after running it will display a Login Screen. On clicking the login button it fires the IdentifyVisitor function.

	![IdentifyVisitor Function](/screenshots/3.png)

3. Here on every touch event the tracker will fetch event details.

	![Touch Event on App](/screenshots/4.png)

4. On clicking payment button , purchase custom event will be fired in this project.

	![Payment Button Click](/screenshots/5.png)




