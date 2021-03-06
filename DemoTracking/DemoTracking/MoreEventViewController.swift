//
//  MoreEventViewController.swift
//  DemoTracking
//
//  Created by MacBook on 15/11/2021.
//  Copyright © 2021 Intempt. All rights reserved.
//

import UIKit
import CountryPickerView
import CoreLocation
import CoreLocationUI

class MoreEventViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var switchControl:UISwitch!
    @IBOutlet weak var customBtn:UIButton!
    @IBOutlet weak var segmentControl:UISegmentedControl!
    @IBOutlet weak var viewTouchable:UIView!
    @IBOutlet weak var lbl:UILabel!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var pickerViewList:UIPickerView!
    @IBOutlet weak var viewLocationButton:UIView!
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
        
        
        if #available(iOS 15.0, *) {
            let locationButton = CLLocationButton()
            locationButton.frame = viewLocationButton.bounds
            locationButton.label = .currentLocation
            viewLocationButton.addSubview(locationButton)
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
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
    @IBAction func navigationControl(){
        let customVC =  self.storyboard?.instantiateViewController(identifier: "NavigationControllerViewController") as! NavigationControllerViewController
        self.navigationController?.pushViewController(customVC, animated: true)
    }
    @IBAction func pageViewController(){
        let vcnt = MySwipeVC()
        self.navigationController?.pushViewController(vcnt, animated: true)
    }

    @IBAction func attributatedBtnPressed(_ sender:UIButton){
        
    }
    @IBAction func barItemPressed(_ sender:UIBarItem){
        
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
extension MoreEventViewController: UISearchBarDelegate {

      func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if searchBar.text?.isEmpty == false {
            // This avoids the text being stretched by the UISearchBar.
            searchBar.setShowsCancelButton(true, animated: true)
        }
        return true
    }

}
