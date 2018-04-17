//
//  HomeViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/9/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import CoreStore
import Whisper
import DGElasticPullToRefresh
import AudioIndicatorBars

protocol TrackDataSourceDelegate: class {
    func dataSourceDidCompleteLoad(_ dataSource: TrackDataSource, tracks: [Track]?)
    func didVoteUp(track: Track)
    func didVoteDown(track: Track)
}

protocol TrackConfigurable {
    func configure(with track: Track?)
}

protocol TrackCellConfigurable: TrackConfigurable {
    var trackTitleLabel: UILabel! { get set }
    var trackArtistLabel: UILabel! { get set }
    var voteCountLabel: UILabel! { get set }
    var voteUpButton: UIButton! { get set }
    var voteDownButton: UIButton! { get set }
    var audioIndicatorBar: AudioIndicatorBarsView! { get set }
}

extension TrackCellConfigurable {
    func configure(with track: Track?) {
        trackTitleLabel.text = track?.name
        trackArtistLabel.text = track?.artist
        if let voteCount = track?.voteCount {
            voteCountLabel.text = "\(voteCount)"
        }
        
        if let vote = CoreStore.fetchOne(From<Vote>(), Where("trackName", isEqualTo: track?.name)) {
            voteUpButton.isSelected = vote.upVoted
            voteDownButton.isSelected = vote.downVoted
        } else {
            voteUpButton.isSelected = false
            voteDownButton.isSelected = false
        }
        
        if track?.playing == true {
            voteUpButton.isHidden = true
            voteDownButton.isHidden = true
            voteCountLabel.isHidden = true
            audioIndicatorBar.isHidden = false
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when, execute: {
                self.audioIndicatorBar.start()
            })
        } else {
            voteUpButton.isHidden = false
            voteDownButton.isHidden = false
            voteCountLabel.isHidden = false
            audioIndicatorBar.isHidden = true
            //audioIndicatorBar.stop()
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
        
        cell.voteUpButton.tag = indexPath.item
        cell.voteUpButton.addTarget(self, action: #selector(voteUp(sender:)), for: .touchUpInside)
        
        cell.voteDownButton.tag = indexPath.item
        cell.voteDownButton.addTarget(self, action: #selector(voteDown(sender:)), for: .touchUpInside)
        
        cell.contentView.backgroundColor = indexPath.row == 0 && track.playing! == true ? #colorLiteral(red: 0.1565925479, green: 0.1742246747, blue: 0.2227806747, alpha: 1) : #colorLiteral(red: 0.1614608765, green: 0.1948977113, blue: 0.2560786903, alpha: 1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    
    @IBAction func voteUp(sender: UIButton) {
        delegate?.didVoteUp(track: tracks[sender.tag])
    }
    
    @IBAction func voteDown(sender: UIButton) {
        delegate?.didVoteDown(track: tracks[sender.tag])
    }
}

class HomeViewController: BaseViewController {
    
    @IBOutlet weak var trackTableView: UITableView!
    @IBOutlet weak var emptyQueueImageView: UIImageView!

    var loadingView: DGElasticPullToRefreshLoadingViewCircle!
    var refreshing: Bool!
    
    var venue: Venue!
    let dataSource = TrackDataSource()
    var voting: Bool! = false
    
    var currentPlayingTrack: Track? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        NotificationCenter.default.addObserver(self, selector: #selector(venueCheckedInNotification(_:)), name: .venueCheckedInNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(homeReselectedNotification(_:)), name: .homeReselectedNotification, object: nil)
        
        dataSource.delegate = self
        trackTableView.dataSource = dataSource
        trackTableView.tableFooterView = UIView()
        
        loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = #colorLiteral(red: 0.9999966025, green: 0.9999999404, blue: 0.9999999404, alpha: 1)
        trackTableView.dg_addPullToRefreshWithActionHandler({
            self.refreshing = true
            self.currentPlayingTrack = nil
            self.refresh(sender: nil)
        }, loadingView: loadingView)
        trackTableView.dg_setPullToRefreshFillColor(#colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1))
        trackTableView.dg_setPullToRefreshBackgroundColor(trackTableView.backgroundColor!)
        
        self.currentPlayingTrack = nil
    }
    
    @objc func venueCheckedInNotification(_ notification: NSNotification) {
        venue = notification.userInfo?["venue"] as! Venue
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44))
        
        let titleLabel = UILabel()
        titleLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        titleLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
        titleLabel.text = venue.name
        titleLabel.sizeToFit()
        titleLabel.center = titleView.center
        titleLabel.textAlignment = .center
        
        let titleImageView = UIImageView(image: #imageLiteral(resourceName: "ic_location_pin"))
        let imageAspect = titleImageView.image!.size.width / titleImageView.image!.size.height
        titleImageView.frame = CGRect(x: titleLabel.frame.origin.x - titleLabel.frame.size.height * imageAspect - 8, y: titleLabel.frame.origin.y + 2, width: titleLabel.frame.size.height * imageAspect, height: titleLabel.frame.size.height - 2)
        titleImageView.contentMode = .scaleAspectFit
        
        titleView.addSubview(titleLabel)
        titleView.addSubview(titleImageView)
        navigationItem.titleView = titleView
        
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(checkOutVenue(_:))))

        trackTableView.setContentOffset(CGPoint(x: 0, y: -DGElasticPullToRefreshConstants.MinOffsetToPull), animated: true)
        loadingView.startAnimating()
        self.refreshing = true
        dataSource.tracks.removeAll()
        trackTableView.reloadData()
        dataSource.load(venueId: venue.venueId)
    }
    
    @objc func homeReselectedNotification(_ notification: NSNotification) {
        trackTableView.setContentOffset(.zero, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        trackTableView.dg_removePullToRefresh()
    }
    
    @IBAction func refresh(sender: UIRefreshControl?) {
        if let venueId = venue.venueId {
            emptyQueueImageView.isHidden = true
            dataSource.load(venueId: venueId)
        }
    }
    
    func checkOutVenue(_ sender: UITapGestureRecognizer) {
        let checkInViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CheckInViewController")
        let navigationController = UINavigationController(rootViewController: checkInViewController)
        present(navigationController, animated: true, completion: nil)
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension HomeViewController: TrackDataSourceDelegate {
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
                        self.currentPlayingTrack = track
                        if index > 0 {
                            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                                self.trackTableView.beginUpdates()
                                self.trackTableView.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: 0, section: 0))
                                dataSource.tracks.remove(at: index)
                                dataSource.tracks.insert(track, at: 0)
                                self.trackTableView.endUpdates()
                            }, completion: nil)
                        }
                        break
                    }
                }
            } else {
                for (index, track) in (sortedTracks?.enumerated())! {
                    if track.playing == true {
                        sortedTracks?.remove(at: index)
                        sortedTracks?.insert(track, at: 0)
                        self.currentPlayingTrack = track
                        break
                    }
                }
                
                dataSource.tracks = sortedTracks!
                trackTableView.reloadData()
            }
            DispatchQueue.main.async {
                self.trackTableView.dg_stopLoading()
            }
            // to fix the elastic pull-to-refresh bug that doesn't disappear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.trackTableView.setContentOffset(.zero, animated: true)
            })
            self.refreshing = false
        } else {
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
            
            var isPlayingTrackChanged = false
            var hasPlayingTrack = false
            
            for (index, track) in (dataSource.tracks.enumerated()) {
                if track.playing == true {
                    if self.currentPlayingTrack == nil {
                        isPlayingTrackChanged = true
                    } else {
                        if self.currentPlayingTrack?.trackId != track.trackId {
                            isPlayingTrackChanged = true
                        }
                    }
                    dataSource.tracks.remove(at: index)
                    dataSource.tracks.insert(track, at: 0)
                    self.currentPlayingTrack = track
                    hasPlayingTrack = true
                    break
                }
            }
            
            if hasPlayingTrack == false {
                self.currentPlayingTrack = nil
            }
            
            if isPlayingTrackChanged == true {
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
                
                dataSource.tracks = sortedTracks!
            }
            
            trackTableView.reloadData()
            
            Vote.update(tracks: dataSource.tracks, venueId: venue.venueId)
        }
        
        emptyQueueImageView.isHidden = (tracks?.count)! > 0
        if let first = dataSource.tracks.first {
            trackTableView.dg_setPullToRefreshBackgroundColor(first.playing! ? #colorLiteral(red: 0.1565925479, green: 0.1742246747, blue: 0.2227806747, alpha: 1) : #colorLiteral(red: 0.1614608765, green: 0.1948977113, blue: 0.2560786903, alpha: 1))
        }
    }
    
    func didVoteUp(track: Track) {
        if UserDataModel.shared.getFirstVoteDone() == false {
            let dialog = PremiumFirstDialog()
            dialog.voteUp = true
            dialog.track = track
            dialog.delegate = self
            present(customModalViewController: dialog, centerYOffset: 0)
            
            return
        }
        
        if Vote.upVoted(trackName: track.name, venueId: venue.venueId) {
            if UserDataModel.shared.currentUser() != nil && UserDataModel.shared.currentUser()?.loginType == .guest {
                let alertView = AlertView(title: "Warning", message: "You must be a member to do premium vote.", okButtonTitle: "Sign up", cancelButtonTitle: "Cancel")
                alertView.delegate = self
                alertView.tag = 1000
                present(customModalViewController: alertView, centerYOffset: 0)
                
                return
            }
            
            let dialog = PremiumDialog()
            dialog.voteUp = true
            dialog.track = track
            dialog.delegate = self
            present(customModalViewController: dialog, centerYOffset: 0)
        } else {
            voteUp(track: track)
        }
    }
    
    func didVoteDown(track: Track) {
        if UserDataModel.shared.getFirstVoteDone() == false {
            let dialog = PremiumFirstDialog()
            dialog.voteUp = false
            dialog.track = track
            dialog.delegate = self
            present(customModalViewController: dialog, centerYOffset: 0)
            
            return
        }
        
        if Vote.downVoted(trackName: track.name, venueId: venue.venueId) {
            if UserDataModel.shared.currentUser() != nil && UserDataModel.shared.currentUser()?.loginType == .guest {
                let alertView = AlertView(title: "Warning", message: "You must be a member to do premium vote.", okButtonTitle: "Sign up", cancelButtonTitle: "Cancel")
                alertView.delegate = self
                alertView.tag = 1000
                present(customModalViewController: alertView, centerYOffset: 0)
                
                return
            }
            
            let dialog = PremiumDialog()
            dialog.voteUp = false
            dialog.track = track
            dialog.delegate = self
            present(customModalViewController: dialog, centerYOffset: 0)
        } else {
            voteDown(track: track)
        }
    }
    
    func voteUp(track: Track) {
        if voting == true { return }
        if !Vote.upVoted(trackName: track.name, venueId: venue.venueId) {
            voting = true
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            QueueDataModel.shared.upVote(track: track, completion: { (error) in
                if let error = error {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.voting = false
                    
                    let announcement = Announcement(title: "Error", subtitle: error.localizedDescription, image: nil)
                    Whisper.show(shout: announcement, to: self)
                } else {
                    Vote.voteUp(trackName: track.name, venueId: self.venue.venueId, completion: { (error) in
                        if let error = error {
                            let announcement = Announcement(title: "Error", subtitle: error.localizedDescription, image: nil)
                            Whisper.show(shout: announcement, to: self)
                        } else {
                            self.trackTableView.reloadData()
                        }
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.voting = false
                    })
                    
                }
            })
        }
    }
    
    func voteDown(track: Track) {
        if voting == true { return }
        if !Vote.downVoted(trackName: track.name, venueId: venue.venueId) {
            voting = true
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            QueueDataModel.shared.downVote(track: track, completion: { (error) in
                if let error = error {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.voting = false
                    
                    let announcement = Announcement(title: "Error", subtitle: error.localizedDescription, image: nil)
                    Whisper.show(shout: announcement, to: self)
                } else {
                    Vote.voteDown(trackName: track.name, venueId: self.venue.venueId, completion: { (error) in
                        if let error = error {
                            let announcement = Announcement(title: "Error", subtitle: error.localizedDescription, image: nil)
                            Whisper.show(shout: announcement, to: self)
                        } else {
                            self.trackTableView.reloadData()
                        }
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.voting = false
                    })
                }
            })
        }
    }
}

extension HomeViewController: PremiumDialogDelegate {
    
    func premiumVote(voteUp: Bool, track: Track) {
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        if currentUser.premiumVoteBalance >= 1 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            voting = true
            QueueDataModel.shared.premiumVote(voteUp: voteUp, track: track, completion: { (error) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.voting = false
                if let error = error {
                    let announcement = Announcement(title: "Error", subtitle: error.localizedDescription, image: nil)
                    Whisper.show(shout: announcement, to: self)
                }
            })
        } else {
            performSegue(withIdentifier: "homeToPurchasePremiumSegue", sender: self)
        }
    }
}

extension HomeViewController: PremiumFirstDialogDelegate {
    
    func premiumFirstVote(voteUp: Bool, track: Track) {
        UserDataModel.shared.storeFirstVoteDone(value: true)
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        if currentUser.premiumVoteBalance >= 1 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            voting = true
            QueueDataModel.shared.premiumVote(voteUp: voteUp, track: track, completion: { (error) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.voting = false
                if let error = error {
                    let announcement = Announcement(title: "Error", subtitle: error.localizedDescription, image: nil)
                    Whisper.show(shout: announcement, to: self)
                }
            })
        } else {
            performSegue(withIdentifier: "homeToPurchasePremiumSegue", sender: self)
        }
    }
    
    func regularVote(voteUp: Bool, track: Track) {
        UserDataModel.shared.storeFirstVoteDone(value: true)
        if voteUp == true {
            if Vote.upVoted(trackName: track.name, venueId: venue.venueId) == false {
                self.voteUp(track: track)
            }
        } else {
            if Vote.downVoted(trackName: track.name, venueId: venue.venueId) == false {
                self.voteDown(track: track)
            }
        }
    }
}

extension HomeViewController: AlertViewDelegate {
    func onPerformActionClicked(action: Int) {
        if action == 1000 {
            guard let currentUser = UserDataModel.shared.currentUser() else { return }
            guard let currentVenue = VenueDataModel.shared.currentVenue else { return }
            
            VenueDataModel.shared.removeCheckIn(venueId: currentVenue.venueId, userId: currentUser.userId) { (error) in
                if error == nil {
                    
                }
            }
            
            UserDataModel.shared.removeUser(userId: currentUser.userId, completion: { (error) in
                
            })
            
            UserDataModel.shared.logout()
            _ = self.parent?.navigationController?.popToRootViewController(animated: true)
        }
    }
        
}
