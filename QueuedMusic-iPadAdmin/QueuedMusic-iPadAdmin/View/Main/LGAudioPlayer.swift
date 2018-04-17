//
//  LGAudioPlayer.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 6/21/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//


import Foundation
import AVFoundation
import MediaPlayer
import AlamofireImage

let LGAudioPlayerOnTrackChangedNotification = "LGAudioPlayerOnTrackChangedNotification"
let LGAudioPlayerOnPlaybackStateChangedNotification = "LGAudioPlayerOnPlaybackStateChangedNotification"

public struct LGPlaybackItem {
    let trackName: String
    let albumName: String
    let artistName: String
}

extension LGPlaybackItem: Equatable {}
public func ==(lhs: LGPlaybackItem, rhs: LGPlaybackItem) -> Bool {
    return lhs.trackName == rhs.trackName
}

open class LGAudioPlayer: NSObject {
    
    //MARK: - Vars
    
    //var audioPlayer: AVAudioPlayer?
    open var playbackItems: [LGPlaybackItem]?
    open var currentPlaybackItem: LGPlaybackItem?
    open var nextPlaybackItem: LGPlaybackItem? {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return nil }
        
        let nextItemIndex = playbackItems.index(of: currentPlaybackItem)! + 1
        if nextItemIndex >= playbackItems.count { return nil }
        
        return playbackItems[nextItemIndex]
    }
    open var previousPlaybackItem: LGPlaybackItem? {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return nil }
        
        let previousItemIndex = playbackItems.index(of: currentPlaybackItem)! - 1
        if previousItemIndex < 0 { return nil }
        
        return playbackItems[previousItemIndex]
    }
    var nowPlayingInfo: [String : AnyObject]?
    
    open var currentTime: TimeInterval? {
        return 100 // self.audioPlayer?.currentTime
    }
    
    open var duration: TimeInterval? {
        return 300 // self.audioPlayer?.duration
    }
    
    var playingStatus: Bool! = false
    var hasNextTrack: Bool! = false
    var trackDuration: Int! = 0
    var currentPlayingTime: Int! = 0
    
    var queueViewController: QueueViewController! = nil
    
    //MARK: - Dependencies
    
    //let audioSession: AVAudioSession
    let commandCenter: MPRemoteCommandCenter
    let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    let notificationCenter: NotificationCenter
    
    //MARK: - Init
    
    typealias LGAudioPlayerDependencies = (audioSession: AVAudioSession, commandCenter: MPRemoteCommandCenter, nowPlayingInfoCenter: MPNowPlayingInfoCenter, notificationCenter: NotificationCenter)
    
    init(dependencies: LGAudioPlayerDependencies) {
        //self.audioSession = dependencies.audioSession
        self.commandCenter = dependencies.commandCenter
        self.nowPlayingInfoCenter = dependencies.nowPlayingInfoCenter
        self.notificationCenter = dependencies.notificationCenter
        
        super.init()
        
        //try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        //try! self.audioSession.setActive(true)
        
        
        self.configureCommandCenter()
    }
    
    //MARK: - Playback Commands
    
    func playItem(_ playbackItem: LGPlaybackItem) {
        self.currentPlaybackItem = playbackItem
        self.updateNowPlayingInfoForCurrentPlaybackItem()
        self.updateCommandCenter()
        
        self.notifyOnTrackChanged()
    }
    
    open func togglePlayPause() {
        if self.playingStatus == true {
            self.pause()
        }
        else {
            self.play()
        }
    }
    
    open func play() {
        self.updateNowPlayingPlaybackRate(rate: 1)
        self.queueViewController.playTrackSong()
        self.updateNowPlayingInfoElapsedTime()
    }
    
    open func pause() {
        self.updateNowPlayingPlaybackRate(rate: 0)
        if self.queueViewController.isTrackPlaying == false {
            self.queueViewController.isTrackPlaying = true
        }
        self.queueViewController.playTrackSong()
        self.updateNowPlayingInfoElapsedTime()
    }
    
    open func nextTrack() {
        self.disableButtons()
        self.updateNowPlayingPlaybackRate(rate: 0)
        self.queueViewController.moveToNextTrack()
    }
    
    func disableButtons() {
        self.commandCenter.previousTrackCommand.isEnabled = false
        self.commandCenter.nextTrackCommand.isEnabled = false
        self.commandCenter.playCommand.isEnabled = false
        self.commandCenter.pauseCommand.isEnabled = false
    }
    
    open func previousTrack() {
        
    }
    
    open func seekTo(_ timeInterval: TimeInterval) {
        //self.audioPlayer?.currentTime = timeInterval
        //self.updateNowPlayingInfoElapsedTime()
    }
    
    //MARK: - Command Center
    
    func updateCommandCenter() {
        self.commandCenter.previousTrackCommand.isEnabled = false
        self.commandCenter.nextTrackCommand.isEnabled = self.hasNextTrack
        self.commandCenter.playCommand.isEnabled = true
        self.commandCenter.pauseCommand.isEnabled = true
    }
    
    func configureCommandCenter() {
        self.commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.play()
            return .success
        })
        
        self.commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.pause()
            return .success
        })
        
        self.commandCenter.nextTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.nextTrack()
            return .success
        })
        
        self.commandCenter.previousTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.previousTrack()
            return .success
        })
        
    }
    
    func clearPlayingInfo() {
        let nowPlayingInfo = [MPMediaItemPropertyTitle: ""] as [String : Any]
        
        self.configureNowPlayingInfo(nowPlayingInfo as [String : AnyObject]?)
        
        self.updateNowPlayingInfoElapsedTime()
    }
    
    //MARK: - Now Playing Info
    
    func updateNowPlayingInfoForCurrentPlaybackItem() {
        guard let currentPlaybackItem = self.currentPlaybackItem else { return }
        
        let nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.trackName,
                              MPMediaItemPropertyAlbumTitle: currentPlaybackItem.albumName,
                              MPMediaItemPropertyArtist: currentPlaybackItem.artistName,
                              MPMediaItemPropertyPlaybackDuration: self.trackDuration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float),
                              MPNowPlayingInfoPropertyPlaybackProgress: "10.0"] as [String : Any]
        
        self.configureNowPlayingInfo(nowPlayingInfo as [String : AnyObject]?)
        
        self.updateNowPlayingInfoElapsedTime()
        
        self.updatePicture(url: self.queueViewController.albumImageURL)
    }
    
    func updatePicture(url: String?) {
        guard let url = url else { return }
        if url == "" {
            return
        }
        
        let urlRequest = URLRequest(url: URL(string: url)!)
        ImageDownloader.default.download(urlRequest) { (response) in
            if let image = response.result.value {
                guard var nowPlayingInfo = self.nowPlayingInfo else { return }
                
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
                
                self.configureNowPlayingInfo(nowPlayingInfo)
            }
        }
    }
    
    func updateNowPlayingPlaybackRate(rate: Int) {
        guard var nowPlayingInfo = self.nowPlayingInfo else { return }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: self.currentPlayingTime)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: rate)
        
        self.configureNowPlayingInfo(nowPlayingInfo)
    }
    
    func updateNowPlayingInfoElapsedTime() {
        guard var nowPlayingInfo = self.nowPlayingInfo else { return }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: self.currentPlayingTime)
        
        self.configureNowPlayingInfo(nowPlayingInfo)
    }
    
    func configureNowPlayingInfo(_ nowPlayingInfo: [String: AnyObject]?) {
        self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }
    
    //MARK: - Convenience
    
    func notifyOnPlaybackStateChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: LGAudioPlayerOnPlaybackStateChangedNotification), object: self)
    }
    
    func notifyOnTrackChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: LGAudioPlayerOnTrackChangedNotification), object: self)
    }
}
