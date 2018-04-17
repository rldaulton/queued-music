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

class CheckIn: NSObject {
    let activity: Int?
    let created: Date?
    let email: String?
    let username: String?
    let checkInId: String!
    
    struct CheckInKey {
        static let activitiyKey = "activity"
        static let usernameKey = "username"
        static let emailKey = "email"
        static let createdKey = "in_time"
    }
    
    
    init?(key: String, json: JSON) {
        checkInId = key
        email = json[CheckInKey.emailKey].stringValue
        username = json[CheckInKey.usernameKey].stringValue
        activity = json[CheckInKey.activitiyKey].intValue
        created = Date(dateString: json[CheckInKey.createdKey].stringValue)
        
        super.init()
    }
}

class CheckInDataModel {
    static let shared: CheckInDataModel = CheckInDataModel()
    
    var currentCheckIn: CheckIn!
    
    func loadCheckIns(venueId: String!, completion: @escaping (_ checks: [CheckIn]) -> Void) {
        if let venueId = venueId {
            FirebaseManager.shared.observeValueChanged(with: "check_ins/\(venueId)") { (snapshot) in
                let enumerator = snapshot.children
                var checkIns: [CheckIn] = []
                while let childSnapshot = enumerator.nextObject() as? FIRDataSnapshot {
                    let json = JSON(childSnapshot.value ?? "")
                    let venue = CheckIn(key: childSnapshot.key, json: json)
                    checkIns.append(venue!)
                }
                completion(checkIns)
            }
        }
    }
}
