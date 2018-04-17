//
//  PaymentsViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/16/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import PKHUD

class PaymentsViewController: BaseViewController {
    
    @IBOutlet weak var paymentTableView: UITableView!
    
    var payments: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        paymentTableView.tableFooterView = UIView()
        
        if PaymentsDataModel.shared.isApplePaySupported() && PaymentsDataModel.shared.isApplePayConfigured() {
            payments.append("Apple Pay")
        }
        payments.append("Credit Card")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension PaymentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell", for: indexPath) as! PaymentCell
        
        cell.methodLabel.text = payments[indexPath.row]
        
        if payments[indexPath.row] == "Apple Pay" {
            cell.statusLabel.text = "auto-enabled"
        } else {
            cell.statusLabel.text = (UserDataModel.shared.currentUser()?.creditCardPaymentId ?? "").isEmpty ? "" : "tap to replace"
        }
        
        return cell
    }
}

extension PaymentsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if payments[indexPath.row] == "Credit Card" {
            CardIOUtilities.preload()
            let cardIOViewController = CardIOPaymentViewController(paymentDelegate: self)
            cardIOViewController?.hideCardIOLogo = true
            cardIOViewController?.modalPresentationStyle = .formSheet
            present(cardIOViewController!, animated: true, completion: nil)
        }
    }
}

extension PaymentsViewController: CardIOPaymentViewControllerDelegate {
    func userDidCancel(_ paymentViewController: CardIOPaymentViewController!) {
        paymentViewController.dismiss(animated: true, completion: nil)
    }
    
    func userDidProvide(_ cardInfo: CardIOCreditCardInfo!, in paymentViewController: CardIOPaymentViewController!) {
        paymentViewController.dismiss(animated: true, completion: nil)
        
        if let info = cardInfo {
            let str = NSString(format: "Received card info.\n Number: %@\n expiry: %02lu/%lu\n cvv: %@.", info.redactedCardNumber, info.expiryMonth, info.expiryYear, info.cvv)
            print(str)
            
            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()
            PaymentsDataModel.shared.applyCreditCard(number: info.cardNumber, expMonth: info.expiryMonth, expYear: info.expiryYear, cvc: info.cvv, completion: { (error) in
                PKHUD.sharedHUD.hide()
                
                if let error = error {
                    let alert = AlertView(title: "Error", message: error.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                    self.present(customModalViewController: alert, centerYOffset: 0)
                } else {
                    self.paymentTableView.reloadData()
                }
            })
        }
    }
}
