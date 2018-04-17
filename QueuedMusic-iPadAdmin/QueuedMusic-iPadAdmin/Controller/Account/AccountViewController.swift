//
//  AnalyticsViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import PKHUD
import AlamofireImage
import HNKGooglePlacesAutocomplete
import MessageUI

class AccountViewController : BaseViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        
        if let imageUrl = currentUser.photoUrl {
            let urlRequest = URLRequest(url: URL(string: imageUrl)!)
            if let image = ImageDownloader.default.imageCache?.image(for: urlRequest, withIdentifier: imageUrl) {
                profileImageView.image = image
            } else {
                ImageDownloader.default.download(urlRequest) { (response) in
                    if let image = response.result.value {
                        ImageDownloader.default.imageCache?.add(image, for: urlRequest, withIdentifier: imageUrl)
                        self.profileImageView.image = image
                    }
                }
            }
        }
        
        self.userNameLabel.text = currentUser.userName
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func back(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func manageSpotifyAccountClicked(_ sender: Any) {
        let url = URL(string: "https://www.spotify.com/us/account/overview/")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func supportClicked(_ sender: Any) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            mailComposeViewController.navigationBar.tintColor = UIColor.white
            mailComposeViewController.navigationBar.backgroundColor = #colorLiteral(red: 1, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
            mailComposeViewController.navigationBar.barTintColor = UIColor.white
            
            self.present(mailComposeViewController, animated: true, completion: nil)
        }/* else {
            self.showSendMailErrorAlert()
        }*/
    }
    
    @IBAction func privacyClicked(_ sender: Any) {
        let url = URL(string: "https://my-website")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func termsClicked(_ sender: Any) {
        let url = URL(string: "https://my-terms-link/terms.html")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func deleteAccountClicked(_ sender: Any) {
        let alertView = AlertView(title: "Are You Sure?", message: "This will delete your venue from our system, as well as any active queues or data associated with it. This cannot be undone.", okButtonTitle: "Delete", cancelButtonTitle: "Cancel")
        alertView.delegate = self
        alertView.setTagIndex(index: 1000)
        self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["my-support-email@email.com"])
        mailComposerVC.setSubject("Host Support Needed")
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

extension AccountViewController: AlertViewDelegate {
    func onOkButtonClicked(sender: AlertView) {
        if sender.getTagIndex() == 1000 { // delete account
            MainViewController.showProgressBar()
            VenueDataModel.shared.removeVenue(venueId: VenueDataModel.shared.currentVenue.venueId, completion: { (error) in
                MainViewController.hideProgressBar()
                if error == nil {
                    UserDataModel.shared.removeAccount(userId: UserDataModel.shared.currentUser()?.userId, completion: { (error) in
                        
                    })
                    UserDataModel.shared.logout()
                    _ = self.navigationController?.popToRootViewController(animated: true)
                } else {
                    let alertView = AlertView(title: "Error", message: error?.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                    self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
                }
            })
            
        }
    }
    
    func onCancelButtonClicked(sender: AlertView) {
        
    }
}
