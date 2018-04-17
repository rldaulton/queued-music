//
//  LoginViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/19/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//


import UIKit
import PKHUD

class LoginViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func back(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func loginWithSpotify(_ sender: Any) {
        SpotifyManager.shared.login(controller: self) { (error, spotifyUser) in
            if error != nil {
                HUD.flash(.labeledError(title: "Error", subtitle: "Spotify Authentification Failed, Please try again"), delay: 2)
            } else {
                PKHUD.sharedHUD.contentView = PKHUDProgressView()
                PKHUD.sharedHUD.show()
                UserDataModel.shared.login(userId: spotifyUser?.uri.absoluteString, loginType: .spotify, googleAuth: nil, completion: { (error, user) in
                    PKHUD.sharedHUD.hide()
                    if let error = error {
                        let alertView = AlertView(title: "Alert", message: error.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                        self.present(customModalViewController: alertView, centerYOffset: 0)
                    } else {
                        if user == nil {
                            let alertView = AlertView(title: "Alert", message: "User doesn't exist.", okButtonTitle: "OK", cancelButtonTitle: nil)
                            self.present(customModalViewController: alertView, centerYOffset: 0)
                        } else {
                            user?.loginType = .spotify
                            UserDataModel.shared.storeCurrentUser(user: user)
                            UserDataModel.shared.storeEscrowSetupStatus(status: true)
                            
                            self.performSegue(withIdentifier: "loginToMainSegue", sender: self)
                        }
                        
                    }
                })
            }
        }
        
    }
    
    @IBAction func loginWithGoogle(_ sender: Any) {
        GoogleAuth.shared.login(controller: self) { (error, googleUser) in
            if error != nil {
                HUD.flash(.labeledError(title: "Error", subtitle: "Google Authentification Failed, Please try again"), delay: 2)
            } else {
                PKHUD.sharedHUD.contentView = PKHUDProgressView()
                PKHUD.sharedHUD.show()
                UserDataModel.shared.login(userId: googleUser?.userID, loginType: .google, googleAuth: googleUser?.authentication, completion: { (error, user) in
                    PKHUD.sharedHUD.hide()
                    if let error = error {
                        let alertView = AlertView(title: "Alert", message: error.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                        self.present(customModalViewController: alertView, centerYOffset: 0)
                    } else {
                        user?.loginType = .google
                        user?.googleAuth = googleUser?.authentication
                        UserDataModel.shared.storeCurrentUser(user: user)
                        
                        self.performSegue(withIdentifier: "loginToMainSegue", sender: self)
                    }
                })
            }
        }
    }

}

