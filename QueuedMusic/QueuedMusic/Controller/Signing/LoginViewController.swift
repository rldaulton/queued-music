//
//  LoginViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/3/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import BWWalkthrough
import PKHUD

protocol WalkthroughPresentable {
    func presentWalkthrough(In viewController: UIViewController!)
}

extension WalkthroughPresentable {
    func presentWalkthrough(In viewController: UIViewController!) {
        let walkthroughStoryboard = UIStoryboard(name: "Walkthrough", bundle: nil)
        let walkthroughViewController = walkthroughStoryboard.instantiateViewController(withIdentifier: "Master") as! BWWalkthroughViewController
        let firstViewController = walkthroughStoryboard.instantiateViewController(withIdentifier: "walkthrough1") as UIViewController
        let secondViewController = walkthroughStoryboard.instantiateViewController(withIdentifier: "walkthrough2") as UIViewController
        let thirdViewController = walkthroughStoryboard.instantiateViewController(withIdentifier: "walkthrough3") as UIViewController
        walkthroughViewController.delegate = viewController as! BWWalkthroughViewControllerDelegate?
        walkthroughViewController.add(viewController: firstViewController)
        walkthroughViewController.add(viewController: secondViewController)
        walkthroughViewController.add(viewController: thirdViewController)
        viewController.present(walkthroughViewController, animated: true, completion: nil)
    }
}

class LoginViewController: BaseViewController, WalkthroughPresentable {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func next() {
        if !AppSetting.shared.isWalkthroughChecked() {
            presentWalkthrough(In: self)
        } else {
            if !AppSetting.shared.isNotificationPermissionChecked() {
                performSegue(withIdentifier: "loginToNotificationSegue", sender: self)
            } else if !AppSetting.shared.isLocationPermissionChecked() {
                performSegue(withIdentifier: "loginToLocationSegue", sender: self)
            } else {
                performSegue(withIdentifier: "loginToMainSegue", sender: self)
            }
        }
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
                            HUD.flash(.labeledError(title: "Error", subtitle: "User doesn't exist. Please sign up first."), delay: 4)
                            return
                        }
                        
                        user?.loginType = .spotify
                        UserDataModel.shared.storeCurrentUser(user: user)
                        self.next()
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
                        if user == nil {
                            HUD.flash(.labeledError(title: "Error", subtitle: "User doesn't exist. Please sign up first."), delay: 4)
                            return
                        }
                        
                        user?.loginType = .google
                        user?.googleAuth = googleUser?.authentication
                        UserDataModel.shared.storeCurrentUser(user: user)
                        self.next()
                    }
                })
            }
        }
    }
}

extension LoginViewController: BWWalkthroughViewControllerDelegate {
    func walkthroughCloseButtonPressed() {
        dismiss(animated: true, completion: nil)
        AppSetting.shared.setWalkthroughChecked(true)
        next()
    }
}
