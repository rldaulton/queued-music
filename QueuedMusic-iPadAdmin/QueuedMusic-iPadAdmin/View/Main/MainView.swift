//
//  MainView.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import AVFoundation

public class MainView : UIView {
    
    @IBOutlet weak var venueNameLabel: UILabel!
    
    public func updateVenueNameLabel(name : String) {
        venueNameLabel.text = name
    }
}
