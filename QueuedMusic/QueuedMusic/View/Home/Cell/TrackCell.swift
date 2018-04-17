//
//  QueueCell.swift
//  QueuedMusic
//
//  Created by Micky on 2/9/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import AudioIndicatorBars

class TrackCell: UITableViewCell {
    
    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var trackArtistLabel: UILabel!
    @IBOutlet weak var voteCountLabel: UILabel!
    @IBOutlet weak var voteUpButton: UIButton!
    @IBOutlet weak var voteDownButton: UIButton!
    @IBOutlet var audioIndicatorBar: AudioIndicatorBarsView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
