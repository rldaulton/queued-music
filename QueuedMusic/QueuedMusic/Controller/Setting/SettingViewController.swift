//
//  SettingViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/14/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import AlamofireImage

class SettingViewController: BaseViewController {

    let settings = ["Support & Feedback", "Payment Information", "App Info & Terms"]
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var pictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var settingTableView: UITableView!
    @IBOutlet weak var premiumVoteView: UIView!
    @IBOutlet weak var premiumVoteBalanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        settingTableView.layoutTableHeaderView(header: headerView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        
        if let imageUrl = currentUser.photoUrl, imageUrl != "" {
            let urlRequest = URLRequest(url: URL(string: imageUrl)!)
            if let image = ImageDownloader.default.imageCache?.image(for: urlRequest, withIdentifier: imageUrl) {
                pictureImageView.image = image
            } else {
                ImageDownloader.default.download(urlRequest) { (response) in
                    if let image = response.result.value {
                        ImageDownloader.default.imageCache?.add(image, for: urlRequest, withIdentifier: imageUrl)
                        self.pictureImageView.image = image
                    }
                }
            }
        }
        
        if let name = currentUser.userName {
            nameLabel.text = name
        }
        
        premiumVoteView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectPremiumVote)))
        if let balance = currentUser.premiumVoteBalance {
            premiumVoteBalanceLabel.text = "\(balance)"
        }
        
        
        if UserDataModel.shared.currentUser() != nil {
            UserDataModel.shared.updateUserInfo(completion: { (error, user) in
                if error == nil {
                    if let name = user?.userName {
                        self.nameLabel.text = name
                    }
                    if let balance = user?.premiumVoteBalance {
                        self.premiumVoteBalanceLabel.text = "\(balance)"
                    }
                    
                    user?.loginType = UserDataModel.shared.currentUser()?.loginType
                    
                    UserDataModel.shared.storeCurrentUser(user: user)
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func selectPremiumVote(tgr: UITapGestureRecognizer!) {
        if UserDataModel.shared.currentUser() != nil && UserDataModel.shared.currentUser()?.loginType == .guest {
            let alertView = AlertView(title: "Warning", message: "You must be a member to access these menu actions.", okButtonTitle: "Sign up", cancelButtonTitle: "Cancel")
            alertView.delegate = self
            alertView.tag = 1000
            present(customModalViewController: alertView, centerYOffset: 0)
            
            return
        }
        performSegue(withIdentifier: "settingToPurchasePremium", sender: self)
    }
    
    @IBAction func logout(_ sender: Any) {
        if UserDataModel.shared.currentUser() != nil && UserDataModel.shared.currentUser()?.loginType == .guest {
            let currentUser = UserDataModel.shared.currentUser()
            let currentVenue = VenueDataModel.shared.currentVenue
            
            if currentUser != nil && currentVenue != nil {
                VenueDataModel.shared.removeCheckIn(venueId: currentVenue?.venueId, userId: currentUser?.userId) { (error) in
                    if error == nil {
                        
                    }
                }
            }
            
            if currentUser != nil && currentUser?.loginType == .guest {
                UserDataModel.shared.removeUser(userId: currentUser?.userId, completion: { (error) in
                    if error == nil {
                        UserDataModel.shared.logout()
                        _ = self.parent?.navigationController?.popToRootViewController(animated: true)
                    }
                })
            }
            
            return
        }
        
        let alertView = AlertView(title: "Warning", message: "Are you sure to log out?", okButtonTitle: "Yes", cancelButtonTitle: "No")
        alertView.delegate = self
        present(customModalViewController: alertView, centerYOffset: 0)
    }
}

extension SettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        
        cell.titleLabel.text = settings[indexPath.row]
        
        return cell
    }
}

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "settingToSupport", sender: self)
            break;
            
        case 1:
            if UserDataModel.shared.currentUser() != nil && UserDataModel.shared.currentUser()?.loginType == .guest {
                let alertView = AlertView(title: "Warning", message: "You must be a member to access these menu actions.", okButtonTitle: "Sign up", cancelButtonTitle: "Cancel")
                alertView.delegate = self
                alertView.tag = 1000
                present(customModalViewController: alertView, centerYOffset: 0)
                
                break;
            }
            
            performSegue(withIdentifier: "settingToPayments", sender: self)
            break;
            
        case 2:
            performSegue(withIdentifier: "settingToTerms", sender: self)
            break;
            
        default:
            break;
        }
    }
}

extension SettingViewController: AlertViewDelegate {
    func onOkButtonClicked() {
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        guard let currentVenue = VenueDataModel.shared.currentVenue else { return }
        
        VenueDataModel.shared.removeCheckIn(venueId: currentVenue.venueId, userId: currentUser.userId) { (error) in
            if error == nil {
                
            }
        }
        
        UserDataModel.shared.logout()
        _ = self.parent?.navigationController?.popToRootViewController(animated: true)
    }
    
    func onPerformActionClicked(action: Int) {
        if action == 1000 {
            guard let currentUser = UserDataModel.shared.currentUser() else { return }
            guard let currentVenue = VenueDataModel.shared.currentVenue else { return }
            
            VenueDataModel.shared.removeCheckIn(venueId: currentVenue.venueId, userId: currentUser.userId) { (error) in
                if error == nil {
                    
                }
            }
            
            UserDataModel.shared.removeUser(userId: currentUser.userId, completion: { (error) in
                
            })
            
            UserDataModel.shared.logout()
            _ = self.parent?.navigationController?.popToRootViewController(animated: true)
        }
    }
    func onCancelButtonClicked() {
        
    }
}
