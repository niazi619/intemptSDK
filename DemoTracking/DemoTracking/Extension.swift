//
//  Extension.swift
//  eeeq
//
//  Created by Tanay Bhattacharjee on 18/03/20.
//  Copyright © 2020 Tanay Bhattacharjee. All rights reserved.
//
import Foundation
import UIKit

extension UIColor {
    
    static var lightOrange :UIColor{
        return UIColor.black
    }
    
    static var orangeBorder :UIColor{
        return UIColor.cyan
        
    }
    
    static var deepOrange :UIColor{
        return UIColor.red
    }
    
    static var placeHolderColor:UIColor{
        return UIColor(red: 0.57, green: 0.57, blue: 0.57, alpha: 1)
    }
    
    static var orangeTextColor :UIColor{
        return UIColor(red: 1, green: 0.44, blue: 0, alpha: 1)
    }
    
    static var lightGrayInApp :UIColor{
        return UIColor(red: 0.91, green: 0.92, blue: 0.93, alpha: 1)
    }
    
    static var reddishGrayInApp :UIColor{
        return UIColor(red: 245/255, green: 242/255, blue: 237/255, alpha: 1)
    }
    
    static var separatorColor: UIColor{
        return UIColor(red: 235/255, green: 235/255, blue: 236/255, alpha: 1)
    }
    
    static var selectedTabBarItem: UIColor{
        return UIColor(red: 1, green: 0.44, blue: 0, alpha: 1)
    }
    
    static var unselectedTabBarItem: UIColor{
        return UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
    }
    
    
    convenience init(hex:String) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            self.init(red: 0, green: 0, blue: 0, alpha: 1)
            return
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    
    
}



extension UIViewController{
    
    func  showAlertWithOneAction(title:String, actionTtitle: String, style: UIAlertAction.Style, actionMethod: @escaping () -> Void , message:String){
        DispatchQueue.main.async(execute: {() -> Void in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: actionTtitle, style: style, handler: { action in
                switch action.style{
                case .default:
                    actionMethod()
                case .cancel:
                    actionMethod()
                case .destructive:
                    actionMethod()
                }
            }))
            
            if let presentedVC = self.presentedViewController, presentedVC is UIAlertController {
                presentedVC.dismiss(animated: true, completion: {
                    self.present(alert, animated: true, completion: nil)
                })
            }
            else {
                self.present(alert, animated: true, completion: nil)
            }
            
        })
    }
    
    
    func  showAlertWithTwoAction(title:String, actionTtitle1: String, style1: UIAlertAction.Style, firstActionMethod: @escaping () -> Void, actionTtitle2: String, style2: UIAlertAction.Style, secondActionMethod: @escaping () -> Void ,  message:String){
        DispatchQueue.main.async(execute: {() -> Void in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: actionTtitle1, style: style1, handler: { action in
                switch action.style{
                case .default:
                    firstActionMethod()
                case .cancel:
                    firstActionMethod()
                case .destructive:
                    firstActionMethod()
                }
            }))
            
            alert.addAction(UIAlertAction(title: actionTtitle2, style: style2, handler: { action in
                switch action.style{
                case .default:
                    secondActionMethod()
                case .cancel:
                    secondActionMethod()
                case .destructive:
                    secondActionMethod()
                }
            }))
            
            if let presentedVC = self.presentedViewController, presentedVC is UIAlertController {
                presentedVC.dismiss(animated: true, completion: {
                    self.present(alert, animated: true, completion: nil)
                })
            }
            else {
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    
    func  showAlertWithThreeAction(title:String, actionTtitle1: String, style1: UIAlertAction.Style, firstActionMethod: @escaping () -> Void, actionTtitle2: String, style2: UIAlertAction.Style, secondActionMethod: @escaping () -> Void ,  actionTtitle3: String, style3: UIAlertAction.Style, thirdActionMethod: @escaping () -> Void ,  message:String){
        DispatchQueue.main.async(execute: {() -> Void in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: actionTtitle1, style: style1, handler: { action in
                switch action.style{
                case .default:
                    firstActionMethod()
                case .cancel:
                    firstActionMethod()
                case .destructive:
                    firstActionMethod()
                }
            }))
            
            alert.addAction(UIAlertAction(title: actionTtitle2, style: style2, handler: { action in
                switch action.style{
                case .default:
                    secondActionMethod()
                case .cancel:
                    secondActionMethod()
                case .destructive:
                    secondActionMethod()
                }
            }))
            
            alert.addAction(UIAlertAction(title: actionTtitle3, style: style3, handler: { action in
                switch action.style{
                case .default:
                    thirdActionMethod()
                case .cancel:
                    thirdActionMethod()
                case .destructive:
                    thirdActionMethod()
                }
            }))
            
            
            
            
            if let presentedVC = self.presentedViewController, presentedVC is UIAlertController {
                presentedVC.dismiss(animated: true, completion: {
                    self.present(alert, animated: true, completion: nil)
                })
            }
            else {
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    
}



extension String{
    func numberValidator() -> Bool {
        let validators = "^[0-9\\s]+$"
        let test = NSPredicate(format: "SELF MATCHES %@", validators)
        let result = test.evaluate(with: self)
        return result
    }
    
    
}

