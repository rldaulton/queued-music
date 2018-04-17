//
//  SettingViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class OnboardingStartViewController : BaseViewController {
    
    @IBOutlet weak var laterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        laterButton.layer.masksToBounds = true
        laterButton.layer.borderColor = UIColor.gray.cgColor
        laterButton.layer.borderWidth = 2.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        EscrowSetupViewController.isEscrowSetting = false
        performSegue(withIdentifier: "toEscrowSetupController", sender: self)
    }
    
    @IBAction func laterButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "startToVideoController", sender: self)
    }
}
