//
//  MySwipeVC.swift
//  DemoTracking
//
//  Created by MacBook on 17/11/2021.
//  Copyright © 2021 Intempt. All rights reserved.
//

import UIKit
import EZSwipeController

// import EZSwipeController // if using CocoaPods
class MySwipeVC: EZSwipeController {
    override func setupView() {
        datasource = self
        self.navigationController?.isNavigationBarHidden = false
        APP_DELEGATE.delay(5){
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension MySwipeVC: EZSwipeControllerDataSource {
    func viewControllerData() -> [UIViewController] {
        let redVC = UIViewController()
        redVC.view.backgroundColor = UIColor.red
        
        let blueVC = UIViewController()
        blueVC.view.backgroundColor = UIColor.blue
        
        let greenVC = UIViewController()
        greenVC.view.backgroundColor = UIColor.green
        
        return [redVC, blueVC, greenVC]
    }
}
