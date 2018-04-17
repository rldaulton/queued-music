//
//  AlertView.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import CoreLocation
import HNKGooglePlacesAutocomplete
import PKHUD

@objc protocol VenueViewDelegate: NSObjectProtocol {
    @objc optional func onUpdateButtonClicked(sender: VenueView)
}

class VenueView: UIViewController {

    private var containedController: UIViewController?
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var clearNameButton: UIButton!
    @IBOutlet weak var clearAddressButton: UIButton!
    @IBOutlet weak var addressTableView: UITableView!
    
    @IBOutlet weak var updateButtonLeftConstraint: NSLayoutConstraint!
    
    public static var mainView: MainView? = nil
    
    weak var delegate: VenueViewDelegate?
    
    //let dataSource = AddressDataSource()
    var addresses: [Address] = []
    
    var originName: String = ""
    var originAddress: String = ""
    
    var originY : CGFloat = 0.0
    
    var isFirst : Bool = false
    
    var currentAddress: HNKGooglePlacesAutocompletePlace!
    
    init() {
        super.init(nibName: "VenueView", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.containedController = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: view.window)
        
        self.nameField.delegate = self
        self.addressField.delegate = self
        self.updateButton.isEnabled = false
        
        self.isFirst = false
        
        //dataSource.delegate = self
        //addressTableView.dataSource = dataSource
        addressTableView.dataSource = self
        addressTableView.isHidden = true
        self.addressTableView.delegate = self
        self.addressTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        setup()
    }

    func setup() {
        self.originName = VenueDataModel.shared.currentVenue.name ?? ""
        self.originAddress = ""
        self.nameField.text = self.originName
        self.addressField.text = self.originAddress
        
        self.clearNameButton.isHidden = self.nameField.text == ""
        self.clearAddressButton.isHidden = self.addressField.text == ""
        
        let location = CLLocation(latitude: Double(VenueDataModel.shared.currentVenue.latitude!), longitude: Double(VenueDataModel.shared.currentVenue.longitude!))
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in

            if error != nil {
                print("Error fetching error")
                return
            }
            
            if (placemarks?.count)! > 0 {
                let pm = placemarks![0]
                if let lines = pm.addressDictionary?["FormattedAddressLines"] as? [String] {
                    HNKGooglePlacesAutocompleteQuery.shared().fetchPlaces(forSearch: lines.joined(separator: ", ")) { (places, error) in
                        
                        if let places = places as? [HNKGooglePlacesAutocompletePlace], error == nil {
                            if places.count > 0 {
                                for place in places {
                                    let address = Address(address: place, latitude: 0, longitude: 0)
                                    self.currentAddress = address?.address
                                    
                                    self.originAddress = (address?.address?.name)!
                                    self.addressField.text = self.originAddress
                                    self.clearAddressButton.isHidden = self.addressField.text == ""
                                    
                                    break
                                }
                            }
                        }
                    }
                }
            }
            else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    func keyboardWillShow(_ notification: Notification) {
        guard let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber,
            let containedController = containedController else {
                return
        }
        
        containedController.view.backgroundColor = #colorLiteral(red: 0.1490196078, green: 0.2274509804, blue: 0.2784313725, alpha: 1)
        self.view.backgroundColor = #colorLiteral(red: 0.1490196078, green: 0.2274509804, blue: 0.2784313725, alpha: 1)
        let center = containedController.view
        
        if self.originY == 0.0 {
            self.originY = (center?.frame.origin.y)!
        }
        
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0.0, options: UIViewAnimationOptions(rawValue: animationCurve.uintValue), animations: {
            if self.isFirst == false {
                center?.frame.origin.y = self.originY - 200
            }
            
            self.view.layoutIfNeeded()
        }, completion: nil)
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        guard let containedController = containedController,
            let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        let center = containedController.view
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0.0, options: UIViewAnimationOptions(rawValue: animationCurve.uintValue), animations: {
            center?.frame.origin.y = self.originY
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @IBAction func onUpdate(_ sender: Any) {
        if self.nameField.text == "" {
            let alertView = AlertView(title: "Error", message: "Please type venue name.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            return
        }
        
        if self.addressField.text == "" {
            let alertView = AlertView(title: "Error", message: "Please type venue address.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            return
        }
        
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        
        CLPlacemark.hnk_placemark(fromGooglePlace: self.currentAddress, apiKey: "my-google-places-api-key", completion: { (placemark, addressString, error) in
            if error == nil {
                let latitude = Float((placemark?.location?.coordinate.latitude)!)
                let longitude = Float((placemark?.location?.coordinate.longitude)!)
                
                VenueDataModel.shared.updateVenue(venueId: VenueDataModel.shared.currentVenue.venueId, name: self.nameField.text, latitude: latitude, longitude: longitude, completion: { (error) in
                    PKHUD.sharedHUD.hide()
                    let venue = VenueDataModel.shared.currentVenue
                    venue?.name = self.nameField.text
                    venue?.latitude = latitude
                    venue?.longitude = longitude
                    VenueDataModel.shared.currentVenue = venue
                    
                    VenueView.mainView?.updateVenueNameLabel(name: self.nameField.text!)
                    
                    self.dismiss(animated: true, completion: {
                        self.delegate?.onUpdateButtonClicked?(sender: self)
                    })
                })
            } else {
                PKHUD.sharedHUD.hide()
                
                let alertView = AlertView(title: "Error", message: "Please type valid venue address.", okButtonTitle: "OK", cancelButtonTitle: nil)
                self.present(customModalViewController: alertView, centerYOffset: 0)
                
                return
            }
        })
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true) {
            
        }
    }
    
    @IBAction func clearNameField(_ sender: Any) {
        self.nameField.text = ""
        self.clearNameButton.isHidden = true
        
        if self.addressField.text != self.originAddress || self.nameField.text != self.originName {
            self.updateButton.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0.8235294118, blue: 0.3843137255, alpha: 1)
            self.updateButton.isEnabled = true
        } else {
            self.updateButton.backgroundColor = #colorLiteral(red: 0.6274509804, green: 0.6431372549, blue: 0.6509803922, alpha: 1)
            self.updateButton.isEnabled = false
        }
    }
    
    @IBAction func clearAddressField(_ sender: Any) {
        self.addressField.text = ""
        self.clearAddressButton.isHidden = true
        
        if self.addressField.text != self.originAddress || self.nameField.text != self.originName {
            self.updateButton.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0.8235294118, blue: 0.3843137255, alpha: 1)
            self.updateButton.isEnabled = true
        } else {
            self.updateButton.backgroundColor = #colorLiteral(red: 0.6274509804, green: 0.6431372549, blue: 0.6509803922, alpha: 1)
            self.updateButton.isEnabled = false
        }
    }
}

extension VenueView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.nameField {
            self.nameField.resignFirstResponder()
            self.addressField.becomeFirstResponder()
        }
        
        if textField == self.addressField {
            self.addressField.resignFirstResponder()
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.clearNameButton.isHidden = self.nameField.text == ""
        self.clearAddressButton.isHidden = self.addressField.text == ""
        
        let str = NSString(string: textField.text ?? "").replacingCharacters(in: range, with: string)
        
        if textField == self.addressField {
            if str != self.originAddress || self.nameField.text != self.originName {
                self.updateButton.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0.8235294118, blue: 0.3843137255, alpha: 1)
                self.updateButton.isEnabled = true
            } else {
                self.updateButton.backgroundColor = #colorLiteral(red: 0.6274509804, green: 0.6431372549, blue: 0.6509803922, alpha: 1)
                self.updateButton.isEnabled = false
            }
            
            if str.characters.count >= 2 {
                HNKGooglePlacesAutocompleteQuery.shared().fetchPlaces(forSearch: str) { (places, error) in
                    
                    if let places = places as? [HNKGooglePlacesAutocompletePlace], error == nil {
                        if places.count > 0 {
                            self.addresses.removeAll()
                            
                            for place in places {
                                let address = Address(address: place, latitude: 0, longitude: 0)
                                self.addresses.append(address!)
                            }
                            
                            self.addressTableView.reloadData()
                            self.addressTableView.isHidden = false
                        } else {
                            self.addressTableView.isHidden = true
                        }
                    }
                }
            } else {
                self.addressTableView.isHidden = true
            }
        } else if textField == self.nameField {
            if self.addressField.text != self.originAddress || str != self.originName {
                self.updateButton.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0.8235294118, blue: 0.3843137255, alpha: 1)
                self.updateButton.isEnabled = true
            } else {
                self.updateButton.backgroundColor = #colorLiteral(red: 0.6274509804, green: 0.6431372549, blue: 0.6509803922, alpha: 1)
                self.updateButton.isEnabled = false
            }
        }
        
        return true
    }
 
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.nameField {
            self.isFirst = true
        } else {
            self.isFirst = false
        }
        return true
    }
}

extension VenueView: AddressDataSourceDelegate {
    func dataSourceDidCompleteLoad(_ dataSource: AddressDataSource, addresses: [Address]?) {
        
    }
}

extension VenueView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = self.addresses[indexPath.item]
        
        self.addressField.text = address.address?.name
        
        self.addressField.resignFirstResponder()
        self.addressTableView.isHidden = true
        
        self.currentAddress = address.address
    }
}

extension VenueView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UITableViewCell
        let cell:UITableViewCell = self.addressTableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        
        let address = addresses[indexPath.item]
        
        cell.textLabel?.text = address.address?.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.addresses.count
    }
}
