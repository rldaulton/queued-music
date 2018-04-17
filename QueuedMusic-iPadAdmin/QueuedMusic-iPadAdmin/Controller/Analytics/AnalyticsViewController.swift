//
//  AnalyticsViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class AnalyticsViewController : BaseViewController {
    
    class func instance()->UIViewController{
        let homeController = UIStoryboard(name: "Analytics", bundle: nil).instantiateViewController(withIdentifier: "AnalyticsViewController")
        let nav = UINavigationController(rootViewController: homeController)
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.isHidden = true
        return nav
    }
    
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
}
