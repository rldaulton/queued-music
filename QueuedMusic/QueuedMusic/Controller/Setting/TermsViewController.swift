//
//  SupportViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/14/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class TermsViewController: BaseViewController {

    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.versionLabel.text = "1.8.1"
        
        self.webView.loadRequest(NSURLRequest(url: NSURL(string: "https://link-to-my-terms.html")! as URL) as URLRequest)
    }
}
