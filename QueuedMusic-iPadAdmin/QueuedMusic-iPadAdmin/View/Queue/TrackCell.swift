//
//  TrackCell.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/24/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class TrackCell: UITableViewCell {
    
    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var trackArtistLabel: UILabel!
    @IBOutlet weak var voteCountLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
