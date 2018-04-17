//
//  SearchModel.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 30.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Spotify

protocol SearchViewModelDelegate {
    func searchModel(model:SearchModel,didFoundArtists artists:[SPTPartialArtist])
    func searchModel(model:SearchModel,didFoundTracks tracks:[SPTPartialTrack])
    func searchDidFail(error:NSError)
}

final class SearchModel: NSObject {
    
    private var delegate:SearchViewModelDelegate?
    
    init(delegate:SearchViewModelDelegate?){
        self.delegate = delegate
    }
    
    func filterData(_ searchTerm: String) {
        search(forArtists: searchTerm)
        search(forTracks: searchTerm)
    }
    
    func search(forArtists keyword:String) {
        
        guard let auth = SPTAuth.defaultInstance() else { return }
        guard let session = auth.session else { return }
        let accessToken = session.accessToken
        
        SPTSearch.perform(withQuery: keyword,
                          queryType: .queryTypeArtist,
                          accessToken: accessToken) { (error, result) in
            if let error = error {
                print("error while search artist:\(error.localizedDescription)")
            } else {
                if let page = result as? SPTListPage,
                    let items = page.items as? [SPTPartialArtist] {
                    self.delegate?.searchModel(model: self, didFoundArtists: items)
                } else {
                    self.delegate?.searchModel(model: self, didFoundArtists: [])
                }
            }
        }
        
    }
    
    func search(forTracks keyword:String) {
        
        guard let auth = SPTAuth.defaultInstance() else { return }
        guard let session = auth.session else { return }
        let accessToken = session.accessToken
        
        SPTSearch.perform(withQuery: keyword,
                          queryType: .queryTypeTrack,
                          accessToken: accessToken) { (error, result) in
            if let error = error {
                print("error while search tracks:\(error.localizedDescription)")
            } else {
                if let page = result as? SPTListPage,
                    let items = page.items as? [SPTPartialTrack] {
                    self.delegate?.searchModel(model: self, didFoundTracks: items)
                } else {
                    self.delegate?.searchModel(model: self, didFoundTracks: [])
                }
            }
        }
    }
    
    func selected(track model:SPTPartialTrack){
        
        guard let auth = SPTAuth.defaultInstance() else { return }
        guard let session = auth.session else { return }
        let accessToken = session.accessToken
        let market = Locale.current.regionCode
        
        SPTTrack.track(withURI: model.uri,
                       accessToken: accessToken,
                       market: market) { (error, object) in
            if let error = error {
                print("error:\(error.localizedDescription) while retrieving full artist object: \(model.identifier) name:\(model.name)")
            } else if let track = object as? SPTTrack {
                self.printTrackInfo(track)
            }
        }
    }
    
    func selected(artist model:SPTPartialArtist, completion:@escaping (_ tracks: [SPTTrack]?) -> Void) {
        
        guard let auth = SPTAuth.defaultInstance() else { return }
        guard let session = auth.session else { return }
        let accessToken = session.accessToken
        
        SPTArtist.artist(withURI: model.uri,
                         accessToken:accessToken) { (artistError, artistResponseObject) in
            if let error = artistError {
                print("error:\(error.localizedDescription) while retrieving full artist object: \(model.identifier) name:\(model.name)")
            } else if let artist = artistResponseObject as? SPTArtist {
                let territory = Locale.current.regionCode
                artist.requestTopTracks(forTerritory: territory,
                                        withAccessToken: accessToken,
                                        callback: { (topTracksError, topTracksResponseObject) in
                    if topTracksError != nil {
                        print("error while retrieving top tracks")
                        completion(nil)
                    } else if let tracks = topTracksResponseObject as? [SPTTrack] {
                        var topTracks = [SPTTrack]()
                        if tracks.count >= 10 {
                            topTracks = Array(tracks[0..<10])
                        } else {
                            topTracks = tracks
                        }
//                        print("==========")
//                        print("Artist:\(artist.name!)")
//                        topTracks.forEach{
//                            self.printTrackInfo($0)
//                            print("---------")
//                        }
                        completion(topTracks)
                    } else {
                        completion(nil)
                    }
                })
            }
        }
    }
    
    func printTrackInfo(_ track:SPTTrack) {
        print("Track: \(track.name!)")
        print("uri:\(track.uri.absoluteString)")
        print("playableUri:\(track.playableUri.absoluteString)")
        print("sharingURL:\(track.sharingURL.absoluteString)")
    }
    
}
