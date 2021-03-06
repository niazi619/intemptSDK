//
//  ViewController.swift
//  eeeq
//
//  Created by Tanay Bhattacharjee on 18/03/20.
//  Copyright © 2020 Tanay Bhattacharjee. All rights reserved.
//

import UIKit
import Intempt
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet var emailTxt: UITextField!
    @IBOutlet var pwdTxt: UITextField!
    @IBOutlet var tanay: UIButton!
    @IBOutlet var lbl: UILabel!
    @IBOutlet var switchTracking: UISwitch!
    @IBOutlet var lblTracking: UILabel!
    @IBOutlet var switchLogging: UISwitch!
    @IBOutlet var lblLogging: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateTrackingStatus()
        self.updateLoggingStatus()
    }
    
    @IBAction func ButtonPressed( sender: AnyObject? ) {
        
        if emailTxt.text == "" {
            self.showAlertWithOneAction(title:
                "Alert", actionTtitle: "Ok", style: .cancel, actionMethod: {
                    
            }, message: "Enter Your EmailId")
        }
        else if !self.isValidEmail(testStr: emailTxt.text!) {
            self.showAlertWithOneAction(title:
                "Alert", actionTtitle: "Ok", style: .cancel, actionMethod: {
                    
            }, message: "Not Valid Email Address. Email address should have @ symbol.")
        }
        else if pwdTxt.text == "" {
            
            self.showAlertWithOneAction(title:
                "Alert", actionTtitle: "Ok", style: .cancel, actionMethod: {
                    
            }, message: "Enter Your Password")
        }
        else if  pwdTxt.text == "123456" {
            
            //identify visitor
            IntemptTracker.identify("\(emailTxt.text!)", withProperties: nil) { (status, result, error) in
                if(status) {
                    NSLog("identify successful")
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

            let nextVC =  self.storyboard?.instantiateViewController(identifier: "nextVC") as! NextViewController
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
        else {
            self.showAlertWithOneAction(title:
                "Alert", actionTtitle: "Ok", style: .cancel, actionMethod: {
                    
            }, message: "Your email or Password not match.")
        }
    }
    
    @IBAction func showMoreEventsScreen(_ sender:UIButton){
        let nextVC =  self.storyboard?.instantiateViewController(identifier: "MoreEventViewController") as! MoreEventViewController
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
    @IBAction func enableDisableTracking(){
        if(IntemptClient.isTrackingEnabled()){
            IntemptClient.disableTracking()
        }else{
            IntemptClient.enableTracking()
        }
        self.updateTrackingStatus()
    }
    func updateTrackingStatus(){
        if(IntemptClient.isTrackingEnabled()){
            lblTracking.text = "Tracking Enabled"
            switchTracking.isOn = true
        }else{
            lblTracking.text = "Tracking Disabled"
            switchTracking.isOn = false
        }
    }
    @IBAction func enableDisableLogging(){
        if(IntemptClient.isLoggingEnabled()){
            IntemptClient.disableLogging()
        }else{
            IntemptClient.enableLogging()
        }
        self.updateLoggingStatus()
    }
    @IBAction func enableLocation(){
        LocationsManager.sharedInstance.startGtettingLocation()
    }
    func updateLoggingStatus(){
        if(IntemptClient.isLoggingEnabled()){
            lblLogging.text = "Logging Enabled"
            switchLogging.isOn = true
        }else{
            lblLogging.text = "Logging Disabled"
            switchLogging.isOn = false
        }
    }
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
}


