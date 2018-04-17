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
    
    func upVote(track: Track, completion: @escaping (_ error: Error?) -> Void) {
        guard let dbRef = track.dbRef else { return }
        let values = [Track.TrackKey.voteCountKey:track.voteCount + 1]
        FirebaseManager.shared.updateValues(with: dbRef, values:values) { (error) in
            if let error = error {
                print("up vote error \(error.localizedDescription)")
                completion(error)
            } else {
                SpotifyManager.shared.trackUserActions(userID: UserDataModel.shared.currentUser()?.userId, venueID: VenueDataModel.shared.currentVenue.venueId, eventCode: "101", eventDesc: "regular upvote", completion: { (error) in
                    
                })
                
                completion(nil)
            }
        }
    }
    
    func downVote(track: Track, completion: @escaping (_ error: Error?) -> Void) {
        guard let dbRef = track.dbRef else { return }
        let values = [Track.TrackKey.voteCountKey:track.voteCount - 1]
        FirebaseManager.shared.updateValues(with: dbRef, values:values) { (error) in
            if let error = error {
                print("down vote error \(error.localizedDescription)")
                completion(error)
            } else {
                SpotifyManager.shared.trackUserActions(userID: UserDataModel.shared.currentUser()?.userId, venueID: VenueDataModel.shared.currentVenue.venueId, eventCode: "100", eventDesc: "regular downvote", completion: { (error) in
                    
                })
                
                completion(nil)
            }
        }
    }
    
    func premiumVote(voteUp: Bool!, track:Track!, completion: @escaping (_ error: Error?) -> Void) {
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        guard let dbRef = track.dbRef else { return }
        let values = [Track.TrackKey.voteCountKey : track.voteCount + (voteUp == true ? 2 : -2)]
        FirebaseManager.shared.updateValues(with: dbRef, values: values) { (error) in
            if let error = error {
                print("premium vote error \(error.localizedDescription)")
                completion(error)
            } else {
                if let premiumVoteBalance = currentUser.premiumVoteBalance, let userId = currentUser.userId {
                    let values = [User.UserKey.premiumVoteBalanceKey : premiumVoteBalance - 1]
                    FirebaseManager.shared.updateValues(with: "user/\(userId)", values: values, completion: { (error) in
                        if let error = error {
                            completion(error)
                        } else {
                            if voteUp == true {
                                SpotifyManager.shared.trackUserActions(userID: UserDataModel.shared.currentUser()?.userId, venueID: VenueDataModel.shared.currentVenue.venueId, eventCode: "201", eventDesc: "premium upvote", completion: { (error) in
                                    
                                })
                            } else {
                                SpotifyManager.shared.trackUserActions(userID: UserDataModel.shared.currentUser()?.userId, venueID: VenueDataModel.shared.currentVenue.venueId, eventCode: "200", eventDesc: "premium downvote", completion: { (error) in
                                    
                                })
                            }
                            currentUser.premiumVoteBalance = premiumVoteBalance - 1
                            UserDataModel.shared.storeCurrentUser(user: currentUser)
                            completion(nil)
                        }
                    })
                }
            }
        }
    }
    
    func addTrackToQueue(queueId: String!, track: SPTPartialTrack!, completion: @escaping (_ error: Error?, _ message: String?) -> Void) {
        guard let queueId = queueId else { return }
        FirebaseManager.shared.checkChildExistence(parentRef: "queue/\(queueId)", childKey: track.uri.absoluteString) { (exist, snapshot) in
            if !exist {
                var artists: [String] = []
                if let artistList = track.artists as? [SPTPartialArtist] {
                    artists = artistList.map{ $0.name! }
                }
                let values: [String : Any] = [Track.TrackKey.playingKey : false,
                                              Track.TrackKey.trackArtistKey : artists.joined(separator: ","),
                                              Track.TrackKey.trackNameKey : track.name,
                                              Track.TrackKey.voteCountKey : 1,
                                              Track.TrackKey.addedKey : Date().string(),
                                              Track.TrackKey.addedByKey : UserDataModel.shared.currentUser()?.userId ?? ""]
                FirebaseManager.shared.addChild(parentRef: "queue/\(queueId)", childKey: track.uri.absoluteString, values: values, completion: { (error) in
                    if let error = error {
                        completion(error, nil)
                    } else {
                        Vote.voteUp(trackName: track.name, venueId: queueId, completion: { (error) in
                            if let error = error {
                                completion(error, nil)
                            } else {
                                SpotifyManager.shared.trackUserActions(userID: UserDataModel.shared.currentUser()?.userId, venueID: VenueDataModel.shared.currentVenue.venueId, eventCode: "400", eventDesc: "song add", completion: { (error) in
                                    
                                })

                                if let trackName = track.name {
                                    completion(error, "\(trackName) has been added to current queue.")
                                } else {
                                    completion(error, "Unknown track has been added to current queue.")
                                }
                            }
                        })
                    }
                })
            } else {
                if !Vote.upVoted(trackName: track.name, venueId: queueId), let snapshot = snapshot {
                    let json = JSON(snapshot.value ?? "")
                    let track = Track(key: snapshot.key, json: json, ref: snapshot.ref)
                    self.upVote(track: track!, completion: { (error) in
                        if let error = error {
                            completion(error, nil)
                        } else {
                            Vote.voteUp(trackName: track?.name, venueId: queueId, completion: { (error) in
                                if let error = error {
                                    completion(error, nil)
                                } else {
                                    SpotifyManager.shared.trackUserActions(userID: UserDataModel.shared.currentUser()?.userId, venueID: VenueDataModel.shared.currentVenue.venueId, eventCode: "400", eventDesc: "song add", completion: { (error) in
                                        
                                    })

                                    if let trackName = track?.name {
                                        completion(error, "\(trackName) has been upvoted successfully.")
                                    } else {
                                        completion(error, "Unknown track has been upvoted successfully.")
                                    }
                                }
                            })
                        }
                        
                    })
                } else {
                    if let trackName = track.name {
                        completion(nil, "\(trackName) has been already upvoted.")
                    } else {
                        completion(nil, "Unknown track has been already upvoted.")
                    }
                }
            }
        }
    }
}
