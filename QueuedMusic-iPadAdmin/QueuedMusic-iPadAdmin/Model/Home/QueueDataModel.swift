//
//  QueueDataModel.swift
//  QueuedMusic
//
//  Created by Micky on 2/9/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import Firebase
import Spotify
import CoreStore

class Track: NSObject {
    let trackId: String!
    let name: String?
    let artist: String?
    var voteCount: Int!
    var playing: Bool?
    let added: Date?
    var addedBy: String?
    let dbRef: FIRDatabaseReference!
    
    struct TrackKey {
        static let trackNameKey = "trackName"
        static let trackArtistKey = "trackArtist"
        static let voteCountKey = "voteCount"
        static let playingKey = "playing"
        static let addedKey = "added"
        static let addedByKey = "addedBy"
    }
    
    init?(key:String, json: JSON, ref: FIRDatabaseReference!) {
        trackId = key
        name = json[TrackKey.trackNameKey].stringValue
        artist = json[TrackKey.trackArtistKey].stringValue
        voteCount = json[TrackKey.voteCountKey].intValue
        playing = json[TrackKey.playingKey].boolValue
        added = Date(dateString: json[TrackKey.addedKey].stringValue)
        addedBy = json[TrackKey.addedByKey].stringValue
        dbRef = ref
        
        super.init()
    }
}

class QueueDataModel {
    static let shared: QueueDataModel = QueueDataModel()
    
    func loadQueue(venueId: String!, completion: @escaping (_ tracks: [Track]) -> Void) {
        if let venueId = venueId {
            FirebaseManager.shared.observeValueChanged(with: "queue/\(venueId)") { (snapshot) in
                let enumerator = snapshot.children
                var tracks: [Track] = []
                while let childSnapshot = enumerator.nextObject() as? FIRDataSnapshot {
                    let json = JSON(childSnapshot.value ?? "")
                    let track = Track(key: childSnapshot.key, json: json, ref: childSnapshot.ref)
                    tracks.append(track!)
                }
                completion(tracks)
            }
        }
    }
    
    func updatePlayingStatus(venueId: String!, trackId: String!, status: Bool!, completion: @escaping (_ error: Error?) -> Void) {
        guard let venueId = venueId, let trackId = trackId, let status = status else { return }
        
        let values = [Track.TrackKey.playingKey:status]
        
        FirebaseManager.shared.updateValues(with: "queue/\(venueId)/\(trackId)", values: values, completion: { (error) in
            if error != nil {
                completion(error)
            } else {
                completion(nil)
            }
        })
    }
    
    func removeQueue(venueId: String!, trackId: String!, completion: @escaping (_ error: Error?) -> Void) {
        guard let venueId = venueId, let trackId = trackId else { return }
        
        FirebaseManager.shared.removeQueue(queueRef: "queue/\(venueId)/\(trackId)", completion: { (error) in
            if error != nil {
                completion(error)
            } else {
                completion(nil)
            }
        })
    }
}
