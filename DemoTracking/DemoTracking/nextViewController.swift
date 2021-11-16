//
//  NextViewController.swift
//  DemoTracking
//
//  Created by Tanay Bhattacharjee on 04/04/20.
//  Copyright © 2020 Tanay Bhattacharjee. All rights reserved.
//

import UIKit

class NextViewController: UIViewController {
    @IBOutlet var img: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func clickValuechange( sender: AnyObject? ) {
        if sender?.tag == 0 {
            self.img.image = UIImage.init(named: "1.jpeg")
        }
        else  if sender?.tag == 1 {
            self.img.image = UIImage.init(named: "2.jpeg")
        }
        else{
            self.img.image = UIImage.init(named: "3.jpeg")
        }
        
    }
    
    
    @IBAction func back( sender: AnyObject? ) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func clickcustomEvent( sender: AnyObject? ) {
        let customVC =  self.storyboard?.instantiateViewController(identifier: "customVC") as! CustomEventViewController
        self.navigationController?.pushViewController(customVC, animated: true)
    }
    @IBAction func showMoreEventsScreen(_ sender:UIButton){
        let nextVC =  self.storyboard?.instantiateViewController(identifier: "MoreEventViewController") as! MoreEventViewController
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
    
}
