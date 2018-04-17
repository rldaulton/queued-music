//
//  SearchResultsTableViewController.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 30.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify
import Whisper
import PKHUD

final class SearchResultsTableViewController: UITableViewController {
    
    var searchModel:SearchModel!
    lazy var dataSource = SearchResultsDataSource()
    fileprivate var topResultSection = SearchTableViewSection(sortOrder: 0, items: [], headerTitle:"Top Result:", footerTitle: nil)
    fileprivate var tracksSection = SearchTableViewSection(sortOrder: 1, items: [], headerTitle: "Songs:", footerTitle: nil)
    var mainViewController: SearchMainViewController?
    var loadingView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchModel = SearchModel(delegate: self)
        dataSource.delegate = self
        tableView.dataSource = dataSource
    }
    
    func reloadView() {
        dataSource.sections = [tracksSection]
        if topResultSection.items.count > 0 {
            dataSource.sections.insert(topResultSection, at: 0)
        }
        
        let count = dataSource.sections.reduce(0, { $0 + $1.items.count })
        mainViewController?.handleEmptyResults(count)
        tableView.isHidden = count == 0
        DispatchQueue.main.async {
            UIView.transition(with: self.tableView,
                              duration: 0.35,
                              options: .transitionCrossDissolve,
                              animations:
                { () -> Void in
                    self.tableView.reloadData()
            },
                              completion: nil);
        }
    }
    
    func clear() {
        tracksSection.items = []
        tracksSection.headerTitle = nil
        topResultSection.items = []
        topResultSection.headerTitle = nil
        tableView.reloadData()
        
        if loadingView == nil {
            loadingView = UIView(frame: CGRect(x: 0, y: 0, width: (mainViewController?.view.bounds.size.width)!, height: 50))
            loadingView.backgroundColor = .clear
            let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            aiv.frame = CGRect(x: loadingView.bounds.size.width / 2 - 20, y: 10, width: 40, height: 40)
            aiv.startAnimating()
            loadingView.addSubview(aiv)
        }
        self.tableView.addSubview(loadingView)
    }
    
    func cancelSearh(){
        topResultSection.items = []
        tracksSection.items = []
        reloadView()
    }
}

extension SearchResultsTableViewController {
    
    func filterData(_ searchTerm: String) {
        SpotifyManager.shared.refreshSession {
            self.searchModel.filterData(searchTerm)
        }
    }
}

extension SearchResultsTableViewController: SearchViewModelDelegate {
    
    func searchModel(model: SearchModel, didFoundTracks tracks: [SPTPartialTrack]) {
        if tracks.count >= 3 {
            tracksSection.items = Array(tracks[0...2])
        } else {
            tracksSection.items = tracks
        }
        topResultSection.headerTitle = "Top Result:"
        tracksSection.headerTitle = "Songs:"
        reloadView()
        loadingView.removeFromSuperview()
    }
    
    func searchModel(model: SearchModel, didFoundArtists artists: [SPTPartialArtist]) {
        if let artist = artists.first {
            topResultSection.items = [artist]
        } else {
            topResultSection.items = []
        }
        topResultSection.headerTitle = "Top Result:"
        tracksSection.headerTitle = "Songs:"
        reloadView()
        loadingView.removeFromSuperview()
    }
    
    func searchDidFail(error: NSError) {
        tracksSection.items = []
        topResultSection.items = []
        reloadView()
        loadingView.removeFromSuperview()
    }
}

extension SearchResultsTableViewController: SearchTrackTableViewCellDelegate {
    
    func trackCellDidPressAddToQueue(_ cell: SearchTrackTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let model = tracksSection.items[indexPath.row] as? SPTPartialTrack else { return }
        SpotifyManager.shared.refreshSession { 
            self.searchModel.selected(track: model)
        }
        
        // add into queue
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        QueueDataModel.shared.addTrackToQueue(queueId: VenueDataModel.shared.currentVenue.venueId, track: model) { (error, message) in
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

// MARK: - UITableViewDelegate
extension SearchResultsTableViewController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard dataSource.sections[section] != nil else { return nil }
        let headerView = SearchSectionHeaderView.loadFromNib()
        headerView.setTitle(title: dataSource.sections[section].headerTitle)
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = dataSource.sections[indexPath.section].items[indexPath.row]
        //default tableviewcell height 80 and 65
        // 3px is separator height
        if model is SPTPartialArtist {
            return 86
        } else {
            return 90
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath) is SearchArtistTableViewCell {
            guard let model = topResultSection.items[indexPath.row] as? SPTPartialArtist else { return }
            let artistTopSongTableViewController = storyboard?.instantiateViewController(withIdentifier: "ArtistTopSongTableViewController") as! ArtistTopSongTableViewController
            artistTopSongTableViewController.artist = model
            let navController = UINavigationController(rootViewController: artistTopSongTableViewController)
            present(navController, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
