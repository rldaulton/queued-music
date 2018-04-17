//
//  VenueCell.swift
//  QueuedMusic
//
//  Created by Micky on 1/25/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class VenueCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var checkInButton: UIButton!
    @IBOutlet weak var locationImageView: UIImageView!
    
    override func awakeFromNib() {
        selectionStyle = .none
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        containerView.backgroundColor = highlighted ? #colorLiteral(red: 0.1215686275, green: 0.1450980392, blue: 0.1960784314, alpha: 1) : #colorLiteral(red: 0.168627451, green: 0.1960784314, blue: 0.262745098, alpha: 1)
    }
}
