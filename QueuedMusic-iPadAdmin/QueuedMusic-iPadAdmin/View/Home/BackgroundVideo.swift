//
//  BackgroundVideo.swft
//  QueuedMusic
//
//  Created by Ryan Daulton on 2/8/17.
//  Copyright © 2017 Ryan Daulton. All rights reserved.
//

import UIKit
import AVFoundation

public class BackgroundVideo: UIView {

    private let screen = UIScreen.main.bounds

    private var player: AVPlayer?
    
    private func createAlpha(alpha: CGFloat) {
        let overlayView = UIView(frame: CGRect(x: screen.minX, y: screen.minY, width: screen.width, height: screen.height))
        overlayView.backgroundColor = UIColor.black
        overlayView.alpha = alpha
        self.addSubview(overlayView)
        self.sendSubview(toBack: overlayView)
    }
    
    public func createBackgroundVideo(url: String, type: String, alpha: CGFloat) {
        createAlpha(alpha: alpha)
        let path = Bundle.main.path(forResource: url, ofType: type)
        player = AVPlayer(url: URL(fileURLWithPath: path!))
        player!.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: screen.minX, y: screen.minY, width: screen.width, height: screen.height)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.layer.insertSublayer(playerLayer, at: 0)

        // Set observer for when video ends and loop video infinitely
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
        player!.seek(to: kCMTimeZero)
        player!.play()
    }
    
    @objc private func playerItemDidReachEnd() {
        // player!.seek(to: kCMTimeZero)
        self.viewController()?.navigationController?.popViewController(animated: true)
    }
}
