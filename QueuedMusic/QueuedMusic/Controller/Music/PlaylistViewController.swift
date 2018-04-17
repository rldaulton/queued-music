//
//  PlaylistViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/13/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify
import AlamofireImage

protocol PlaylistDataSourceDelegate: class {
    func dataSourceDidCompleteLoad(_ dataSource: PlaylistDataSource)
}

protocol PlaylistConfigurable {
    func configure(with playlist: SPTPartialPlaylist?)
}

protocol PlaylistCellConfigurable: PlaylistConfigurable {
    var artworkImageView: UIImageView! { get set }
    var titleLabel: UILabel! { get set }
}

extension PlaylistCellConfigurable {
    func configure(with playlist: SPTPartialPlaylist?) {
        let filter = ScaledToSizeWithRoundedCornersFilter(size:artworkImageView.bounds.size, radius: 0)
        artworkImageView.af_setImage(withURL: (playlist?.largestImage.imageURL)!, filter: filter)
        titleLabel.text = playlist?.name
    }
}

extension PlaylistCell: PlaylistCellConfigurable { }

class PlaylistDataSource: NSObject, UITableViewDataSource {
    weak var delegate: PlaylistDataSourceDelegate?
    var playlists: [SPTPartialPlaylist] = []
    var hasMore: Bool!
    var listPage: SPTListPage?
    
    func load() {
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        switch currentUser.loginType! {
        case .spotify:
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            SpotifyManager.shared.loadPlaylists(listPage: nil) { (listPage) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.listPage = listPage
                self.playlists.removeAll()
                if let items = listPage?.items {
                    for item in items {
                        if let playlist = item as? SPTPartialPlaylist {
                            self.playlists.append(playlist)
                        }
                    }
                }
                self.delegate?.dataSourceDidCompleteLoad(self)
            }
            break;
            
        case .google:
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            SpotifyManager.shared.loadFeaturedPlaylists(listPage: nil) { (listPage) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.listPage = listPage
                self.playlists.removeAll()
                if let items = listPage?.items {
                    for item in items {
                        if let playlist = item as? SPTPartialPlaylist {
                            self.playlists.append(playlist)
                        }
                    }
                }
                self.delegate?.dataSourceDidCompleteLoad(self)
            }
            break;
        case .guest:
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            SpotifyManager.shared.loadFeaturedPlaylists(listPage: nil) { (listPage) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.listPage = listPage
                self.playlists.removeAll()
                if let items = listPage?.items {
                    for item in items {
                        if let playlist = item as? SPTPartialPlaylist {
                            self.playlists.append(playlist)
                        }
                    }
                }
                self.delegate?.dataSourceDidCompleteLoad(self)
            }
            break;
        default:
            break;
        }
    }
    
    private func loadMore() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        SpotifyManager.shared.loadPlaylists(listPage: self.listPage) { (listPage) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.listPage = listPage
            if let items = listPage?.items {
                for item in items {
                    if let playlist = item as? SPTPartialPlaylist {
                        self.playlists.append(playlist)
                    }
                }
            }
            self.delegate?.dataSourceDidCompleteLoad(self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as! PlaylistCell
        
        if indexPath.item == playlists.count && listPage?.hasNextPage == true {
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
            let playlist = playlists[indexPath.item]
            (cell as PlaylistConfigurable).configure(with: playlist)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listPage?.hasNextPage == true ? self.playlists.count + 1 : self.playlists.count
    }
}


class PlaylistViewController: BaseViewController {
    
    @IBOutlet weak var playlistTableView: UITableView!
    
    var refreshControl: UIRefreshControl!
    
    let dataSource = PlaylistDataSource()
    var selectedPlaylist: SPTPartialPlaylist!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = UserDataModel.shared.currentUser()?.loginType == .spotify ? "My Music" : "Featured"

        dataSource.delegate = self
        playlistTableView.dataSource = dataSource
        playlistTableView.tableFooterView = UIView()
        
        refreshControl = UIRefreshControl()
        playlistTableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        playlistTableView.setContentOffset(CGPoint(x: 0, y: -refreshControl.frame.size.height), animated: true)
        refreshControl.beginRefreshing()
        dataSource.load()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playlistToSonglist" {
            let destination = segue.destination as! SonglistViewController
            destination.playlist = selectedPlaylist
        }
    }
    
    @IBAction func refresh(sender: UIRefreshControl) {
        dataSource.load()
    }
}

extension PlaylistViewController: PlaylistDataSourceDelegate {
    func dataSourceDidCompleteLoad(_ dataSource: PlaylistDataSource) {
        playlistTableView.reloadData()
        refreshControl.endRefreshing()
    }
}

extension PlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedPlaylist = dataSource.playlists[indexPath.item]
        performSegue(withIdentifier: "playlistToSonglist", sender: self)
    }
}


