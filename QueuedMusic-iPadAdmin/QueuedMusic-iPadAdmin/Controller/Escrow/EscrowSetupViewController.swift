//
//  SettingViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import PKHUD

class EscrowSetupViewController : BaseViewController {

    @IBOutlet weak var firstNameView: EscrowTextView!
    @IBOutlet weak var lastNameView: EscrowTextView!
    @IBOutlet weak var birthMonthView: EscrowTextView!
    @IBOutlet weak var birthDateView: EscrowTextView!
    @IBOutlet weak var birthYearView: EscrowTextView!
    @IBOutlet weak var ssnView: EscrowTextView!
    @IBOutlet weak var legalFullNameView: EscrowTextView!
    @IBOutlet weak var legalTaxView: EscrowTextView!
    @IBOutlet weak var address1View: EscrowTextView!
    @IBOutlet weak var address2View: EscrowTextView!
    @IBOutlet weak var cityView: EscrowTextView!
    @IBOutlet weak var stateView: EscrowTextView!
    @IBOutlet weak var zipView: EscrowTextView!
    @IBOutlet weak var emailView: EscrowTextView!
    @IBOutlet weak var accountHolderView: EscrowTextView!
    @IBOutlet weak var accountRoutingView: EscrowTextView!
    @IBOutlet weak var accountNumberView: EscrowTextView!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var tooltip1View: UIView!
    @IBOutlet weak var tooltip2View: UIView!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var settingTitleView: UIView!
    
    var isTermsChecked: Bool!
    var ipAddress: String!
    
    public static var isEscrowSetting: Bool! = false
    public static var homeViewController: HomeViewController! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.firstNameView.initView(controller: self, tag: 0)
        self.lastNameView.initView(controller: self, tag: 1)
        self.birthMonthView.initView(controller: self, tag: 2)
        self.birthDateView.initView(controller: self, tag: 3)
        self.birthYearView.initView(controller: self, tag: 4)
        self.ssnView.initView(controller: self, tag: 5)
        self.legalFullNameView.initView(controller: self, tag: 6)
        self.legalTaxView.initView(controller: self, tag: 7)
        self.address1View.initView(controller: self, tag: 8)
        self.address2View.initView(controller: self, tag: 9)
        self.cityView.initView(controller: self, tag: 10)
        self.stateView.initView(controller: self, tag: 11)
        self.zipView.initView(controller: self, tag: 12)
        self.emailView.initView(controller: self, tag: 13)
        self.accountHolderView.initView(controller: self, tag: 14)
        self.accountRoutingView.initView(controller: self, tag: 15)
        self.accountNumberView.initView(controller: self, tag: 16)
        
        self.accountHolderView.textField.isEnabled = false
        
        self.isTermsChecked = false
        
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: "Stripe Connected Account Agreement", attributes: underlineAttribute)
        self.termsButton.setAttributedTitle(underlineAttributedString, for: UIControlState.normal)
        self.termsButton.titleLabel?.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        self.tooltip1View.isHidden = true
        self.tooltip2View.isHidden = true
        
        var arr : [String] = self.getIFAddresses()
        
        if arr != nil && arr.count > 0 {
            self.ipAddress = arr[arr.count - 1]
        } else {
            self.ipAddress = ""
        }
        
        self.settingTitleView.isHidden = !EscrowSetupViewController.isEscrowSetting
        
        let gestureSwift2AndHigher = UITapGestureRecognizer(target: self, action:  #selector (self.viewTouchAction (_:)))
        self.view.addGestureRecognizer(gestureSwift2AndHigher)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func finishButtonClicked(_ sender: Any) {
        
        self.updateAccountHolderName()
        self.tooltip2View.isHidden = true
        self.tooltip1View.isHidden = true
        
        var valid = true
        
        if self.firstNameView.textField.text == "" {
            self.firstNameView.validStatus(status: false)
            valid = false
        }
        
        if self.lastNameView.textField.text == "" {
            self.lastNameView.validStatus(status: false)
            valid = false
        }
        
        if self.birthMonthView.textField.text == "" {
            self.birthMonthView.validStatus(status: false)
            valid = false
        }
        
        if self.birthDateView.textField.text == "" {
            self.birthDateView.validStatus(status: false)
            valid = false
        }
        
        if self.birthYearView.textField.text == "" {
            self.birthYearView.validStatus(status: false)
            valid = false
        }
        
        if self.ssnView.textField.text == "" {
            self.ssnView.validStatus(status: false)
            valid = false
        }
        
        if self.legalFullNameView.textField.text == "" {
            self.legalFullNameView.validStatus(status: false)
            valid = false
        }
        
        if self.legalTaxView.textField.text == "" {
            self.legalTaxView.validStatus(status: false)
            valid = false
        }
        
        if self.address1View.textField.text == "" {
            self.address1View.validStatus(status: false)
            valid = false
        }
        
        if self.cityView.textField.text == "" {
            self.cityView.validStatus(status: false)
            valid = false
        }
        
        if self.stateView.textField.text == "" {
            self.stateView.validStatus(status: false)
            valid = false
        }
        
        if self.zipView.textField.text == "" {
            self.zipView.validStatus(status: false)
            valid = false
        }
        
        if self.accountHolderView.textField.text == "" {
            self.accountHolderView.validStatus(status: false)
            valid = false
        }
        
        if self.accountRoutingView.textField.text == "" {
            self.accountRoutingView.validStatus(status: false)
            valid = false
        }
        
        if self.accountNumberView.textField.text == "" {
            self.accountNumberView.validStatus(status: false)
            valid = false
        }
        
        if self.isTermsChecked == false {
            let alertView = AlertView(title: "Error", message: "Please check Stripe Connected Accoung Agreement", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            valid = false
        }
        
        if valid == false {
            return
        }
        
        if (self.legalFullNameView.textField.text?.characters.count)! > 80 {
            let alertView = AlertView(title: "Error", message: "Business Full Legal Name should be less than 80 characters.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            self.legalFullNameView.validStatus(status: false)
            return
        }
        
        if self.emailView.textField.text != "" && self.isValidEmail(testStr: self.emailView.textField.text!) == false {
            let alertView = AlertView(title: "Error", message: "Invalid email address.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            self.emailView.validStatus(status: false)
            return
        }
        
        var num = Int(self.accountNumberView.textField.text!)
        if self.accountNumberView.textField.text?.characters.count != 12 || num == nil {
            let alertView = AlertView(title: "Error", message: "Account Number should be a 12-digit number.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            self.accountNumberView.validStatus(status: false)
            return
        }
        
        num = Int(self.accountRoutingView.textField.text!)
        if self.accountRoutingView.textField.text?.characters.count != 9 || num == nil {
            let alertView = AlertView(title: "Error", message: "Account Routing Number should be a 9-digit number.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            self.accountRoutingView.validStatus(status: false)
            return
        }
        
        num = Int(self.legalTaxView.textField.text!)
        if self.legalTaxView.textField.text?.characters.count != 9 || num == nil {
            let alertView = AlertView(title: "Error", message: "Business Tax ID should be a 9-digit number.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            self.legalTaxView.validStatus(status: false)
            return
        }
        
        num = Int(self.ssnView.textField.text!)
        if self.ssnView.textField.text?.characters.count != 9 || num == nil {
            let alertView = AlertView(title: "Error", message: "Social security number should be a 9-digit number.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            self.ssnView.validStatus(status: false)
            return
        }
        
        num = Int(self.zipView.textField.text!)
        if self.zipView.textField.text?.characters.count != 5 || num == nil {
            let alertView = AlertView(title: "Error", message: "Zip code should be a 5-digit number.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.present(customModalViewController: alertView, centerYOffset: 0)
            
            self.zipView.validStatus(status: false)
            return
        }
        
        let currentUser = UserDataModel.shared.currentUser()
        
        let escrow = Escrow()
        
        escrow.initValues()
        escrow.firstName = self.firstNameView.textField.text
        escrow.lastName = self.lastNameView.textField.text
        escrow.birthDay = self.birthDateView.textField.text
        escrow.birthMonth = self.birthMonthView.textField.text
        escrow.birthYear = self.birthYearView.textField.text
        escrow.ssn = self.ssnView.textField.text
        escrow.businessFullName = self.legalFullNameView.textField.text
        escrow.businessTax = self.legalTaxView.textField.text
        escrow.address1 = self.address1View.textField.text
        escrow.address2 = self.address2View.textField.text
        escrow.city = self.cityView.textField.text
        escrow.state = self.stateView.textField.text
        escrow.zip = self.zipView.textField.text
        escrow.email = self.emailView.textField.text != "" ? self.emailView.textField.text : currentUser?.email
        escrow.accountHolderName = self.accountHolderView.textField.text
        escrow.accountRoutingNumber = self.accountRoutingView.textField.text
        escrow.accountNumber = self.accountNumberView.textField.text
        
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        
        EscrowDataModel.shared.setupEscrow(escrow: escrow, ipAddress: self.ipAddress) { (error, message) in
            PKHUD.sharedHUD.hide()
            if error == nil {
                if message == "" {
                    if EscrowSetupViewController.isEscrowSetting == true {
                        if EscrowSetupViewController.homeViewController != nil {
                            EscrowSetupViewController.homeViewController.reloadEscrowData()
                        }
                        _ = self.navigationController?.popViewController(animated: true)
                    } else {
                        self.performSegue(withIdentifier: "escrowToVideoTutorialController", sender: self)
                    }
                } else {
                    let alertView = AlertView(title: "Error", message: message, okButtonTitle: "OK", cancelButtonTitle: nil)
                    self.present(customModalViewController: alertView, centerYOffset: 0)
                }
            } else {
                let alertView = AlertView(title: "Error", message: error?.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                self.present(customModalViewController: alertView, centerYOffset: 0)
            }
        }
        
        
    }
    
    func viewTouchAction(_ sender:UITapGestureRecognizer) {
        self.tooltip1View.isHidden = true
        self.tooltip2View.isHidden = true
    }
    
    func overlayButtonAction(tag: Int!) {
        switch (tag) {
        case 2:
            let pickerView = PickerView(contentType: PickerView.MONTH_PICKER)
            pickerView.delegate = self
            self.present(customModalViewController: pickerView, centerYOffset: 0)
            break;
        case 3:
            let pickerView = PickerView(contentType: PickerView.DAY_PICKER)
            pickerView.delegate = self
            self.present(customModalViewController: pickerView, centerYOffset: 0)
            break;
        case 4:
            let pickerView = PickerView(contentType: PickerView.YEAR_PICKER)
            pickerView.delegate = self
            self.present(customModalViewController: pickerView, centerYOffset: 0)
            break;
        case 11:
            let pickerView = PickerView(contentType: PickerView.STATE_PICKER)
            pickerView.delegate = self
            self.present(customModalViewController: pickerView, centerYOffset: 0)
            break;
        default:
            break;
        }
        
    }
    
    func updateAccountHolderName() {
        self.accountHolderView.textField.text = String.init(format: "%@ %@", self.firstNameView.textField.text!, self.lastNameView.textField.text!)
    }
    
    func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    @IBAction func back(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func checkButtonClicked(_ sender: Any) {
        self.tooltip2View.isHidden = true
        self.tooltip1View.isHidden = true
        
        if self.isTermsChecked == true {
            self.checkButton.setImage(UIImage(named: "ic_unchecked.png"), for: UIControlState.normal)
            self.isTermsChecked = false
        } else {
            self.checkButton.setImage(UIImage(named: "ic_checked.png"), for: UIControlState.normal)
            self.isTermsChecked = true
        }
    }
    
    @IBAction func legalTipClicked(_ sender: Any) {
        self.tooltip1View.isHidden = false
        self.tooltip2View.isHidden = true
    }
    
    @IBAction func termsButtonClicked(_ sender: Any) {
        let url = URL(string: "https://stripe.com/us/connect-account/legal")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func bankTipClicked(_ sender: Any) {
        self.tooltip2View.isHidden = false
        self.tooltip1View.isHidden = true
    }
    
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // For each interface ...
            var ptr = ifaddr
            while (ptr != nil) {
                
                let flags = Int32(ptr!.pointee.ifa_flags)
                var addr = ptr!.pointee.ifa_addr.pointee
                
                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                        nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            if let address = String(validatingUTF8: hostname) {
                                addresses.append(address)
                            }
                        }
                    }
                }
                
                ptr = ptr?.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        
        return addresses
    }
    
    func hideTooltip() {
        self.tooltip2View.isHidden = true
        self.tooltip1View.isHidden = true
    }
    
    func nextTextView(tag: Int!) {
        self.tooltip2View.isHidden = true
        self.tooltip1View.isHidden = true
        self.updateAccountHolderName()
        
        switch (tag) {
        case 0:
            self.firstNameView.textField.resignFirstResponder()
            self.lastNameView.textField.becomeFirstResponder()
            break
        case 1:
            self.lastNameView.textField.resignFirstResponder()
            
            self.overlayButtonAction(tag: 2)
            break
        case 2:
            self.birthMonthView.textField.resignFirstResponder()
            self.birthDateView.textField.becomeFirstResponder()
            break
        case 3:
            self.birthDateView.textField.resignFirstResponder()
            self.birthYearView.textField.becomeFirstResponder()
            break
        case 4:
            self.birthYearView.textField.resignFirstResponder()
            self.ssnView.textField.becomeFirstResponder()
            break
        case 5:
            self.ssnView.textField.resignFirstResponder()
            self.legalFullNameView.textField.becomeFirstResponder()
            break
        case 6:
            self.legalFullNameView.textField.resignFirstResponder()
            self.legalTaxView.textField.becomeFirstResponder()
            break
        case 7:
            self.legalTaxView.textField.resignFirstResponder()
            self.address1View.textField.becomeFirstResponder()
            break
        case 8:
            self.address1View.textField.resignFirstResponder()
            self.address2View.textField.becomeFirstResponder()
            break
        case 9:
            self.address2View.textField.resignFirstResponder()
            self.cityView.textField.becomeFirstResponder()
            break
        case 10:
            self.cityView.textField.resignFirstResponder()
            self.overlayButtonAction(tag: 11)
            break
        case 11:
            self.stateView.textField.resignFirstResponder()
            self.zipView.textField.becomeFirstResponder()
            break
        case 12:
            self.zipView.textField.resignFirstResponder()
            self.emailView.textField.becomeFirstResponder()
            break
        case 13:
            self.emailView.textField.resignFirstResponder()
            self.accountRoutingView.textField.becomeFirstResponder()
            break
        case 14:
            self.accountHolderView.textField.resignFirstResponder()
            self.accountRoutingView.textField.becomeFirstResponder()
            break
        case 15:
            self.accountRoutingView.textField.resignFirstResponder()
            self.accountNumberView.textField.becomeFirstResponder()
            break
        case 16:
            self.accountNumberView.textField.resignFirstResponder()
            break
        default:
            break
        }
    }
}

extension EscrowSetupViewController : PickerViewDelegate {
    func onOkButtonClicked(sender: PickerView) {
        if sender.getTagIndex() == 2 {
            self.birthMonthView.textField.text = sender.selectedValue
            self.overlayButtonAction(tag: 3)
        } else if sender.getTagIndex() == 3 {
            self.birthDateView.textField.text = sender.selectedValue
            self.overlayButtonAction(tag: 4)
        } else if sender.getTagIndex() == 4 {
            self.birthYearView.textField.text = sender.selectedValue
            self.ssnView.textField.becomeFirstResponder()
        } else if sender.getTagIndex() == 11 {
            self.stateView.textField.text = sender.selectedValue
            self.zipView.textField.becomeFirstResponder()
        }
    }
    
    func onCancelButtonClicked(sender: PickerView) {
        
    }
}
