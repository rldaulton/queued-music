//
//  TrackCell.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/24/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class CheckInCell: UITableViewCell {
    
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var pnsButton: UIButton!
    @IBOutlet weak var activityView: ActivityView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
