//
//  MainTabBarController.swift
//  QueuedMusic
//
//  Created by Micky on 2/7/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    var lastSelect: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self

        let checkInViewController = storyboard?.instantiateViewController(withIdentifier: "CheckInViewController") as! CheckInViewController
        let navController = UINavigationController(rootViewController: checkInViewController)
        present(navController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let rootViewController = (viewController as! UINavigationController).viewControllers.first
        if UserDataModel.shared.currentUser() == nil && !(rootViewController is HomeViewController) {
            let alertView = AlertView(title: "Warning", message: "You must sign in to view this content", okButtonTitle: "Login", cancelButtonTitle: "Cancel")
            alertView.delegate = self
            present(customModalViewController: alertView, centerYOffset: 0)
            return false
        }
        
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let rootViewController = (viewController as! UINavigationController).viewControllers.first
        if rootViewController is HomeViewController && rootViewController == lastSelect {
            NotificationCenter.default.post(name: .homeReselectedNotification, object: nil)
        }
        lastSelect = rootViewController
    }
}

extension MainTabBarController: AlertViewDelegate {
    func onOkButtonClicked() {
        _ = navigationController?.popToRootViewController(animated: true)
    }
}
