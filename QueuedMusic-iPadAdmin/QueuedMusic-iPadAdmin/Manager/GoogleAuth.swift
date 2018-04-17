//
//  GoogleAuth.swift
//  QueuedMusic
//
//  Created by Micky on 2/21/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Foundation
import GoogleSignIn
import PKHUD

class GoogleAuth: NSObject {
    
    static let shared: GoogleAuth = GoogleAuth()
    
    var controller: UIViewController!
    var completion: ((_ error: Error?, _ user: GIDGoogleUser?) -> Void)?
    
    private override init() {
        super.init()
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    func login(controller: UIViewController, completion: @escaping (_ error: Error?, _ user: GIDGoogleUser?) -> Void) {
        self.controller = controller
        self.completion = completion
        
        GIDSignIn.sharedInstance().signIn()
    }
    
    func loginSilently(completion: @escaping (_ error: Error?, _ user: GIDGoogleUser?) -> Void) {
        self.completion = completion
        GIDSignIn.sharedInstance().signInSilently()
    }
    
    func isLoggedIn() -> Bool {
        return GIDSignIn.sharedInstance().hasAuthInKeychain()
    }
    
    func logout() {
        GIDSignIn.sharedInstance().signOut()
    }
    
    func isValid(url: URL) -> Bool {
        return url.scheme!.hasPrefix(Bundle.main.bundleIdentifier!) || url.scheme!.hasPrefix("com.googleusercontent.apps.")
    }
}

extension GoogleAuth: GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Google Auth Error \(error.localizedDescription)")
            completion?(error, nil)
        } else {
            print("Google Auth Success")
            completion?(nil, user)
        }
        
    }
}

extension GoogleAuth: GIDSignInUIDelegate {
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        controller.present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true, completion: nil)
        
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
    }
}
