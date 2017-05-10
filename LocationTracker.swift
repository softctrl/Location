//
//  LocationTracker.swift
//  LocationSwing
//
//  Created by Mazhar Biliciler on 19/07/14.
//  Copyright (c) 2014 Mazhar Biliciler. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

let LATITUDE = "latitude"
let LONGITUDE = "longitude"
let ACCURACY = "theAccuracy"

class LocationTracker : NSObject, CLLocationManagerDelegate, UIAlertViewDelegate {
    
    var myLastLocation : CLLocationCoordinate2D?
    var myLastLocationAccuracy : CLLocationAccuracy?
    
    var accountStatus : NSString?
    var authKey : NSString?
    var device : NSString?
    var name : NSString?
    var profilePicURL : NSString?
    var userid : Int?
    
    var shareModel : LocationShareModel?
    
    var myLocation : CLLocationCoordinate2D?
    var myLocationAcuracy : CLLocationAccuracy?
    var myLocationAltitude : CLLocationDistance?
    
    override init()  {

        super.init()
        self.shareModel = LocationShareModel()
        self.shareModel!.myLocationArray = NSMutableArray()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
    }
    
    class func sharedLocationManager()->CLLocationManager? {
        
        struct Static {
            static var _locationManager : CLLocationManager?
        }
        
        objc_sync_enter(self)
        if Static._locationManager == nil {
            Static._locationManager = CLLocationManager()
            Static._locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        }
        
        objc_sync_exit(self)
        return Static._locationManager!
    }
    
    // MARK: Application in background
    func applicationEnterBackground() {
        let locationManager : CLLocationManager = LocationTracker.sharedLocationManager()!
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        
        self.shareModel!.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        _ = self.shareModel?.bgTask?.beginNewBackgroundTask()
    }
    
    func restartLocationUpdates() {
        print("restartLocationUpdates\n")
        
        if self.shareModel?.timer != nil {
            self.shareModel?.timer?.invalidate()
            self.shareModel!.timer = nil
        }
        
        let locationManager : CLLocationManager = LocationTracker.sharedLocationManager()!
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
    }
    
    func startLocationTracking() {
        print("startLocationTracking\n")
        
        if CLLocationManager.locationServicesEnabled() == false {
            print("locationServicesEnabled false\n")
            let servicesDisabledAlert : UIAlertView = UIAlertView(title: "Location Services Disabled", message: "You currently have all location services for this device disabled", delegate: nil, cancelButtonTitle: "OK")
            servicesDisabledAlert.show()
            
        } else {
            
            
            let authorizationStatus : CLAuthorizationStatus = CLLocationManager.authorizationStatus()
            if (authorizationStatus == CLAuthorizationStatus.denied) || (authorizationStatus == CLAuthorizationStatus.restricted) {
                print("authorizationStatus failed")
            } else {
                let locationManager : CLLocationManager = LocationTracker.sharedLocationManager()!
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                locationManager.distanceFilter = kCLDistanceFilterNone
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        print("locationManager didUpdateLocations\n")
        let count = locations.count-1
        for i in 0...count {
            let newLocation : CLLocation = locations[i] as! CLLocation
            let theLocation : CLLocationCoordinate2D = newLocation.coordinate
            let theAltitude : CLLocationDistance = newLocation.altitude
            let theAccuracy : CLLocationAccuracy = newLocation.horizontalAccuracy
            let locationAge : TimeInterval = newLocation.timestamp.timeIntervalSinceNow
            if locationAge > 30.0 {
                continue
            }
            
            
            
            // Select only valid location and also location with good accuracy
            if /*(newLocation != nil) && */(theAccuracy > 0) && (theAccuracy < 2000) && !((theLocation.latitude == 0.0) && (theLocation.longitude == 0.0)) {
                self.myLastLocation = theLocation
                self.myLastLocationAccuracy = theAccuracy
                
                let dict : NSMutableDictionary = NSMutableDictionary()
                dict.setObject(NSNumber(value: theLocation.latitude) as! Float, forKey: "latitude" as NSCopying)
                dict.setObject(NSNumber(value: theLocation.longitude) as! Float, forKey: "longitude" as NSCopying)
                dict.setObject(NSNumber(value: theAccuracy) as! Float, forKey: "theAccuracy" as NSCopying)
                dict.setObject(NSNumber(value: theAltitude), forKey: "theAltitude" as NSCopying)
                // Add the vallid location with good accuracy into an array
                // Every 1 minute, I will select the best location based on accuracy and send to server
                self.shareModel!.myLocationArray!.add(dict)
            }
        }
        // If the timer still valid, return it (Will not run the code below)
        if self.shareModel!.timer != nil {
            return
        }
        
        self.shareModel!.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        _ = self.shareModel!.bgTask!.beginNewBackgroundTask()
        
        // Restart the locationMaanger after 1 minute
        let restartLocationUpdates : Selector = #selector(LocationTracker.restartLocationUpdates)
        self.shareModel!.timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: restartLocationUpdates, userInfo: nil, repeats: false)
        
        // Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
        // The location manager will only operate for 10 seconds to save battery
        let stopLocationDelayBy10Seconds : Selector = #selector(LocationTracker.stopLocationDelayBy10Seconds)
        var delay10Seconds : Timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: stopLocationDelayBy10Seconds, userInfo: nil, repeats: false)
    }
    
    //MARK: Stop the locationManager
    func stopLocationDelayBy10Seconds() {
        let locationManager : CLLocationManager = LocationTracker.sharedLocationManager()!
        locationManager.stopUpdatingLocation()
        print("locationManager stop Updating after 10 seconds\n")
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
        
        switch (error.code) {
            
            
        case CLError.Code.network.rawValue:
            let alert : UIAlertView = UIAlertView(title: "Network Error", message: "Please check your network connection.", delegate: self, cancelButtonTitle: "OK")
            alert.show()
            break
        case CLError.Code.denied.rawValue:
            let alert : UIAlertView = UIAlertView(title: "Network Error", message: "Please check your network connection.", delegate: self, cancelButtonTitle: "OK")
            alert.show()
            break
        default:
            break
        }
        
    }
    
    func stopLocationTracking () {
        print("stopLocationTracking\n")
        
        if self.shareModel!.timer != nil {
            self.shareModel!.timer!.invalidate()
            self.shareModel!.timer = nil
        }
        let locationManager : CLLocationManager = LocationTracker.sharedLocationManager()!
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: Update location to server
    func updateLocationToServer() {
        print("updateLocationToServer\n")
        
        // Find the best location from the array based on accuracy
        var myBestLocation : NSMutableDictionary = NSMutableDictionary()
        
//        for (var i : Int = 0 ; i < self.shareModel!.myLocationArray!.count ; i += 1) {
        let count = self.shareModel!.myLocationArray!.count - 1
        for i in 0...count {
            let currentLocation : NSMutableDictionary = self.shareModel!.myLocationArray!.object(at: i) as! NSMutableDictionary
            if i == 0 {
                myBestLocation = currentLocation
            } else {
                if (currentLocation.object(forKey: ACCURACY) as! Float) <= (myBestLocation.object(forKey: ACCURACY) as! Float) {
                    myBestLocation = currentLocation
                }
            }
        }
        print("My Best location \(myBestLocation)\n")
        
        // If the array is 0, get the last location
        // Sometimes due to network issue or unknown reason,
        // you could not get the location during that period, the best you can do is
        // sending the last known location to the server
        
        if self.shareModel!.myLocationArray!.count == 0 {
            print("Unable to get location, use the last known location\n")
            self.myLocation = self.myLastLocation
            self.myLocationAcuracy = self.myLastLocationAccuracy
        } else {
            let lat : CLLocationDegrees = myBestLocation.object(forKey: LATITUDE) as! CLLocationDegrees
            let lon : CLLocationDegrees = myBestLocation.object(forKey: LONGITUDE) as! CLLocationDegrees
            let theBestLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self.myLocation = theBestLocation
            self.myLocationAcuracy = myBestLocation.object(forKey: ACCURACY) as! CLLocationAccuracy!
        }
        print("Send to server: latitude \((self.myLocation?.latitude)!) longitude \((self.myLocation?.longitude)!) accuracy \((self.myLocationAcuracy)!)\n")
        
        //TODO: Your code to send the self.myLocation and self.myLocationAccuracy to your server
        
        
        // After sending the location to the server successful,
        // remember to clear the current array with the following code. It is to make sure that you clear up old location in the array
        // and add the new locations from locationManager
        
        self.shareModel!.myLocationArray!.removeAllObjects()
        self.shareModel!.myLocationArray = nil
        self.shareModel!.myLocationArray = NSMutableArray()
    }
    
    func getBestLocationForServer()->NSDictionary? {
        print("getBestLocationForServer\n")
        
        // Find the best location from the array based on accuracy
        var myBestLocation : NSMutableDictionary = NSMutableDictionary()
        let count = self.shareModel!.myLocationArray!.count - 1
        for i in 0...count {
            let currentLocation : NSMutableDictionary = self.shareModel!.myLocationArray!.object(at: i) as! NSMutableDictionary
            if i == 0 {
                myBestLocation = currentLocation
            } else {
                if (currentLocation.object(forKey: ACCURACY) as! Float) <= (myBestLocation.object(forKey: ACCURACY) as! Float) {
                    myBestLocation = currentLocation
                }
            }
        }
        print("My Best location \(myBestLocation)\n")
        
        // If the array is 0, get the last location
        // Sometimes due to network issue or unknown reason,
        // you could not get the location during that period, the best you can do is
        // sending the last known location to the server
        
        if self.shareModel!.myLocationArray!.count == 0 {
            print("Unable to get location, use the last known location\n")
            self.myLocation = self.myLastLocation
            self.myLocationAcuracy = self.myLastLocationAccuracy
        } else {
            let lat : CLLocationDegrees = myBestLocation.object(forKey: LATITUDE) as! CLLocationDegrees
            let lon : CLLocationDegrees = myBestLocation.object(forKey: LONGITUDE) as! CLLocationDegrees
            let theBestLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self.myLocation = theBestLocation
            
            self.myLocationAcuracy = myBestLocation.object(forKey: ACCURACY) as! CLLocationAccuracy!
        }
        
        let returnType : NSMutableDictionary = NSMutableDictionary()
        returnType.setValue(self.myLocation?.latitude, forKey: "lat")
        returnType.setValue(self.myLocation?.longitude, forKey: "lon")
        returnType.setValue(self.myLocationAcuracy, forKey: "acc")
        
        
        print("Send to server: latitude \((self.myLocation?.latitude)!) longitude \((self.myLocation?.longitude)!) accuracy \((self.myLocationAcuracy)!)\n")
        
        //TODO: Your code to send the self.myLocation and self.myLocationAccuracy to your server
        
        
        // After sending the location to the server successful,
        // remember to clear the current array with the following code. It is to make sure that you clear up old location in the array
        // and add the new locations from locationManager
        
        self.shareModel!.myLocationArray!.removeAllObjects()
        self.shareModel!.myLocationArray = nil
        self.shareModel!.myLocationArray = NSMutableArray()
        return returnType
    }
    
}
