//
//  QueueViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import CoreStore
import Whisper
import DGElasticPullToRefresh
import Spotify
import AlamofireImage
import AVFoundation

protocol TrackDataSourceDelegate: class {
    func dataSourceDidCompleteLoad(_ dataSource: TrackDataSource, tracks: [Track]?)
    func removeTrack(track: Track, index: Int)
}

protocol TrackConfigurable {
    func configure(with track: Track?)
}

protocol TrackCellConfigurable: TrackConfigurable {
    var trackTitleLabel: UILabel! { get set }
    var trackArtistLabel: UILabel! { get set }
    var voteCountLabel: UILabel! { get set }
    var removeButton: UIButton! { get set }
}

extension TrackCellConfigurable {
    func configure(with track: Track?) {
        trackTitleLabel.text = track?.name
        trackArtistLabel.text = track?.artist
        if let voteCount = track?.voteCount {
            voteCountLabel.text = "\(voteCount)"
        }
    }
}

extension TrackCell: TrackCellConfigurable { }

class TrackDataSource: NSObject, UITableViewDataSource {
    weak var delegate: TrackDataSourceDelegate?
    var tracks: [Track] = []
    
    func load(venueId: String) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        QueueDataModel.shared.loadQueue(venueId: venueId) { (tracks) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.delegate?.dataSourceDidCompleteLoad(self, tracks: tracks)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackCell
        
        let track = tracks[indexPath.item]
        (cell as TrackConfigurable).configure(with: track)
        
        cell.removeButton.tag = indexPath.item
        cell.removeButton.addTarget(self, action: #selector(removeTrack(sender:)), for: .touchUpInside)
        
        cell.contentView.backgroundColor = indexPath.row == 0 && track.playing! == true ? #colorLiteral(red: 0.1565925479, green: 0.1742246747, blue: 0.2227806747, alpha: 1) : #colorLiteral(red: 0.1614608765, green: 0.1948977113, blue: 0.2560786903, alpha: 1)
        
        if indexPath.row == 0 && track.playing! == true {
            cell.removeButton.isHidden = true
        } else {
            cell.removeButton.isHidden = false
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    
    @IBAction func removeTrack(sender: UIButton) {
        delegate?.removeTrack(track: tracks[sender.tag], index: sender.tag)
    }
}

class QueueViewController : BaseViewController {
    
    @IBOutlet weak var trackTableView: UITableView!
    @IBOutlet weak var emptyQueueImageView: UIImageView!
    @IBOutlet weak var trackTitleLabel : UILabel!
    @IBOutlet weak var trackArtistLabel : UILabel!
    @IBOutlet weak var playingProgress : UIProgressView!
    @IBOutlet weak var volumeSlider : UISlider!
    @IBOutlet weak var playingTimeLabel : UILabel!
    @IBOutlet weak var trackImageView : UIImageView!
    @IBOutlet weak var playButton : UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var playlistTakeoverImageView: UIImageView!
    
    var loadingView: DGElasticPullToRefreshLoadingViewCircle!
    var refreshing: Bool!
    
    var url: URL!
    var currentTrack : SPTPartialTrack!
    var removeTrack: Track!
    var takeoverTracks: [SPTPartialTrack] = []
    
    var venue: Venue!
    let dataSource = TrackDataSource()
    
    var currentTrackPlayingTime : Int!
    var playingTime: Int!
    var isTrackPlaying: Bool!
    var hasPlayingTrack: Bool!
    var isSkipTrack: Bool!
    var selectedTrackIndex: Int! = 0
    var isPlayingStatusUpdate: Bool!
    var pendingSelectedTrackIndex: Int!
    var isFirstSongRemoved: Bool! = false
    var isTakeoverPlaying: Bool! = false
    var isRemoveQueue: Bool! = false
    
    var albumImageURL: String! = ""
    var timer = Timer()
    
    var player: SPTAudioStreamingController?
    
    static var userTracks: [Track] = []
    
    //MARK: - Dependencies
    
    var lgPlayer: LGAudioPlayer! = nil
    var notificationCenter: NotificationCenter! = nil
    var bundle: Bundle! = nil
    
    class func instance()->UIViewController{
        let homeController = UIStoryboard(name: "Queue", bundle: nil).instantiateViewController(withIdentifier: "QueueViewController")
        let nav = UINavigationController(rootViewController: homeController)
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.isHidden = true
        return nav
    }
    
    func showProgressBar() {
        self.activityIndicatorView.startAnimating()
        self.activityView.isHidden = false
    }
    
    func hideProgressBar() {
        self.activityIndicatorView.stopAnimating()
        self.activityView.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.playingProgress.setProgress(0, animated: false)
        
        dataSource.delegate = self
        trackTableView.dataSource = dataSource
        trackTableView.tableFooterView = UIView()
        
        loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = #colorLiteral(red: 0.9999966025, green: 0.9999999404, blue: 0.9999999404, alpha: 1)
        playingProgress.trackTintColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        playingProgress.progressTintColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
        
        volumeSlider.tintColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        
        venue = VenueDataModel.shared.currentVenue
        
        loadingView.startAnimating()
        self.refreshing = true
        dataSource.tracks.removeAll()
        trackTableView.reloadData()
        dataSource.load(venueId: venue.venueId)
        
        self.isTrackPlaying = false
        self.hasPlayingTrack = false
        self.isSkipTrack = false
        self.isPlayingStatusUpdate = false
        
        self.preparePlayer()
        
        self.volumeSlider.setValue(0.5, animated: false)
        self.hideProgressBar()
        
        self.lgPlayer = MainViewController.dependencies.player
        self.notificationCenter = MainViewController.dependencies.notificationCenter
        self.bundle = MainViewController.dependencies.bundle
        self.lgPlayer.queueViewController = self
        
        self.configureNotifications()
    }
    
    deinit {
        self.notificationCenter.removeObserver(self)
    }
    
    //MARK: - Notifications
    
    func configureNotifications() {
        self.notificationCenter.addObserver(self, selector: #selector(onTrackAndPlaybackStateChange), name: NSNotification.Name(rawValue: LGAudioPlayerOnTrackChangedNotification), object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(onTrackAndPlaybackStateChange), name: NSNotification.Name(rawValue: LGAudioPlayerOnPlaybackStateChangedNotification), object: nil)
    }
    
    func onTrackAndPlaybackStateChange() {
        self.updatePlayerButton(animated: true)
        
    }
    
    //MARK: - Updates
    
    func updatePlayerButton(animated: Bool) {
        /*let updateView = {
         if self.player.currentPlaybackItem == nil {
         self.playerButtonHeight.constant = 0
         self.playerButton.alpha = 0
         }
         else {
         self.playerButtonHeight.constant = 50
         self.playerButton.alpha = 1
         }
         self.view.layoutIfNeeded()
         }
         
         if animated {
         UIView.animate(withDuration: 0.5, delay: 0, options: .beginFromCurrentState, animations: updateView, completion: nil)
         }
         else {
         updateView()
         }*/
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        self.player?.setVolume(SPTVolume(self.volumeSlider.value), callback: nil)
    }
    
    @IBAction func back(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(sender: UIRefreshControl?) {
        if let venueId = venue.venueId {
            emptyQueueImageView.isHidden = true
            playlistTakeoverImageView.isHidden = true
            dataSource.load(venueId: venueId)
        }
    }
    
    @IBAction func refreshTracks(_ sender: Any) {
    
    }
 
    @IBAction func playTrack(_ sender: Any) {
        self.playTrackSong()
    }
    
    func playTrackSong() {
        if isTrackPlaying == true {
            self.isTrackPlaying = false
            self.timer.invalidate()
            if self.player?.loggedIn == true {
                self.player?.setIsPlaying(false, callback: nil)
            }
            
            if let image = UIImage(named: "ic_play") {
                playButton.setImage(image, for: .normal)
            }
            self.lgPlayer.notifyOnPlaybackStateChanged()
        } else {
            if self.hasPlayingTrack == true {
                if self.player?.loggedIn == true {
                    self.player?.setIsPlaying(true, callback: nil)
                    
                    self.isTrackPlaying = true
                    if self.timer.isValid == true {
                        self.timer.invalidate()
                    }
                    
                    if let image = UIImage(named: "ic_pause") {
                        playButton.setImage(image, for: .normal)
                    }
                    
                    self.lgPlayer.notifyOnPlaybackStateChanged()
                    
                    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updatePlayingTime), userInfo: nil, repeats: true)
                }
            } else {
                self.playNewTrack()
            }
        }
    }
    
    func playNewTrack() {
        if self.dataSource.tracks.count == 0 {
            let track = self.takeoverTracks[0]
            
            self.preparePlayer()
            
            if self.player?.loggedIn == true {
                self.player?.setIsPlaying(false, callback: nil)
                
                self.showProgressBar()
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                
                self.hasPlayingTrack = true
                
                let trackId = track.uri.absoluteString.replacingOccurrences(of: "spotify:track:", with: "")
                
                if self.dataSource.tracks.count == 1 {
                    loadTakeoverTracks()
                }
                
                self.isTakeoverPlaying = true
                
                self.playlistTakeoverImageView.isHidden = false
                
                self.player?.playSpotifyURI(String.init(format: "spotify:track:%@", trackId), startingWith: 0, startingWithPosition: 0, callback: { (error) in
                    if error != nil {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.hideProgressBar()
                    }
                })
                
                self.player?.setRepeat(SPTRepeatMode.off, callback: nil)
            } else {
                let alertView = AlertView(title: "Warning", message: "Spotify Premium Required!", okButtonTitle: "OK", cancelButtonTitle: nil)
                alertView.delegate = nil
                self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
            }
        } else {
            let track = self.dataSource.tracks[self.selectedTrackIndex]
            
            self.preparePlayer()
            
            if self.player?.loggedIn == true {
                self.player?.setIsPlaying(false, callback: nil)
                
                self.showProgressBar()
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                
                self.hasPlayingTrack = true
                
                let trackId = track.trackId.replacingOccurrences(of: "spotify:track:", with: "")
                
                if self.dataSource.tracks.count == 1 {
                    loadTakeoverTracks()
                }
                
                self.isTakeoverPlaying = false
                self.playlistTakeoverImageView.isHidden = true
                
                self.player?.playSpotifyURI(String.init(format: "spotify:track:%@", trackId), startingWith: 0, startingWithPosition: 0, callback: { (error) in
                    if error != nil {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.hideProgressBar()
                    }
                })
                
                self.player?.setRepeat(SPTRepeatMode.off, callback: nil)
                //self.lgPlayer.playItems(self.playlist, firstItem: self.playlist[0])
            } else {
                let alertView = AlertView(title: "Warning", message: "Spotify Premium Required!", okButtonTitle: "OK", cancelButtonTitle: nil)
                alertView.delegate = nil
                self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
            }
        }
    }
    
    func loadTakeoverTracks() {
        if UserDataModel.shared.currentUser()?.allowPlayback == "true" && UserDataModel.shared.currentUser()?.takeoverID != "" {
            SpotifyManager.shared.loadSonglist(url: NSURL(string: (UserDataModel.shared.currentUser()?.takeoverID)!) as URL!, listPage: nil, completion: { (listPage) in
                self.takeoverTracks.removeAll()
                if let items = listPage?.items {
                    for item in items {
                        if let track = item as? SPTPartialTrack {
                            self.takeoverTracks.append(track)
                        }
                    }
                }
            })
        }
    }
    
    func updatePlayingStatus(status: Bool!) {
        if self.dataSource.tracks.count > 0 {
            let track = self.dataSource.tracks[self.selectedTrackIndex]
            
            self.isPlayingStatusUpdate = true
            
            venue = VenueDataModel.shared.currentVenue
            
            let venueId = venue.venueId!
            let trackId = track.trackId!
            
            QueueDataModel.shared.updatePlayingStatus(venueId: venueId, trackId: trackId, status: status) { (error) in
                
            }
        }
    }
    
    func preparePlayer() {
        if self.player != nil {
            if self.player?.loggedIn == true {
                return
            }
        }
        
        guard let auth = SPTAuth.defaultInstance() else { return }
        
        SpotifyManager.shared.refreshSession {
            do {
                if self.player == nil {
                    self.player = SPTAudioStreamingController.sharedInstance()
                    self.player?.delegate = self
                    self.player?.playbackDelegate = self
                    try self.player?.start(withClientId: "spotify-cliend-id")
                }
                
                if self.player?.loggedIn == false {
                    self.player?.login(withAccessToken: auth.session.accessToken)
                }
            } catch {
                print("error")
            }
        }
    }
    
    @IBAction func nextTrack(_ sender: Any) {
        if self.selectedTrackIndex + 1 >= self.dataSource.tracks.count {
            return
        }
        
        if timer.isValid == true {
            timer.invalidate()
        }
        
        let alertView = AlertView(title: "", message: "Would you like to override the queue and skip to the next track in the queue?" , okButtonTitle: "Yes", cancelButtonTitle: "No")
        alertView.delegate = self
        alertView.setTagIndex(index: 3000)
        self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
    }
    
    func getTrack(trackId: String!) {
        let trackId = trackId.replacingOccurrences(of: "spotify:track:", with: "")
        
        if self.timer.isValid == true {
            self.timer.invalidate()
        }
        
        self.playingTimeLabel.text = self.getTimeLabel(timeInSeconds: 0) //self.getTimeLabel(timeInSeconds: self.currentTrackPlayingTime)
        
        self.playingTime = 0
        self.lgPlayer.currentPlayingTime = self.playingTime
        self.playingProgress.setProgress(0, animated: false)
        
        if self.player?.loggedIn == true {
            self.player?.setIsPlaying(false, callback: nil)
        }
        self.isTrackPlaying = false
        self.hasPlayingTrack = false
        
        self.trackImageView.image = nil
        
        if let image = UIImage(named: "ic_play") {
            playButton.setImage(image, for: .normal)
        }
        
        self.showProgressBar()

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let url = URL.init(string: String.init(format: "spotify:track:%@", trackId))
        
        SpotifyManager.shared.getTrackWithSpotifySDK(url: url!) { (track) in
            self.hideProgressBar()
            
            if track == nil || track?.album == nil {
                let alertView = AlertView(title: "Warning", message: "No track info!", okButtonTitle: "OK", cancelButtonTitle: nil)
                alertView.delegate = nil
                self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
            } else {
                let cover = track?.album.largestCover
                
                self.albumImageURL = cover?.imageURL?.absoluteString
                
                let filter = ScaledToSizeWithRoundedCornersFilter(size:self.trackImageView.bounds.size, radius: 0)
                self.trackImageView.af_setImage(withURL: (cover?.imageURL!)!, filter: filter)
                
                self.currentTrackPlayingTime = Int((track?.duration)!)
                
                var artists: [String] = []
                if let artistList = track?.artists as? [SPTPartialArtist] {
                    artists = artistList.map{ $0.name! }
                }
                
                self.trackTitleLabel.text = track?.name
                self.trackArtistLabel.text = artists.joined(separator: ",")
                
                self.playlistTakeoverImageView.isHidden = !self.isTakeoverPlaying
                
                if self.isSkipTrack == true {
                    self.isSkipTrack = false
                    self.playNewTrack()
                }
            }
        }
    }
    
    public func getTimeLabel(timeInSeconds: Int!) -> String	 {
        let min = timeInSeconds / 60
        let sec = timeInSeconds - (min * 60)
        
        var timeLabel = ""
        if min < 10 {
            timeLabel = String.init(format: "0%d", min)
        } else {
            timeLabel = String.init(format: "%d", min)
        }
        
        if sec < 10 {
            timeLabel = String.init(format: "%@:0%d", timeLabel, sec)
        } else {
            timeLabel = String.init(format: "%@:%d", timeLabel, sec)
        }
        
        return timeLabel
    }
    
    func playNextTakeoverTrack() {
        let track = self.takeoverTracks[0]
        
        self.preparePlayer()
        
        if self.player?.loggedIn == true {
            self.player?.setIsPlaying(false, callback: nil)
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            self.hasPlayingTrack = true
            
            let trackId = track.uri.absoluteString.replacingOccurrences(of: "spotify:track:", with: "")
            
            self.isTakeoverPlaying = true
            
            self.playlistTakeoverImageView.isHidden = false
            
            self.player?.playSpotifyURI(String.init(format: "spotify:track:%@", trackId), startingWith: 0, startingWithPosition: 0, callback: { (error) in
                if error != nil {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            })
            
            self.player?.setRepeat(SPTRepeatMode.off, callback: nil)
        } else {
            
        }
    }
    
    public func updatePlayingTime() {
        if self.playingTime >= self.currentTrackPlayingTime {
            self.hasPlayingTrack = false
            self.isTrackPlaying = false
            timer.invalidate()
            self.lgPlayer.disableButtons()
            
            if let image = UIImage(named: "ic_play") {
                playButton.setImage(image, for: .normal)
            }
            
            self.player?.setIsPlaying(false, callback: nil)
            
            self.playNextTrack()
            
            return
        }
        
        self.playingTime = self.playingTime + 1
        self.lgPlayer.currentPlayingTime = self.playingTime
        
        let percent = Float(self.playingTime) / Float(self.currentTrackPlayingTime)
        
        self.playingProgress.setProgress(percent, animated: true)
        
        self.playingTimeLabel.text = self.getTimeLabel(timeInSeconds: self.playingTime)
    }
}

extension QueueViewController: SPTAudioStreamingPlaybackDelegate {
    public func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
        self.hideProgressBar()
        
        if self.hasPlayingTrack == true {
            if self.currentTrackPlayingTime != nil && self.playingTime != nil && self.currentTrackPlayingTime > 2 && self.playingTime + 1 >= self.currentTrackPlayingTime {
                self.hasPlayingTrack = false
                self.isTrackPlaying = false
                timer.invalidate()
                self.lgPlayer.disableButtons()
                
                if let image = UIImage(named: "ic_play") {
                    playButton.setImage(image, for: .normal)
                }
                
                self.player?.setIsPlaying(false, callback: nil)
                
                self.playNextTrack()
                
                return
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            self.isTrackPlaying = true
            if self.timer.isValid == true {
                self.timer.invalidate()
            }
            
            if let image = UIImage(named: "ic_pause") {
                playButton.setImage(image, for: .normal)
            }
            
            self.playingTime = 0
            self.lgPlayer.currentPlayingTime = self.playingTime
            self.playingProgress.setProgress(0, animated: false)
            
            self.emptyQueueImageView.isHidden = true
            
            if self.dataSource.tracks.count > 0 {
                let track = self.dataSource.tracks[0]
                
                self.lgPlayer.playingStatus = true
                self.lgPlayer.trackDuration = self.currentTrackPlayingTime
                if self.dataSource.tracks.count > 1 {
                    self.lgPlayer.hasNextTrack = true
                } else {
                    if UserDataModel.shared.currentUser()?.allowPlayback == "true" && UserDataModel.shared.currentUser()?.takeoverID != "" {
                        self.lgPlayer.hasNextTrack = self.takeoverTracks.count > 1
                    }
                }
                
                let playbackItem1 = LGPlaybackItem(trackName: track.name!,
                                                   albumName: track.name!,
                                                   artistName: track.artist!)
                
                self.trackTitleLabel.text = track.name
                self.trackArtistLabel.text = track.artist
                
                self.lgPlayer.playItem(playbackItem1)
            } else {
                let track = self.takeoverTracks[0]
                
                self.lgPlayer.playingStatus = true
                self.lgPlayer.trackDuration = self.currentTrackPlayingTime
                self.lgPlayer.hasNextTrack = self.takeoverTracks.count > 1
                
                self.albumImageURL = track.album.largestCover.imageURL.absoluteString
                
                let filter = ScaledToSizeWithRoundedCornersFilter(size:self.trackImageView.bounds.size, radius: 0)
                self.trackImageView.af_setImage(withURL: track.album.largestCover.imageURL, filter: filter)
                
                var artists: [String] = []
                if let artistList = track.artists as? [SPTPartialArtist] {
                    artists = artistList.map{ $0.name! }
                }
                
                let playbackItem1 = LGPlaybackItem(trackName: track.name!,
                                                   albumName: track.name!,
                                                   artistName: artists.joined(separator: ","))
                
                self.trackTitleLabel.text = track.name
                self.trackArtistLabel.text = artists.joined(separator: ",")
                
                self.lgPlayer.playItem(playbackItem1)
            }
            
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updatePlayingTime), userInfo: nil, repeats: true)
            
            self.player?.setVolume(SPTVolume(self.volumeSlider.value), callback: nil)
            
            self.updatePlayingStatus(status: true)
        } else {
            self.player?.setIsPlaying(false, callback: nil)
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func moveToNextTrack() {
        if timer.isValid == true {
            timer.invalidate()
        }
        
        if self.player?.loggedIn == true {
            self.player?.setIsPlaying(false, callback: nil)
        }
        
        self.isSkipTrack = true
        
        self.isTrackPlaying = false
        self.hasPlayingTrack = false
        
        if self.dataSource.tracks.count == 0 {
            if UserDataModel.shared.currentUser()?.allowPlayback == "true" && UserDataModel.shared.currentUser()?.takeoverID != "" {
                if self.takeoverTracks.count == 0 {
                    return
                }
                self.takeoverTracks.remove(at: 0)
                
                if self.takeoverTracks.count == 0 {
                    return
                }
                
                self.playNextTakeoverTrack()
            }
            
            return;
        }
        
        let track = self.dataSource.tracks[self.selectedTrackIndex]
        
        venue = VenueDataModel.shared.currentVenue
        
        let venueId = venue.venueId!
        let trackId = track.trackId!
        
        QueueDataModel.shared.removeQueue(venueId: venueId, trackId: trackId) { (error) in
            if error == nil {
                if self.dataSource.tracks.count == 0 {
                    if UserDataModel.shared.currentUser()?.allowPlayback == "true" && UserDataModel.shared.currentUser()?.takeoverID != "" {
                        self.playNextTakeoverTrack()
                    }
                    
                    return;
                }
                self.selectedTrackIndex = 0
                let track = self.dataSource.tracks[self.selectedTrackIndex]
                
                self.trackTitleLabel.text = track.name
                self.trackArtistLabel.text = track.artist
                
                self.getTrack(trackId: track.trackId)
            }
        }
    }
}

extension QueueViewController: SPTAudioStreamingDelegate {
    public func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        print("error")
        print(error)
        
        //Spotify Premium Required
    }
    
    public func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("logged in")
    }
    
    public func audioStreamingDidEncounterTemporaryConnectionError(_ audioStreaming: SPTAudioStreamingController!) {
        print("did encounter connection error")
    }
    
    public func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveMessage message: String!) {
        print("audio streaming")
    }
    
    public func audioStreamingDidDisconnect(_ audioStreaming: SPTAudioStreamingController!) {
        print("disconnect")
    }
    
    public func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController!) {
        print("logout")
    }
}

extension QueueViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension QueueViewController: TrackDataSourceDelegate {
    func dataSourceDidCompleteLoad(_ dataSource: TrackDataSource, tracks: [Track]?) {
        if self.refreshing == true {
            var sortedTracks = tracks?.sorted(by: {
                if $0.voteCount == $1.voteCount {
                    return $0.added!.compare($1.added!) == .orderedAscending
                }
                return $0.voteCount > $1.voteCount
            })
            if dataSource.tracks.count > 0, (sortedTracks?.count)! > 0, let newTracks = sortedTracks {
                var swapPair = [Int:Int]()
                for i in 0..<newTracks.count {
                    let newTrack = newTracks[i]
                    var oldIndex = 0
                    var exists = false
                    for j in 0..<dataSource.tracks.count {
                        if newTrack.trackId == dataSource.tracks[j].trackId {
                            oldIndex = j
                            exists = true
                            break
                        }
                    }
                    if exists {
                        var newIndex = oldIndex
                        for k in oldIndex + 1..<dataSource.tracks.count {
                            if dataSource.tracks[oldIndex].voteCount < dataSource.tracks[k].voteCount {
                                newIndex = k
                            } else if dataSource.tracks[oldIndex].voteCount == dataSource.tracks[k].voteCount && dataSource.tracks[oldIndex].added!.compare(dataSource.tracks[k].added!) == .orderedDescending {
                                newIndex = k
                            }
                        }
                        if newIndex == oldIndex && oldIndex > 0 {
                            for k in (0..<oldIndex).reversed() {
                                if dataSource.tracks[oldIndex].voteCount > dataSource.tracks[k].voteCount {
                                    newIndex = k
                                } else if dataSource.tracks[oldIndex].voteCount == dataSource.tracks[k].voteCount && dataSource.tracks[oldIndex].added!.compare(dataSource.tracks[k].added!) == .orderedAscending {
                                    newIndex = k
                                }
                            }
                        }
                        if newIndex != oldIndex && swapPair[newIndex] != oldIndex {
                            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                                self.trackTableView.beginUpdates()
                                self.trackTableView.moveRow(at: IndexPath(row: oldIndex, section: 0), to: IndexPath(row: newIndex, section: 0))
                                let oldTrack = dataSource.tracks.remove(at: oldIndex)
                                dataSource.tracks.insert(oldTrack, at: newIndex)
                                swapPair[oldIndex] = newIndex
                                self.trackTableView.endUpdates()
                            }, completion: nil)
                        }
                    } else {
                        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                            self.trackTableView.beginUpdates()
                            self.trackTableView.insertRows(at: [IndexPath(row: dataSource.tracks.count + 1, section: 0)], with: .fade)
                            dataSource.tracks.append(newTrack)
                            self.trackTableView.endUpdates()
                        }, completion: nil)
                    }
                }
                for (index, track) in dataSource.tracks.enumerated() {
                    if track.playing == true {
                        dataSource.tracks.remove(at: index)
                        dataSource.tracks.insert(track, at: 0)
                        break
                    }
                }
                
                self.trackTableView.reloadData()
            } else {
                for (index, track) in (sortedTracks?.enumerated())! {
                    if track.playing == true {
                        sortedTracks?.remove(at: index)
                        sortedTracks?.insert(track, at: 0)
                        break
                    }
                }
                
                dataSource.tracks = sortedTracks!
                trackTableView.reloadData()
            }
            // to fix the elastic pull-to-refresh bug that doesn't disappear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.trackTableView.setContentOffset(.zero, animated: true)
            })
            self.refreshing = false
            
            if dataSource.tracks.count > 0 {
                self.selectedTrackIndex = 0
                let track = self.dataSource.tracks[self.selectedTrackIndex]
                
                self.trackTitleLabel.text = track.name
                self.trackArtistLabel.text = track.artist
                
                self.getTrack(trackId: track.trackId)
            }
        } else {
            if dataSource.tracks.count == 0 && tracks?.count == 1 {
                self.selectedTrackIndex = 0
                let track = tracks?[self.selectedTrackIndex]
                
                self.trackTitleLabel.text = track?.name
                self.trackArtistLabel.text = track?.artist
                
                if self.isRemoveQueue == false {
                    self.getTrack(trackId: track?.trackId)
                }
            }
            
            for (index, oldTrack) in dataSource.tracks.enumerated() {
                var exists = false
                for newTrack in tracks! {
                    if oldTrack.trackId == newTrack.trackId {
                        exists = true
                        oldTrack.voteCount = newTrack.voteCount
                        oldTrack.playing = newTrack.playing
                        break
                    }
                }
                if !exists {
                    dataSource.tracks.remove(at: index)
                }
            }
            
            for newTrack in tracks! {
                var exists = false
                for oldTrack in dataSource.tracks {
                    if newTrack.trackId == oldTrack.trackId {
                        exists = true
                        break
                    }
                }
                if !exists {
                    dataSource.tracks.append(newTrack)
                }
            }
            
            var sortedTracks = tracks?.sorted(by: {
                if $0.voteCount == $1.voteCount {
                    return $0.added!.compare($1.added!) == .orderedAscending
                }
                return $0.voteCount > $1.voteCount
            })
            
            for (index, track) in (sortedTracks?.enumerated())! {
                if track.playing == true {
                    sortedTracks?.remove(at: index)
                    sortedTracks?.insert(track, at: 0)
                    break
                }
            }
            
            if dataSource.tracks.count == 0 {
                dataSource.tracks = sortedTracks!
            } else {
                let playingTrack = dataSource.tracks[0]
                if playingTrack.playing! == true {
                    for (index, newTrack) in sortedTracks!.enumerated() {
                        if newTrack.trackId == playingTrack.trackId {
                            sortedTracks?.remove(at: index)
                            break
                        }
                    }
                    
                    sortedTracks?.insert(playingTrack, at: 0)
                }
                
                dataSource.tracks = sortedTracks!
                
                let newFirstTrack = dataSource.tracks[0]
                let flag = self.isFirstSongRemoved == true ? true : newFirstTrack.trackId != playingTrack.trackId
                
                if flag == true && self.isPlayingStatusUpdate == false {
                    self.selectedTrackIndex = 0
                    let track = self.dataSource.tracks[self.selectedTrackIndex]
                    
                    self.trackTitleLabel.text = track.name
                    self.trackArtistLabel.text = track.artist
                    
                    if self.isRemoveQueue == false {
                        self.getTrack(trackId: track.trackId)
                    }
                }
                
                if self.isPlayingStatusUpdate == true {
                    self.isPlayingStatusUpdate = false
                }
            }
            
            trackTableView.reloadData()
        }
        
        if dataSource.tracks.count == 0 {
            self.playButton.isEnabled = false
            self.nextButton.isEnabled = false
            if self.isTakeoverPlaying == false {
                self.trackTitleLabel.text = "No title"
                self.trackArtistLabel.text = "No artist"
                self.trackImageView.image = nil
            }
        } else {
            self.playButton.isEnabled = true
            if dataSource.tracks.count == 1 {
                self.nextButton.isEnabled = false
            } else {
                self.nextButton.isEnabled = true
            }
        }
        
        if self.isRemoveQueue == true {
            self.selectedTrackIndex = 0
            self.isRemoveQueue = false
            if self.dataSource.tracks.count == 0 {
                if UserDataModel.shared.currentUser()?.allowPlayback == "true" && UserDataModel.shared.currentUser()?.takeoverID != "" {
                    if self.takeoverTracks.count > 0 {
                        let track = self.takeoverTracks[self.selectedTrackIndex]
                        
                        var artists: [String] = []
                        if let artistList = track.artists as? [SPTPartialArtist] {
                            artists = artistList.map{ $0.name! }
                        }
                        
                        self.trackTitleLabel.text = track.name
                        self.trackArtistLabel.text = artists.joined(separator: ",")
                        
                        self.isSkipTrack = true
                        
                        self.getTrack(trackId: track.uri.absoluteString)
                    } else {
                        self.trackTitleLabel.text = "No title"
                        self.trackArtistLabel.text = "No artist"
                        
                        self.emptyQueueImageView.isHidden = false
                        self.lgPlayer.clearPlayingInfo()
                    }
                } else {
                    self.trackTitleLabel.text = "No title"
                    self.trackArtistLabel.text = "No artist"
                    
                    self.emptyQueueImageView.isHidden = false
                    self.lgPlayer.clearPlayingInfo()
                }
                
                return
            }
            
            let track = self.dataSource.tracks[self.selectedTrackIndex]
            
            self.trackTitleLabel.text = track.name
            self.trackArtistLabel.text = track.artist
            
            self.isSkipTrack = true
            self.isTakeoverPlaying = false
            self.playlistTakeoverImageView.isHidden = true
            
            self.getTrack(trackId: track.trackId)
        }
        
        QueueViewController.userTracks = dataSource.tracks
        
        if self.isTakeoverPlaying == true {
            self.playButton.isEnabled = false
            self.nextButton.isEnabled = false
        }
        
        emptyQueueImageView.isHidden = (tracks?.count)! > 0
        if self.isTakeoverPlaying == true {
            emptyQueueImageView.isHidden = true
            playlistTakeoverImageView.isHidden = false
        } else {
            playlistTakeoverImageView.isHidden = true
        }
        
        if let first = dataSource.tracks.first {
            trackTableView.dg_setPullToRefreshBackgroundColor(first.playing! ? #colorLiteral(red: 0.1565925479, green: 0.1742246747, blue: 0.2227806747, alpha: 1) : #colorLiteral(red: 0.1614608765, green: 0.1948977113, blue: 0.2560786903, alpha: 1))
        }
    }
    
    func removeTrack(track: Track, index: Int) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: 10000), execute: {
            self.removeTrack = track
            if index == 0 {
                self.isFirstSongRemoved = true
            } else {
                self.isFirstSongRemoved = false
            }
            let alertView = AlertView(title: "", message:String(format: "Are you sure you want to remove %@ by %@ from the current queue?", (track.name)!, track.artist!) , okButtonTitle: "Remove", cancelButtonTitle: "Cancel")
            alertView.delegate = self
            alertView.setTagIndex(index: 1000)
            self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
        })
    }
    
    func playNextTrack() {
        if self.dataSource.tracks.count == 0 {
            if UserDataModel.shared.currentUser()?.allowPlayback == "true" && UserDataModel.shared.currentUser()?.takeoverID != "" {
                self.takeoverTracks.remove(at: 0)
                
                if self.takeoverTracks.count > 0 {
                    let track = self.takeoverTracks[0]
                    
                    var artists: [String] = []
                    if let artistList = track.artists as? [SPTPartialArtist] {
                        artists = artistList.map{ $0.name! }
                    }
                    
                    self.trackTitleLabel.text = track.name
                    self.trackArtistLabel.text = artists.joined(separator: ",")
                    
                    self.isSkipTrack = true
                    self.isTakeoverPlaying = true
                    
                    self.playlistTakeoverImageView.isHidden = false
                    
                    self.getTrack(trackId: track.uri.absoluteString)
                } else {
                    self.trackTitleLabel.text = "No title"
                    self.trackArtistLabel.text = "No artist"
                    
                    self.emptyQueueImageView.isHidden = false
                    self.lgPlayer.clearPlayingInfo()
                }
            } else {
                self.trackTitleLabel.text = "No title"
                self.trackArtistLabel.text = "No artist"
                
                self.emptyQueueImageView.isHidden = false
                self.lgPlayer.clearPlayingInfo()
            }
            
            return
        }
        
        if timer.isValid == true {
            timer.invalidate()
        }
        
        if self.player?.loggedIn == true {
            self.player?.setIsPlaying(false, callback: nil)
        }
        
        if self.isTrackPlaying == true {
            self.isSkipTrack = true
        } else {
            self.isSkipTrack = false
        }
        
        self.isTrackPlaying = false
        self.hasPlayingTrack = false
        
        if self.isTakeoverPlaying == true {
            self.selectedTrackIndex = 0
            let track = self.dataSource.tracks[self.selectedTrackIndex]
            
            self.trackTitleLabel.text = track.name
            self.trackArtistLabel.text = track.artist
            
            self.isSkipTrack = true
            self.isTakeoverPlaying = false
            
            self.playlistTakeoverImageView.isHidden = true
            
            self.getTrack(trackId: track.trackId)
        } else {
            let track = self.dataSource.tracks[self.selectedTrackIndex]
            
            venue = VenueDataModel.shared.currentVenue
            
            let venueId = venue.venueId!
            let trackId = track.trackId!
            
            self.isRemoveQueue = true
            
            QueueDataModel.shared.removeQueue(venueId: venueId, trackId: trackId) { (error) in
            }
        }
    }
}

extension QueueViewController: AlertViewDelegate {
    func onOkButtonClicked(sender: AlertView) {
        if sender.getTagIndex() == 1000 { // remove track
            venue = VenueDataModel.shared.currentVenue
            
            let venueId = venue.venueId!
            let trackId = self.removeTrack.trackId!
            
            QueueDataModel.shared.removeQueue(venueId: venueId, trackId: trackId) { (error) in
               
            }
        } else if sender.getTagIndex() == 2000 { // override
            let track = self.dataSource.tracks[self.pendingSelectedTrackIndex]
            
            self.trackTitleLabel.text = track.name
            self.trackArtistLabel.text = track.artist
            
            self.getTrack(trackId: track.trackId)
            
            self.selectedTrackIndex = self.pendingSelectedTrackIndex
        } else if sender.getTagIndex() == 3000 { // skip
            self.moveToNextTrack()
        }
    }
    
    func onCancelButtonClicked(sender: AlertView) {
        self.isFirstSongRemoved = false
    }
}


