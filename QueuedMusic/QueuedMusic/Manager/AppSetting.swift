//
//  AppSetting.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Foundation

class AppSetting {
    
    static let shared: AppSetting = AppSetting()
    
    private init() { }
    
    private let notificationPermissionKey = "notification_permission_key"
    private let locationPermissionKey = "location_permission_key"
    private let walkthroughKey = "walkthrough_key"
    
    func isNotificationPermissionChecked() -> Bool {
        return UserDefaults.standard.bool(forKey: notificationPermissionKey)
    }
    
    func setNotificationPermissionChecked(_ checked: Bool) {
        UserDefaults.standard.set(checked, forKey: notificationPermissionKey)
    }
    
    func isLocationPermissionChecked() -> Bool {
        return UserDefaults.standard.bool(forKey: locationPermissionKey)
    }
    
    func setLocationPermissionChecked(_ checked: Bool) {
        UserDefaults.standard.set(checked, forKey: locationPermissionKey)
    }
    
    func isWalkthroughChecked() -> Bool {
        return UserDefaults.standard.bool(forKey: walkthroughKey)
    }
    
    func setWalkthroughChecked(_ checked: Bool) {
        UserDefaults.standard.set(checked, forKey: walkthroughKey)
    }
}
