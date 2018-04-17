//
//  WelcomeViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/2/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import BWWalkthrough
import PKHUD
import Firebase

class WelcomeViewController: BaseViewController, WalkthroughPresentable {
    
    @IBOutlet var backgroundVideo: BackgroundVideo!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundVideo.createBackgroundVideo(url: "club", type: "mp4", alpha: 0.7)

        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if UserDataModel.shared.currentUser() != nil {
            if UserDataModel.shared.currentUser()?.loginType == .guest {
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
                        
                    })
                    UserDataModel.shared.logout()
                }
            } else {
                self.next()
            }
        }
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
                performSegue(withIdentifier: "welcomeToNotificationSegue", sender: self)
            } else if !AppSetting.shared.isLocationPermissionChecked() {
                performSegue(withIdentifier: "welcomeToLocationSegue", sender: self)
            } else {
                performSegue(withIdentifier: "welcomeToMainSegue", sender: self)
            }
        }
    }
    
    @IBAction func signupWithSpotify(_ sender: Any) {
        SpotifyManager.shared.login(controller: self, completion: { (error, spotifyUser) in
            if error != nil {
                PKHUD.sharedHUD.hide()
                HUD.flash(.labeledError(title: "Error", subtitle: "Spotify Authentification Failed, Please try again"), delay: 2)
            } else {
                var imageUrl = ""
                if let largestImage = spotifyUser?.largestImage {
                    imageUrl = largestImage.imageURL.absoluteString
                }
                let user = User(userId: spotifyUser?.uri.absoluteString, userName: spotifyUser?.canonicalUserName, email: spotifyUser?.emailAddress, applePayPaymentId: "", creditCardPaymentId: "", customerStripeId: "", lifetimeVotes: 0, premiumVoteBalance: 5, loginType: .spotify, joined: Date(), photoUrl: imageUrl, token: "")
                UserDataModel.shared.register(user: user, completion: { (error) in
                    PKHUD.sharedHUD.hide()
                    if let error = error {
                        let alertView = AlertView(title: "Error", message: error.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                        self.present(customModalViewController: alertView, centerYOffset: 0)
                    } else {
                        user.loginType = .spotify
                        UserDataModel.shared.storeCurrentUser(user: user)
                        UserDataModel.shared.storeFirstVoteDone(value: false)
                        self.next()
                    }
                })
            }
        })
    }
    
    @IBAction func signupWithGoogle(_ sender: Any) {
        GoogleAuth.shared.login(controller: self) { (error, googleUser) in
            if error != nil {
                PKHUD.sharedHUD.hide()
                HUD.flash(.labeledError(title: "Error", subtitle: "Google Authentification Failed, Please try again"), delay: 2)
            } else {
                var imageUrl = ""
                if googleUser?.profile.hasImage == true, let url = googleUser?.profile.imageURL(withDimension: 200) {
                    imageUrl = url.absoluteString
                }
                let user = User(userId: googleUser?.userID, userName: googleUser?.profile.name, email: googleUser?.profile.email, applePayPaymentId: "", creditCardPaymentId: "", customerStripeId: "", lifetimeVotes: 0, premiumVoteBalance: 5 , loginType: .google, joined: Date(), photoUrl: imageUrl, token: "")
                user.googleAuth = googleUser?.authentication
                UserDataModel.shared.register(user: user, completion: { (error) in
                    PKHUD.sharedHUD.hide()
                    if let error = error {
                        let alertView = AlertView(title: "Error", message: error.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                        self.present(customModalViewController: alertView, centerYOffset: 0)
                    } else {
                        user.loginType = .google
                        user.googleAuth = googleUser?.authentication
                        UserDataModel.shared.storeCurrentUser(user: user)
                        UserDataModel.shared.storeFirstVoteDone(value: false)
                        self.next()
                    }
                })
            }
        }
    }
    
    @IBAction func enterAsGuest(_ sender: Any) {
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        FirebaseManager.shared.loginAnonymously { (user, error) in
            if error == nil {
                let user = User(userId: user?.uid, userName: "Guest", email: "", applePayPaymentId: "", creditCardPaymentId: "", customerStripeId: "", lifetimeVotes: 0, premiumVoteBalance: 0, loginType: .guest, joined: Date(), photoUrl: "", token: FIRInstanceID.instanceID().token())
                
                UserDataModel.shared.register(user: user, completion: { (error) in
                    PKHUD.sharedHUD.hide()
                    if let error = error {
                        let alertView = AlertView(title: "Error", message: error.localizedDescription, okButtonTitle: "OK", cancelButtonTitle: nil)
                        self.present(customModalViewController: alertView, centerYOffset: 0)
                    } else {
                        UserDataModel.shared.storeCurrentUser(user: user)
                        UserDataModel.shared.storeFirstVoteDone(value: false)
                        self.next()
                    }
                })
            } else {
                PKHUD.sharedHUD.hide()
            }
        }
    }
    
    @IBAction func login(_ sender: Any) {
        performSegue(withIdentifier: "welcomeToLoginSegue", sender: self)
    }
}

extension WelcomeViewController: BWWalkthroughViewControllerDelegate {
    func walkthroughCloseButtonPressed() {
        dismiss(animated: true, completion: nil)
        AppSetting.shared.setWalkthroughChecked(true)
        next()
    }
}
