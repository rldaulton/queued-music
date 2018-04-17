//
//  SettingViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import PKHUD
import AlamofireImage
import HNKGooglePlacesAutocomplete

protocol AddressDataSourceDelegate: class {
    func dataSourceDidCompleteLoad(_ dataSource: AddressDataSource, addresses: [Address]?)
}

protocol AddressConfigurable {
    func configure(with address: Address?)
}

protocol AddressCellConfigurable: AddressConfigurable {
    var addressLabel: UILabel! { get set }
}

extension AddressCellConfigurable {
    func configure(with address: Address?) {
        addressLabel.text = address?.address?.name
    }
}

extension AddressCell: AddressCellConfigurable { }

class AddressDataSource: NSObject, UITableViewDataSource {
    weak var delegate: AddressDataSourceDelegate?
    var addresses: [Address] = []
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath) as! AddressCell
        
        let address = addresses[indexPath.item]
        cell.configure(with: address)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.addresses.count
    }
}

class NewVenueViewController : BaseViewController {
    
    private var containedController: UIViewController?
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var venueNameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var addressTableView: UITableView!
    
    let dataSource = AddressDataSource()
    
    var latitude: Float?
    var longitude: Float?
    var currentAddress: HNKGooglePlacesAutocompletePlace!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        containedController = self;
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: view.window)
  
        self.venueNameTextField.attributedPlaceholder = NSAttributedString(string: "Venue Name",
                                                                           attributes: [NSForegroundColorAttributeName: UIColor.gray])
        
        self.addressTextField.attributedPlaceholder = NSAttributedString(string: "Address of Venue",
                                                                           attributes: [NSForegroundColorAttributeName: UIColor.gray])
        
        dataSource.delegate = self
        addressTableView.dataSource = dataSource
        addressTableView.tableFooterView = UIView()
        addressTableView.isHidden = true
        self.addressTableView.delegate = self
        
        self.latitude = 0
        self.longitude = 0
        
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        
        if let imageUrl = currentUser.photoUrl {
            if imageUrl != "" {
                let urlRequest = URLRequest(url: URL(string: imageUrl)!)
                if let image = ImageDownloader.default.imageCache?.image(for: urlRequest, withIdentifier: imageUrl) {
                    userImageView.image = image
                } else {
                    ImageDownloader.default.download(urlRequest) { (response) in
                        if let image = response.result.value {
                            ImageDownloader.default.imageCache?.add(image, for: urlRequest, withIdentifier: imageUrl)
                            self.userImageView.image = image
                        }
                    }
                }
            }
        }
        
        self.userNameLabel.text = currentUser.userName
        
        self.venueNameTextField.delegate = self
        self.addressTextField.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func nextButton(_ sender: Any) {
        self.addressTextField.resignFirstResponder()
        self.venueNameTextField.resignFirstResponder()
        self.addressTableView.isHidden = true
        
        if self.venueNameTextField.text == "" {
            let alertView = AlertView(title: "Error", message: "Please type venue name.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            return
        }
        
        if self.addressTextField.text == "" {
            let alertView = AlertView(title: "Error", message: "Please type venue address.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            return
        }
        
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        
        CLPlacemark.hnk_placemark(fromGooglePlace: self.currentAddress, apiKey: "my-google-places-api-key", completion: { (placemark, addressString, error) in
            if error == nil {
                self.latitude = Float((placemark?.location?.coordinate.latitude)!)
                self.longitude = Float((placemark?.location?.coordinate.longitude)!)
                
                self.registerVenue()
            } else {
                PKHUD.sharedHUD.hide()
                
                let alertView = AlertView(title: "Error", message: "Please type valid venue address.", okButtonTitle: "OK", cancelButtonTitle: nil)
                self.present(customModalViewController: alertView, centerYOffset: 0)
                
                return
            }
        })

    }
    
    func registerVenue() {
        let currentUser = UserDataModel.shared.currentUser()
        
        let venue = Venue(adminId: currentUser?.userId, latitude: self.latitude, longitude: self.longitude, created: Date(), name: self.venueNameTextField.text)
        
        VenueDataModel.shared.addVenue(newVenue: venue) { (error, key) in
            PKHUD.sharedHUD.hide()
            
            if error == nil {
                UserDataModel.shared.storeEscrowSetupStatus(status: true)
                
                self.performSegue(withIdentifier: "onboardingStartController", sender: self)
            } else {
                let alertView = AlertView(title: "Error", message: error?.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                self.present(customModalViewController: alertView, centerYOffset: 0)
            }
        }
    }
    
    func keyboardWillShow(_ notification: Notification) {
        if self.venueNameTextField.isFocused == true {
            return
        }
        
        guard let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber,
            let containedController = containedController else {
                return
        }
        
        containedController.view.backgroundColor = #colorLiteral(red: 0.1490196078, green: 0.2274509804, blue: 0.2784313725, alpha: 1)
        self.view.backgroundColor = #colorLiteral(red: 0.1490196078, green: 0.2274509804, blue: 0.2784313725, alpha: 1)
        let center = containedController.view
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0.0, options: UIViewAnimationOptions(rawValue: animationCurve.uintValue), animations: {
            if center?.frame.origin.y == 0 {
                center?.frame.origin.y  = -200
            } else {
                center?.frame.origin.y  = -400
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
            center?.frame.origin.y = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

extension NewVenueViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.venueNameTextField {
            self.venueNameTextField.resignFirstResponder()
            self.addressTextField.becomeFirstResponder()
        } else if textField == self.addressTextField {
            self.addressTextField.resignFirstResponder()
            self.addressTableView.isHidden = true
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.addressTextField {
            let str = NSString(string: textField.text ?? "").replacingCharacters(in: range, with: string)
            if str.characters.count >= 2 {
                HNKGooglePlacesAutocompleteQuery.shared().fetchPlaces(forSearch: str) { (places, error) in
                    
                    if let places = places as? [HNKGooglePlacesAutocompletePlace], error == nil {
                        if places.count > 0 {
                            self.dataSource.addresses.removeAll()
                            
                            for place in places {
                                let address = Address(address: place, latitude: 0, longitude: 0)
                                self.dataSource.addresses.append(address!)
                            }
                            
                            self.addressTableView.reloadData()
                            self.addressTableView.isHidden = false
                        } else {
                            self.addressTableView.isHidden = true
                        }
                    } else {
                        // print(error?.localizedDescription)
                    }
                }
            } else {
                self.addressTableView.isHidden = true
            }
        }
        return true
    }
}

extension NewVenueViewController: AddressDataSourceDelegate {
    func dataSourceDidCompleteLoad(_ dataSource: AddressDataSource, addresses: [Address]?) {
        
    }
}

extension NewVenueViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = self.dataSource.addresses[indexPath.item]
        
        self.addressTextField.text = address.address?.name
        
        self.addressTextField.resignFirstResponder()
        self.addressTableView.isHidden = true
        
        self.currentAddress = address.address
    }
}

