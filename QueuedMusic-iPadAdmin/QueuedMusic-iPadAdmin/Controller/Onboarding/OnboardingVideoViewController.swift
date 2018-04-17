//
//  SettingViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import XCDYouTubeKit

class OnboardingVideoViewController : BaseViewController {

    private let videoPlayerViewController = XCDYouTubeVideoPlayerViewController(videoIdentifier: "2l52omCsWx8")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doneButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "toMainController", sender: self)
    }
    
    @IBAction func playButtonClicked(_ sender: Any) {
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayerPlaybackDidFinish(_:)), name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish, object: videoPlayerViewController.moviePlayer)
        self.presentMoviePlayerViewControllerAnimated(videoPlayerViewController)
        self.videoPlayerViewController.moviePlayer.play()
    }
    
    func moviePlayerPlaybackDidFinish(_ notification: Notification!) {
        self.videoPlayerViewController.navigationController?.popViewController(animated: true)
    }
}
