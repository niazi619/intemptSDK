//
//  LocationsManager.swift
//

import Foundation
import CoreLocation

class LocationsManager: NSObject, CLLocationManagerDelegate {

    var locationManager:CLLocationManager!
    var location:CLLocation!
    var recentLat:Double = 0.0
    var recentLng:Double = 0.0
    
    override init() {
        super.init()
    }
    
    static let sharedInstance: LocationsManager = {
        let instance = LocationsManager()
        // setup code
        return instance
    }()
    
    // MARK: - Initialization Method
    
   
    func startGtettingLocation() {
        
        if(self.locationManager == nil){
            self.locationManager = CLLocationManager()
        }
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.pausesLocationUpdatesAutomatically = false
        //self.locationManager.distanceFilter = 50
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func stopGtettingLocation() {
        if(self.locationManager != nil){
            self.locationManager.stopUpdatingLocation()
        }
    }
    //MARK:- Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        self.location = location
        self.recentLat = (location?.coordinate.latitude)!
        self.recentLng = (location?.coordinate.longitude)!
    
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        print("error=",error.localizedDescription)
    }
    class func isLocationServiceEnabled()->Bool{
        
        let enable:Bool = CLLocationManager.locationServicesEnabled()
        let auth = CLLocationManager.authorizationStatus()
        if(!enable || auth == .notDetermined || auth == .restricted || auth == .denied || CLLocationManager.locationServicesEnabled() == false){
            return false
        }
        else{
            return true
        }
        
    }

}
