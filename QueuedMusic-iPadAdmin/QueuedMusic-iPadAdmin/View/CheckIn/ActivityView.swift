//
//  UserView.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import AVFoundation

class ActivityView : UIView {
    @IBOutlet weak var activityView1: UIView!
    @IBOutlet weak var activityView2: UIView!
    @IBOutlet weak var activityView3: UIView!
    @IBOutlet weak var activityView4: UIView!
    @IBOutlet weak var activityView5: UIView!
    
    func initLabels() {
        self.activityView1.backgroundColor = #colorLiteral(red: 0.1951036453, green: 0.293051362, blue: 0.3496583104, alpha: 1)
        self.activityView2.backgroundColor = #colorLiteral(red: 0.1951036453, green: 0.293051362, blue: 0.3496583104, alpha: 1)
        self.activityView3.backgroundColor = #colorLiteral(red: 0.1951036453, green: 0.293051362, blue: 0.3496583104, alpha: 1)
        self.activityView4.backgroundColor = #colorLiteral(red: 0.1951036453, green: 0.293051362, blue: 0.3496583104, alpha: 1)
        self.activityView5.backgroundColor = #colorLiteral(red: 0.1951036453, green: 0.293051362, blue: 0.3496583104, alpha: 1)
    }
    
    func setNumber(num: Int!) {
        if num >= 1 {
            self.activityView1.backgroundColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
        }
        
        if num >= 2 {
            self.activityView2.backgroundColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
        }
        
        if num >= 3 {
            self.activityView3.backgroundColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
        }
        
        if num >= 4 {
            self.activityView4.backgroundColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
        }
        
        if num >= 5 {
            self.activityView5.backgroundColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
        }
    }
}
