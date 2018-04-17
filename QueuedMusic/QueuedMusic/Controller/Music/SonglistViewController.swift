//
//  SonglistViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/14/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify
import Whisper
import PKHUD

protocol SonglistDataSourceDelegate: class {
    func dataSourceDidCompleteLoad(_ dataSource: SonglistDataSource)
    func addtoQueue(track: SPTPartialTrack!)
}

protocol SonglistConfigurable {
    func configure(with track: SPTPartialTrack?)
}

protocol SonglistCellConfigurable: SonglistConfigurable {
    var titleLabel: UILabel! { get set }
    var authorLabel: UILabel! { get set }
    var queueButton: UIButton! { get set }
}

extension SonglistCellConfigurable {
    func configure(with track: SPTPartialTrack?) {
        titleLabel.text = track?.name
        authorLabel.text = ""
        if let artistList = track?.artists as? [SPTPartialArtist] {
            let artists = artistList.map{ $0.name! }
            authorLabel.text = artists.joined(separator: ", ")
        }
    }
}

extension SonglistCell: SonglistCellConfigurable { }

class SonglistDataSource: NSObject, UITableViewDataSource {
    weak var delegate: SonglistDataSourceDelegate?
    var tracks: [SPTPartialTrack] = []
    var hasMore: Bool!
    var listPage: SPTListPage?
    var url: URL!
    
    func load(WithUrl url: URL) {
        self.url = url
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        SpotifyManager.shared.loadSonglist(url: url, listPage: nil, completion: { (listPage) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.listPage = listPage
            self.tracks.removeAll()
            if let items = listPage?.items {
                for item in items {
                    if let track = item as? SPTPartialTrack {
                        if track.isPlayable == true {
                            self.tracks.append(track)
                        }
                        
                    }
                }
            }
            self.tracks = self.tracks.filter({ !$0.uri.absoluteString.hasPrefix("spotify:local:") })
            self.delegate?.dataSourceDidCompleteLoad(self)
        })
    }
    
    private func loadMore() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        SpotifyManager.shared.loadSonglist(url: url, listPage: listPage, completion: { (listPage) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.listPage = listPage
            if let items = listPage?.items {
                for item in items {
                    if let track = item as? SPTPartialTrack {
                        self.tracks.append(track)
                    }
                }
            }
            self.delegate?.dataSourceDidCompleteLoad(self)
        })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SonglistCell", for: indexPath) as! SonglistCell
        
        if indexPath.item == tracks.count && listPage?.hasNextPage == true {
            loadMore()
            let cell = UITableViewCell(style: .default, reuseIdentifier: "LoadMoreCell")
            let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            loadingView.startAnimating()
            cell.addSubview(loadingView)
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            loadingView.centerXAnchor.constraint(equalTo: cell.centerXAnchor)
            loadingView.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            
            return cell
        } else {
            let track = tracks[indexPath.item]
            (cell as SonglistConfigurable).configure(with: track)
            cell.queueButton.tag = indexPath.item
            cell.queueButton.addTarget(self, action: #selector(addToQueue(sender:)), for: .touchUpInside)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listPage?.hasNextPage == true ? self.tracks.count + 1 : self.tracks.count
    }
    
    @IBAction func addToQueue(sender: UIButton!) {
        delegate?.addtoQueue(track: tracks[sender.tag])
    }
}

class SonglistViewController: BaseViewController {
    
    @IBOutlet weak var songlistTableView: UITableView!
    
    var refreshControl: UIRefreshControl!
    
    public var playlist: SPTPartialPlaylist!
    
    let dataSource = SonglistDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = playlist.name

        dataSource.delegate = self
        songlistTableView.dataSource = dataSource
        songlistTableView.tableFooterView = UIView()
        
        refreshControl = UIRefreshControl()
        songlistTableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        songlistTableView.setContentOffset(CGPoint(x: 0, y: -refreshControl.frame.size.height), animated: true)
        refreshControl.beginRefreshing()
        dataSource.load(WithUrl: playlist.uri)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func refresh(sender: UIRefreshControl) {
        dataSource.load(WithUrl: playlist.uri)
    }
}

extension SonglistViewController: SonglistDataSourceDelegate {
    func dataSourceDidCompleteLoad(_ dataSource: SonglistDataSource) {
        songlistTableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func addtoQueue(track: SPTPartialTrack!) {
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

extension SonglistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
