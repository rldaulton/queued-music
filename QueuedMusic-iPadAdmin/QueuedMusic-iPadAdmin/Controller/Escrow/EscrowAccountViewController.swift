//
//  AnalyticsViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import MessageUI


protocol EscrowDataSourceDelegate: class {
    func dataSourceDidCompleteLoad(_ dataSource: EscrowDataSource, escrows: [EscrowSummary]?)
}

protocol EscrowConfigurable {
    func configure(with escrow: EscrowSummary?)
}

protocol EscrowCellConfigurable: EscrowConfigurable {
    var transactionAmountLabel: UILabel! { get set }
    var transactionTimeLabel: UILabel! { get set }
    var activityLabel: UILabel! { get set }
}

extension EscrowCellConfigurable {
    func configure(with escrow: EscrowSummary?) {
        activityLabel.text = escrow?.reversed == true ? "Reversed" : "Approved"
        activityLabel.textColor = escrow?.reversed == true ? #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        // transaction Amount
        let total : Double = Double((escrow?.amount)!) / 0.3
        let accountAttributes1 = [NSForegroundColorAttributeName: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 17)] as [String : Any]
        let accountAttributes2 = [NSForegroundColorAttributeName: #colorLiteral(red: 0.4743354321, green: 0.9497771859, blue: 0.7335880399, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 17)] as [String : Any]
        let accountAttributes3 = [NSForegroundColorAttributeName: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 17)] as [String : Any]
        
        let accountOne = NSMutableAttributedString(string: "$", attributes: accountAttributes1)
        let accountTwo = NSMutableAttributedString(string: String.init(format: "%.2f", Double((escrow?.amount)!) / 100), attributes: accountAttributes2)
        let accountThree = NSMutableAttributedString(string: String.init(format: " of $%.2f", Double(total) / 100), attributes: accountAttributes3)
        
        let combination = NSMutableAttributedString()
        
        combination.append(accountOne)
        combination.append(accountTwo)
        combination.append(accountThree)
        
        self.transactionAmountLabel.attributedText = combination
        
        // Transaction Time
        let date = Date(timeIntervalSince1970: TimeInterval((escrow?.created)!))
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT") //Set timezone that you want
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "dd-MMM-yy HH:mm:ss" //Specify your format that you want
        let strDate = dateFormatter.string(from: date)
        transactionTimeLabel.text = strDate
    }
}

extension EscrowTableCell: EscrowCellConfigurable { }

class EscrowDataSource: NSObject, UITableViewDataSource {
    weak var delegate: EscrowDataSourceDelegate?
    var escrows: [EscrowSummary] = []
    
    func load(paymentId: String) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        EscrowDataModel.shared.loadEscrowSummary(accountID: paymentId) { (summary, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.delegate?.dataSourceDidCompleteLoad(self, escrows: summary)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EscrowTableCell", for: indexPath) as! EscrowTableCell
        
        let escrow = escrows[indexPath.item]
        (cell as EscrowConfigurable).configure(with: escrow)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.escrows.count
    }
}

class EscrowAccountViewController : BaseViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var pendingLabel: UILabel!
    @IBOutlet weak var escrowTableView: UITableView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    let dataSource = EscrowDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        dataSource.delegate = self
        escrowTableView.dataSource = dataSource
        dataSource.load(paymentId: VenueDataModel.shared.currentVenue.paymentId!)
        
        self.initEscrowLabel(balance: "0", pending: "0")
        
        EscrowDataModel.shared.loadBalanceAmount(accountID: VenueDataModel.shared.currentVenue.paymentId) { (amount, pending, error) in
            self.initEscrowLabel(balance: amount, pending: pending)
        }
        
        self.noDataLabel.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func back(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func reqeustChange(_ sender: Any) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            mailComposeViewController.navigationBar.tintColor = UIColor.white
            mailComposeViewController.navigationBar.backgroundColor = #colorLiteral(red: 1, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
            mailComposeViewController.navigationBar.barTintColor = UIColor.white
            
            self.present(mailComposeViewController, animated: true, completion: nil)
        } /*else {
            self.showSendMailErrorAlert()
        }*/
    }
    
    func initEscrowLabel(balance: String!, pending: String!) {
        if balance != nil && balance != "null" {
            let accountAttributes1 = [NSForegroundColorAttributeName: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 25)] as [String : Any]
            let accountAttributes2 = [NSForegroundColorAttributeName: #colorLiteral(red: 0.4743354321, green: 0.9497771859, blue: 0.7335880399, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 25)] as [String : Any]
            
            let accountOne = NSMutableAttributedString(string: "$ ", attributes: accountAttributes1)
            let accountTwo = NSMutableAttributedString(string: String.init(format: "%.2f", Double(balance)! / 100), attributes: accountAttributes2)
            
            let combination = NSMutableAttributedString()
            
            combination.append(accountOne)
            combination.append(accountTwo)
            
            self.balanceLabel.attributedText = combination
        }
        
        if pending != nil && pending != "null"  {
            let lifetimeAttributes1 = [NSForegroundColorAttributeName: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 25)] as [String : Any]
            let lifetimeAttributes2 = [NSForegroundColorAttributeName: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 25)] as [String : Any]
            
            let lifetimeOne = NSMutableAttributedString(string: "$ ", attributes: lifetimeAttributes1)
            let lifetimeTwo = NSMutableAttributedString(string: String.init(format: "%.2f", Double(pending)! / 100), attributes: lifetimeAttributes2)
            
            let combination2 = NSMutableAttributedString()
            
            combination2.append(lifetimeOne)
            combination2.append(lifetimeTwo)
            
            self.pendingLabel.attributedText = combination2
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["my-support-email@email.com"])
        mailComposerVC.setSubject("Escrow - Requested Account Changes")
        mailComposerVC.setMessageBody("", isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = AlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", okButtonTitle: "OK", cancelButtonTitle: nil)
        self.navigationController?.present(customModalViewController: sendMailErrorAlert, centerYOffset: 0)
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension EscrowAccountViewController: EscrowDataSourceDelegate {
    func dataSourceDidCompleteLoad(_ dataSource: EscrowDataSource, escrows: [EscrowSummary]?) {
        dataSource.escrows = escrows!
        if escrows?.count == 0 {
            self.noDataLabel.isHidden = false
        } else {
            self.noDataLabel.isHidden = true
        }
        escrowTableView.reloadData()
    }
    
}

