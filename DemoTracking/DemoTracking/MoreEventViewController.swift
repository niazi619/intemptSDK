//
//  MoreEventViewController.swift
//  DemoTracking
//
//  Created by MacBook on 15/11/2021.
//  Copyright © 2021 Intempt. All rights reserved.
//

import UIKit
import CountryPickerView

class MoreEventViewController: UIViewController {
    
    @IBOutlet weak var switchControl:UISwitch!
    @IBOutlet weak var customBtn:UIButton!
    @IBOutlet weak var segmentControl:UISegmentedControl!
    @IBOutlet weak var viewTouchable:UIView!
    @IBOutlet weak var lbl:UILabel!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var pickerViewList:UIPickerView!
    var countryPickerView: CountryPickerView!
    var responder:UIResponder!
    var controll:UIControl!
    let pickerDataList = ["Row1", "Row2", "Row3", "Row4", "Row5"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pickerViewList.dataSource = self
        pickerViewList.delegate = self
        
        countryPickerView = CountryPickerView()
        countryPickerView.delegate = self
        
    }
    
    @IBAction func goBackPressed(){
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func switchControllValueChanged(_ sender:UISwitch){
        
    }
    @IBAction func customBtnTapped(_ sender:UIButton){
        
    }
    @IBAction func filledBtnTapped(_ sender:UIButton){
        
    }
    @IBAction func defaultBtnTapped(_ sender:UIButton){
        
    }
    @IBAction func tintBtnTapped(_ sender:UIButton){
        
    }
    @IBAction func segementValueTapped(_ sender:UISegmentedControl){
        
    }
    @IBAction func sliderValueTapped(_ sender:UISegmentedControl){
        
    }
    @IBAction func steperValueTapped(_ sender:UISegmentedControl){
        
    }
    @IBAction func dateChanged(_ sender:UIDatePicker){
        print(sender.date)
    }
    @IBAction func podTestWithCountryPicker(){
        countryPickerView.showCountriesList(from: self)
    }

}

extension MoreEventViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataList.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        return pickerDataList[row]
    }
}

extension MoreEventViewController: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        print(country)
    }
}
