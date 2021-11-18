//
//  CustomEventViewController.swift
//  DemoTracking
//
//  Created by Tanay Bhattacharjee on 10/04/20.
//  Copyright © 2020 Tanay Bhattacharjee. All rights reserved.
//

import UIKit
import Intempt

class CustomEventViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func back( sender: AnyObject? ) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func payment( sender: AnyObject? ) {
        
        let dic1 = NSMutableDictionary()
        dic1.setValue("2", forKey: "bookingId");
        dic1.setValue("1", forKey: "flightId");
        dic1.setValue("booked", forKey: "bookingStatus");
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dic1.setValue(dateFormatter.string(from:Date()), forKey: "bookingDate");
        
        
        let arrData = NSArray(object: dic1)
        print(arrData)
        
        //CustomEvent
        IntemptTracker.track("flight-booking", withProperties: arrData as? [Any]) { (status, result, error) in
            if(status) {
                if let dictResult = result as? [String: Any] {
                    print(dictResult)
                }
            }
            else {
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
        
    }
}
