//
//  EscrowTableCell.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 5/30/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class EscrowTableCell: UITableViewCell {
    
    @IBOutlet weak var transactionAmountLabel: UILabel!
    @IBOutlet weak var transactionTimeLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
