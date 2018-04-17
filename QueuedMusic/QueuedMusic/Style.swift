//
//  Style.swift
//  QueuedMusic
//
//  Created by Micky on 1/25/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

protocol AppearanceCustomizable {
    func apply()
}

struct AppAppearance: AppearanceCustomizable {
    func apply() {
        applyNavBarAppearance()
    }
    
    private func applyNavBarAppearance() {
        UINavigationBar.appearance().tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        UINavigationBar.appearance().barTintColor = #colorLiteral(red: 1, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName : UIFont(name: "Avenir-Heavy", size: 20) as Any, NSForegroundColorAttributeName : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSFontAttributeName : UIFont(name: "Avenir-Heavy", size: 14) as Any, NSForegroundColorAttributeName : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)], for: UIControlState.normal)
    }
}
