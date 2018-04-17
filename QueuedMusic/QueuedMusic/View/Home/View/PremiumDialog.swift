//
//  PremiumDialog.swift
//  QueuedMusic
//
//  Created by Micky on 2/10/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

protocol PremiumDialogDelegate: class {
    func premiumVote(voteUp: Bool, track: Track)
}

class PremiumDialog: UIViewController {
    
    weak var delegate: PremiumDialogDelegate?
    var voteUp: Bool!
    var track: Track!
    
    init() {
        super.init(nibName: "PremiumDialog", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func premiumVote(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        delegate?.premiumVote(voteUp: voteUp, track: track)
    }
}
