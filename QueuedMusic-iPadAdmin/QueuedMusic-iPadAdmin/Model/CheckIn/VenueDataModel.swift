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
    var venueId: String!
    var name: String?
    var latitude: Float?
    var longitude: Float?
    var verified: Bool
    let adminId: String?
    var paymentId: String?
    var openSession: Bool
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
    
    init?(adminId: String?, latitude: Float?, longitude: Float?, created: Date?, name: String?) {
        self.venueId = ""
        self.adminId = adminId
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.created = created
        self.openSession = true
        self.verified = false
        self.paymentId = ""
        self.distance = 0
        
        super.init()
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
    
    func addVenue(newVenue: Venue!, completion:@escaping (_ error: Error?, _ key: String?) -> Void) {
        FirebaseManager.shared.observeSingleEvent(with: "venue") { (snapshot) in
            let enumerator = snapshot.children
            var isExist = false
            while let childSnapshot = enumerator.nextObject() as? FIRDataSnapshot {
                let json = JSON(childSnapshot.value ?? "")
                let venue = Venue(key: childSnapshot.key, json: json)
                if venue?.name == newVenue.name {
                    isExist = true
                    break
                }
            }
            
            if isExist == true {
                completion(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"Venue already exists"]), "")
                return
            }
            
            let values: [String : Any] = [Venue.VenueKey.adminIdKey: newVenue.adminId ?? "",
                                          Venue.VenueKey.createdKey: newVenue.created?.string() ?? "",
                                          Venue.VenueKey.latitudeKey: newVenue.latitude ?? 0.0,
                                          Venue.VenueKey.longitudeKey: newVenue.longitude ?? 0.0,
                                          Venue.VenueKey.venueNameKey: newVenue.name ?? "",
                                          Venue.VenueKey.openSessionKey: newVenue.openSession,
                                          Venue.VenueKey.paymentIdKey: newVenue.paymentId ?? "",
                                          Venue.VenueKey.verifiedKey: newVenue.verified]
        
            FirebaseManager.shared.addChildByAutoId(parentRef: "venue", values: values, completion: { (error, key) in
                if let error = error {
                    completion(error, key)
                } else {
                    print("Firebase added a venue successfully")
                    
                    let currentUser = UserDataModel.shared.currentUser()
                    currentUser?.venueID = key
                    
                    UserDataModel.shared.storeCurrentUser(user: currentUser)
                    
                    newVenue.venueId = key
                    VenueDataModel.shared.currentVenue = newVenue
                    
                    UserDataModel.shared.updateVenueID(venueId: key, completion: { (error)  in
                    
                    })
                    
                    completion(error, key)
                }
            })
        }
        
    }
    
    func updateVenue(venueId: String!, paymentID: String!, verified: Bool!, completion:@escaping (_ error: Error?) -> Void) {
        FirebaseManager.shared.updateValues(with: String(format: "venue/%@", venueId), values: [Venue.VenueKey.paymentIdKey : paymentID, Venue.VenueKey.verifiedKey: verified]) { (error) in
            completion(error)
        }
    }
    
    func updateVenue(venueId: String!, openSession: Bool!, completion:@escaping (_ error: Error?) -> Void) {
        FirebaseManager.shared.updateValues(with: String(format: "venue/%@", venueId), values: [Venue.VenueKey.openSessionKey : openSession]) { (error) in
            completion(error)
        }
    }
    
    func updateVenue(venueId: String!, name: String!, latitude: Float?, longitude: Float?, completion:@escaping (_ error: Error?) -> Void) {
        FirebaseManager.shared.updateValues(with: String(format: "venue/%@", venueId), values: [Venue.VenueKey.venueNameKey : name, Venue.VenueKey.latitudeKey: latitude ?? 0.0, Venue.VenueKey.longitudeKey: longitude ?? 0.0]) { (error) in
            completion(error)
        }
    }
    
    func removeVenue(venueId: String!, completion: @escaping (_ error: Error?) -> Void) {
        guard let venueId = venueId else { return }
        
        FirebaseManager.shared.removeVenue(venueRef: "venue/\(venueId)", completion: { (error) in
            if error != nil {
                completion(error)
            } else {
                completion(nil)
            }
        })
    }
}
