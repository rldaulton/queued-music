//
//  ArtistTopSongTableViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/14/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify
import Whisper
import PKHUD

class ArtistTopSongTableViewController: UITableViewController {
    
    var artist: SPTPartialArtist!
    var searchModel: SearchModel!
    var tracks: [SPTTrack]? = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = artist.name
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        
        tableView.tableFooterView = UIView()

        searchModel = SearchModel(delegate: nil)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        SpotifyManager.shared.refreshSession {
            self.searchModel.selected(artist: self.artist, completion: { (tracks) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if tracks != nil {
                    self.tracks = tracks
                    self.tableView.reloadData()
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tracks?.count)!
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = SearchSectionHeaderView.loadFromNib()
        headerView.setTitle(title: "Artist Top Tracks")
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTrackTableViewCell", for: indexPath) as! SearchTrackTableViewCell

        if let track = tracks?[indexPath.row] {
            cell.titleLabel.text = track.name
            if let artistList = track.artists as? [SPTPartialArtist] {
                let artists = artistList.map{ $0.name! }
                cell.subtitleLabel.text = artists.joined(separator: ",")
            } else {
                cell.subtitleLabel.text = ""
            }
            cell.delegate = self
        }

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - IBAction
    
    @IBAction func close(sender: UIButton!) {
        dismiss(animated: true, completion: nil)
    }
}

extension ArtistTopSongTableViewController: SearchTrackTableViewCellDelegate {
    func trackCellDidPressAddToQueue(_ cell: SearchTrackTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let track = tracks?[indexPath.row]
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        QueueDataModel.shared.addTrackToQueue(queueId: VenueDataModel.shared.currentVenue.venueId, track: track) { (error, message) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            PKHUD.sharedHUD.hide()
            
            if let error = error {
                let announcement = Announcement(title: "Error", subtitle: error.localizedDescription, image: nil)
                Whisper.show(shout: announcement, to: self)
            } else {
                let announcement = Announcement(title: "Message", subtitle: message, image: nil)
                Whisper.show(shout: announcement, to: self)
                
            }
        }
    }
}
