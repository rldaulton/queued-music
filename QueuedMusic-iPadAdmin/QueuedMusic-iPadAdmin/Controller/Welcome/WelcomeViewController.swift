//
//  ViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/18/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import PKHUD
import Spotify
import XCDYouTubeKit

class WelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if UserDataModel.shared.currentUser() != nil {
            if UserDataModel.shared.escrowSetupStatus() == true {
                performSegue(withIdentifier: "welcomeToMainSegue", sender: self)
            } else {
                performSegue(withIdentifier: "welcomeToNewVenueController", sender: self)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func login(_ sender: Any) {
        performSegue(withIdentifier: "welcomeToLoginSegue", sender: self)
    }
    
    @IBAction func signupWithSpotify(_ sender: Any) {
        SpotifyManager.shared.login(controller: self, completion: { (error, spotifyUser) in
            if error != nil {
                PKHUD.sharedHUD.hide()
                HUD.flash(.labeledError(title: "Error", subtitle: "Spotify Authentification Failed, Please try again"), delay: 2)
            } else {
                if spotifyUser?.product != SPTProduct.premium {
                    PKHUD.sharedHUD.hide()
                    let alertView = AlertView(title: "Error", message: "You must be a Spotify Premium member to host a an active queue.", okButtonTitle: "OK", cancelButtonTitle: nil)
                    self.present(customModalViewController: alertView, centerYOffset: 0)
                    
                    return
                }
                
                var imageUrl = ""
                if let largestImage = spotifyUser?.largestImage {
                    imageUrl = largestImage.imageURL.absoluteString
                }
                let user = User(userId: spotifyUser?.uri.absoluteString, userName: spotifyUser?.canonicalUserName, email: spotifyUser?.emailAddress, venueID: "", loginType: .spotify, joined: Date(), photoUrl: imageUrl)
                UserDataModel.shared.register(user: user, completion: { (error) in
                    PKHUD.sharedHUD.hide()
                    if let error = error {
                        let alertView = AlertView(title: "Error", message: error.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                        self.present(customModalViewController: alertView, centerYOffset: 0)
                    } else {
                        user.loginType = .spotify
                        UserDataModel.shared.storeCurrentUser(user: user)
                        UserDataModel.shared.storeEscrowSetupStatus(status: false)
                        
                        self.performSegue(withIdentifier: "welcomeToNewVenueController", sender: self)
                    }
                })
            }
        })
    }
}

