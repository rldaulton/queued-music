//
//  Vote+CoreDataClass.swift
//  
//
//  Created by Micky on 2/10/17.
//
//

import Foundation
import CoreData
import CoreStore

public class Vote: NSManagedObject {
    
    static func voteUp(trackName: String!, venueId: String!, completion: @escaping (_ error: Error?) -> Void) {
        if let vote = CoreStore.fetchOne(From<Vote>(), Where("trackName", isEqualTo: trackName) && Where("venueId", isEqualTo: venueId)) {
            if !vote.upVoted {
                CoreStore.beginAsynchronous({ (transaction) in
                    vote.upVoted = true
                    vote.downVoted = false
                    transaction.commit({ (result) in
                        switch result {
                        case .success( _):
                            print("saved vote status in core data successfully")
                            completion(nil)
                            break;
                            
                        case .failure(let error):
                            print(error)
                            completion(error)
                            break;
                        }
                    })
                })
            } else {
                completion(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"You have been already upvoted this song"]))
            }
        } else {
            CoreStore.beginAsynchronous({ (transaction) in
                let vote = transaction.create(Into<Vote>())
                vote.trackName = trackName
                vote.venueId = venueId
                vote.upVoted = true
                vote.downVoted = false
                transaction.commit({ (result) in
                    switch result {
                    case .success( _):
                        print("saved vote status in core data successfully")
                        completion(nil)
                        break;
                        
                    case .failure(let error):
                        print(error)
                        completion(error)
                        break;
                    }
                })
            })
        }
    }
    
    static func voteDown(trackName: String!, venueId: String!, completion: @escaping (_ error: Error?) -> Void) {
        if let vote = CoreStore.fetchOne(From<Vote>(), Where("trackName", isEqualTo: trackName) && Where("venueId", isEqualTo: venueId)) {
            if !vote.downVoted {
                CoreStore.beginAsynchronous({ (transaction) in
                    vote.upVoted = false
                    vote.downVoted = true
                    transaction.commit({ (result) in
                        switch result {
                        case .success( _):
                            print("saved vote status in core data successfully")
                            completion(nil)
                            break;
                            
                        case .failure(let error):
                            print(error)
                            completion(error)
                            break;
                        }
                    })
                })
            } else {
                completion(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"You have been already downvoted this song"]))
            }
        } else {
            CoreStore.beginAsynchronous({ (transaction) in
                let vote = transaction.create(Into<Vote>())
                vote.trackName = trackName
                vote.venueId = venueId
                vote.upVoted = false
                vote.downVoted = true
                transaction.commit({ (result) in
                    switch result {
                    case .success( _):
                        print("saved vote status in core data successfully")
                        completion(nil)
                        break;
                        
                    case .failure(let error):
                        print(error)
                        completion(error)
                        break;
                    }
                })
            })
        }
    }
    
    static func upVoted(trackName: String!, venueId: String!) -> Bool {
        if let vote = CoreStore.fetchOne(From<Vote>(), Where("trackName", isEqualTo: trackName) && Where("venueId", isEqualTo: venueId)) {
            return vote.upVoted
        } else {
            return false
        }
    }
    
    static func downVoted(trackName: String!, venueId: String!) -> Bool {
        if let vote = CoreStore.fetchOne(From<Vote>(), Where("trackName", isEqualTo: trackName) && Where("venueId", isEqualTo: venueId)) {
            return vote.downVoted
        } else {
            return false
        }
    }
    
    static func update(tracks: [Track]!, venueId: String!) {
        var trackIds: [String] = []
        for track in tracks {
            trackIds.append(track.name!)
        }
        CoreStore.beginAsynchronous({ (transaction) in
            let predicate = NSPredicate(format: "NOT (trackName IN %@)", trackIds)
            transaction.deleteAll(From<Vote>(), Where(predicate))
            transaction.commit()
        })
    }
}
