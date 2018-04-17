//
//  PremiumFirstDialog.swift
//  QueuedMusic
//
//  Created by Micky on 6/23/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

protocol PremiumFirstDialogDelegate: class {
    func premiumFirstVote(voteUp: Bool, track: Track)
    func regularVote(voteUp: Bool, track: Track)
}

class PremiumFirstDialog: UIViewController {
    
    weak var delegate: PremiumFirstDialogDelegate?
    var voteUp: Bool!
    var track: Track!
    
    init() {
        super.init(nibName: "PremiumFirstDialog", bundle: nil)
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
        delegate?.premiumFirstVote(voteUp: voteUp, track: track)
    }
    
    @IBAction func regularVote(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        delegate?.regularVote(voteUp: voteUp, track: track)
    }
}
