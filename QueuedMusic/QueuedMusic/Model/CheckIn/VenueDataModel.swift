//
//  Venue.swift
//  QueuedMusic
//
//  Created by Micky on 1/25/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import Firebase

class Venue: NSObject {
    let venueId: String!
    let name: String?
    let latitude: Float?
    let longitude: Float?
    let verified: Bool
    let adminId: String?
    let paymentId: String?
    let openSession: Bool
    let created: Date?
    var distance: Float // in mile
    
    struct VenueKey {
        static let venueNameKey = "name"
        static let latitudeKey = "latitude"
        static let longitudeKey = "longitude"
        static let verifiedKey = "verified"
        static let adminIdKey = "adminID"
        static let openSessionKey = "openSession"
        static let paymentIdKey = "paymentID"
        static let createdKey = "created"
    }
    
    struct CheckInKey {
        static let createdKey = "in_time"
        static let emailKey = "email"
        static let usernameKey = "username"
        static let activityKey = "activity"
        static let tokenKey = "FCMToken"
    }
    
    
    init?(key: String, json: JSON) {
        venueId = key
        name = json[VenueKey.venueNameKey].stringValue
        latitude = json[VenueKey.latitudeKey].floatValue
        longitude = json[VenueKey.longitudeKey].floatValue
        verified = json[VenueKey.verifiedKey].boolValue
        adminId = json[VenueKey.adminIdKey].stringValue
        paymentId = json[VenueKey.paymentIdKey].stringValue
        openSession = json[VenueKey.openSessionKey].boolValue
        created = Date(dateString: json[VenueKey.createdKey].stringValue)
        self.distance = 0
        
        super.init()
    }
}

class VenueDataModel {
    static let shared: VenueDataModel = VenueDataModel()
    
    var currentVenue: Venue!
    
    func loadVenues(completion: @escaping (_ venues: [Venue]) -> Void) {
        FirebaseManager.shared.observeSingleEvent(with: "venue") { (snapshot) in
            let enumerator = snapshot.children
            var venues: [Venue] = []
            while let childSnapshot = enumerator.nextObject() as? FIRDataSnapshot {
                let json = JSON(childSnapshot.value ?? "")
                let venue = Venue(key: childSnapshot.key, json: json)
                venues.append(venue!)
            }
            completion(venues)
        }
    }
    
    func removeCheckIn(venueId: String!, userId: String!, completion: @escaping (_ error: Error?) -> Void) {
        guard let venueId = venueId, let userId = userId else { return }
        
        FirebaseManager.shared.observeSingleEvent(with: "check_ins") { (snapshot) in
            let enumerator = snapshot.children
            while let childSnapshot = enumerator.nextObject() as? FIRDataSnapshot {
                let vId = childSnapshot.key
                if vId != venueId {
                    FirebaseManager.shared.removeCheckIn(queueRef: "check_ins/\(vId)/\(userId)", completion: { (error) in
                        
                    })
                }
            }
        }
        
        FirebaseManager.shared.removeCheckIn(queueRef: "check_ins/\(venueId)/\(userId)", completion: { (error) in
            if error == nil {
                completion(nil)
            } else {
                completion(error)
            }
        })
        
        
    }
    
    func addCheckIn(venueId: String!, user: User!, completion: @escaping (_ error: Error?) -> Void) {
        guard let venueId = venueId else { return }
        
        let values: [String : Any] = [Venue.CheckInKey.activityKey : 0,
                                      Venue.CheckInKey.createdKey : Date().string(),
                                      Venue.CheckInKey.emailKey: user.email ?? "",
                                      Venue.CheckInKey.usernameKey: user.userName ?? "",
                                      Venue.CheckInKey.tokenKey: user.FCMToken ?? ""]
        
        FirebaseManager.shared.addChild(parentRef: "check_ins/\(venueId)", childKey: user.userId, values: values, completion: { (error) in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        })
    }
}
