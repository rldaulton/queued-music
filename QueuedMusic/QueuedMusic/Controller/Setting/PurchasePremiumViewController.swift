//
//  PurchasePremiumViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/14/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import PKHUD
import Stripe

class PurchasePremiumViewController: BaseViewController {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var purchaseTableView: UITableView!
    @IBOutlet var packageButtons: [UIButton]!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var purchaseButton: UIButton!

    let packages = [["votes":Int(20), "price":Float(1.99)],
                    ["votes":Int(60), "price":Float(4.99)],
                    ["votes":Int(150), "price":Float(9.99)]]
    var payments : [Dictionary<String, Any>] = []
    var selectedPackageIndex = -1
    var selectedPaymentIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        purchaseTableView.layoutTableHeaderView(header: headerView)
        purchaseTableView.layoutTableFooterView(footer: footerView)
        
        selectPackage(packageButtons[1])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        var updatedPayments : [Dictionary<String, Any>] = []
        if !(UserDataModel.shared.currentUser()?.creditCardPaymentId ?? "").isEmpty {
            var exists = false
            for payment in payments {
                if let icon = payment["icon"] as? String, icon == "ic_creditcard" {
                    exists = true
                    updatedPayments.append(payment)
                    break;
                }
            }
            if !exists {
                updatedPayments.append(["identifier" : "PurchasePremiumCell",
                                 "icon" : "ic_creditcard",
                                 "checked" : false])
            }
        }
        if PaymentsDataModel.shared.isApplePaySupported() && PaymentsDataModel.shared.isApplePayConfigured() {
            var exists = false
            for payment in payments {
                if let icon = payment["icon"] as? String, icon == "ic_apple_pay" {
                    updatedPayments.append(payment)
                    exists = true
                    break;
                }
            }
            if !exists {
                updatedPayments.append(["identifier" : "PurchasePremiumCell",
                                 "icon" : "ic_apple_pay",
                                 "checked" : false])
            }
        }
        
        if updatedPayments.count < 2 {
            updatedPayments.append(["identifier" : "AddPaymentMethodCell"])
        }
        payments = updatedPayments
        purchaseTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func selectPackage(_ sender: UIButton) {
        for packageButton in packageButtons {
            if packageButton == sender {
                packageButton.layer.borderUIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                packageButton.layer.borderWidth = 2
            } else {
                packageButton.layer.borderUIColor = #colorLiteral(red: 0.5882352941, green: 0.6, blue: 0.6235294118, alpha: 1)
                packageButton.layer.borderWidth = 1
            }
        }
        
        if let index = packageButtons.index(of: sender) {
            if let price = packages[index]["price"] as? Float {
                totalLabel.text = String(format: "total: $%.2f", price)
            }
            selectedPackageIndex = index
        }
    }
    
    @IBAction func purchase(_ sender: UIButton) {
        let payment = payments[selectedPaymentIndex]
        let package = packages[selectedPackageIndex]
        if let checked = payment["checked"] as? Bool, checked == true, let votes = package["votes"], let price = package["price"] {
            let alertView = AlertView(title: "Confirm", message: "You are about to purchase \(votes) votes at a price of \(price). Proceed?", okButtonTitle: "Buy", cancelButtonTitle: "Cancel")
            alertView.delegate = self
            present(customModalViewController: alertView, centerYOffset: 0)
        }
    }
}

extension PurchasePremiumViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let identifier = payments[indexPath.row]["identifier"] as? String, identifier == "PurchasePremiumCell" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PurchasePremiumCell", for: indexPath) as! PurchasePremiumCell
            
            if let icon = payments[indexPath.row]["icon"] as? String  {
                cell.paymentLogoImageView.image = UIImage(named: icon)
            }
            if let checked = payments[indexPath.row]["checked"] as? Bool {
                cell.checkmarkImageView.isHidden = !checked
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddPaymentMethodCell", for: indexPath) as! AddPaymentMethodCell
            
            return cell
        }
    }
}

extension PurchasePremiumViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let identifier = payments[indexPath.row]["identifier"] as? String, identifier == "PurchasePremiumCell" {
            for index in 0..<payments.count {
                payments[index]["checked"] = (index == indexPath.row) ? true : false
            }
            tableView.reloadData()

            purchaseButton.isHidden = true
            for payment in payments {
                if let checked = payment["checked"] as? Bool, checked == true {
                    purchaseButton.isHidden = false
                    break
                }
            }
            selectedPaymentIndex = indexPath.row
        } else {
            performSegue(withIdentifier: "purchasePremiumToPaymentsSegue", sender: self)
        }
    }
}

extension PurchasePremiumViewController: AlertViewDelegate {
    func onOkButtonClicked() {
        let package = packages[selectedPackageIndex]
        guard let amount = package["price"] as? Float, let votes = package["votes"] as? Int else { return }
        
        if let icon = payments[selectedPaymentIndex]["icon"] as? String, icon == "ic_apple_pay" {
            let paymentRequest: PKPaymentRequest? = Stripe.paymentRequest(withMerchantIdentifier: STPPaymentConfiguration.shared().appleMerchantIdentifier!)
            paymentRequest?.paymentSummaryItems = [PKPaymentSummaryItem(label: "\(votes) Vote Package", amount: NSDecimalNumber(value: amount))]
            if let paymentRequest = paymentRequest, Stripe.canSubmitPaymentRequest(paymentRequest) {
                let paymentAuthorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
                paymentAuthorizationViewController.delegate = self
                present(paymentAuthorizationViewController, animated: true, completion: nil)
            } else {
                let alertView = AlertView(title: "Purchase Error", message: "There is a problem with your apple pay configuration", okButtonTitle: "OK", cancelButtonTitle: nil)
                self.present(customModalViewController: alertView, centerYOffset: 0)
            }

        } else {
            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()
            PaymentsDataModel.shared.payWithCreditCard(amount: Int(round(amount * 100)), completion: { (error) in
                if let error = error {
                    PKHUD.sharedHUD.hide()
                    let alertView = AlertView(title: "Purchase Error", message: "The purchase has failed. Please try again later, or contact support.", okButtonTitle: "OK", cancelButtonTitle: nil)
                    self.present(customModalViewController: alertView, centerYOffset: 0)
                } else {
                    guard let currentUser = UserDataModel.shared.currentUser() else { return }
                    if let premiumVoteBalance = currentUser.premiumVoteBalance, let userId = currentUser.userId {
                        let values = [User.UserKey.premiumVoteBalanceKey : premiumVoteBalance + votes]
                        FirebaseManager.shared.updateValues(with: "user/\(userId)", values: values, completion: { (error) in
                            if error == nil {
                                currentUser.premiumVoteBalance = premiumVoteBalance + votes
                                UserDataModel.shared.storeCurrentUser(user: currentUser)
                                var code = "320"
                                if votes == 60 {
                                    code = "360"
                                } else if votes == 150 {
                                    code = "3150"
                                }
                                
                                SpotifyManager.shared.trackUserActions(userID: UserDataModel.shared.currentUser()?.userId, venueID: VenueDataModel.shared.currentVenue.venueId, eventCode: code, eventDesc: "purchase votes", completion: { (error) in
                                    
                                })
                                
                                PKHUD.sharedHUD.hide()
                                let alertView = AlertView(title: "Purchase Success", message: "You have successfully purchased \(votes) votes at a price of \(amount) with your credit card.", okButtonTitle: "OK", cancelButtonTitle: nil)
                                alertView.tag = 1000
                                alertView.delegate = self
                                self.present(customModalViewController: alertView, centerYOffset: 0)
                            }
                        })
                    }
                }
            })
        }
    }
    
    func onPerformActionClicked(action: Int) {
        if action == 1000 {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension PurchasePremiumViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        dismiss(animated: true, completion: nil)
        
        let package = packages[selectedPackageIndex]
        guard let amount = package["price"] as? Float, let votes = package["votes"] as? Int else { return }
        
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        PaymentsDataModel.shared.payWithApplePay(payment: payment, amount: Int(round(amount * 100))) { (error) in
            if let error = error {
                PKHUD.sharedHUD.hide()
                let alert = AlertView(title: "Error", message: "The purchase has failed. Please try again later, or contact support.", okButtonTitle: "OK", cancelButtonTitle: nil)
                self.present(customModalViewController: alert, centerYOffset: 0)
                completion(.failure)
            } else {
                guard let currentUser = UserDataModel.shared.currentUser() else { return }
                if let premiumVoteBalance = currentUser.premiumVoteBalance, let userId = currentUser.userId {
                    let values = [User.UserKey.premiumVoteBalanceKey : premiumVoteBalance + votes]
                    FirebaseManager.shared.updateValues(with: "user/\(userId)", values: values, completion: { (error) in
                        if error == nil {
                            currentUser.premiumVoteBalance = premiumVoteBalance + votes
                            UserDataModel.shared.storeCurrentUser(user: currentUser)
                            
                            PKHUD.sharedHUD.hide()
                            let alertView = AlertView(title: "Purchase Success", message: "You have successfully purchased \(votes) votes at a price of \(amount) with your apple pay.", okButtonTitle: "OK", cancelButtonTitle: nil)
                            alertView.tag = 1000
                            alertView.delegate = self
                            self.present(customModalViewController: alertView, centerYOffset: 0)
                        }
                    })
                }
            }
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        dismiss(animated: true, completion: nil)
    }
}


