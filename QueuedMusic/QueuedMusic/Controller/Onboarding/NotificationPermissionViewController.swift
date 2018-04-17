//
//  NotificationPermissionViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import UserNotifications
import PKHUD

class NotificationPermissionViewController: BaseViewController {
    
    private var isDialogPresented: Bool! = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isDialogPresented {
            let alertView = AlertView(title: "Turn On Smart Notifications",
                                      message: "You will get updates when important events happen, like your song playing, bar deals, or check in spots",
                                      okButtonTitle: "Yes!",
                                      cancelButtonTitle: "Not Now")
            alertView.delegate = self
            present(customModalViewController: alertView, centerYOffset: 50)
            isDialogPresented = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension NotificationPermissionViewController: AlertViewDelegate {
    func onOkButtonClicked() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                DispatchQueue.main.async {
                    AppSetting.shared.setNotificationPermissionChecked(true)
                    self.performSegue(withIdentifier: "notificationToLocationSegue", sender: self)
                }
            }
        } else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
            AppSetting.shared.setNotificationPermissionChecked(true)
            self.performSegue(withIdentifier: "notificationToLocationSegue", sender: self)
        }
        
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func onCancelButtonClicked() {
        AppSetting.shared.setNotificationPermissionChecked(false)
        self.performSegue(withIdentifier: "notificationToLocationSegue", sender: self)
    }
}
