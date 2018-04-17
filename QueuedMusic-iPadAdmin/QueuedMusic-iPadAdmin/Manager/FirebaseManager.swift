//
//  FirebaseManager.swift
//  QueuedMusic
//
//  Created by Micky on 2/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Foundation
import Firebase
import SwiftyJSON

class FirebaseManager {
    
    static let shared: FirebaseManager = FirebaseManager()

    var dbRef: FIRDatabaseReference!
    
    private init() {
        dbRef = FIRDatabase.database().reference()
    }
    
    func loginAnonymously(completion: @escaping (_ user: FIRUser?, _ error: Error?) -> Void) {
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            if let error = error {
                print("Firebase anonymous sign in error \(error.localizedDescription)")
            } else if let userId = user?.uid {
                print("Firbase anonymous user id \(userId)")
            }
            completion(user, error)
        })
    }
    
    func loginWithCredential(credential: FIRAuthCredential, completion: @escaping (_ user: FIRUser?, _ error: Error?) -> Void) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if let error = error {
                print("Firebase sign in with credential error \(error.localizedDescription)")
            } else {
                print("Firebase sign in with credential successfully")
            }
            completion(user, error)
        })
    }
    
    func observeSingleEvent(with childRef: String!, completion:@escaping (_ snapshot: FIRDataSnapshot) -> Void) {
        let ref = dbRef.child(childRef)
        ref.observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot)
        }
    }
    
    func observeValueChanged(with childRef: String!, completion:@escaping (_ snapshot: FIRDataSnapshot) -> Void) {
        let ref = dbRef.child(childRef)
        ref.observe(.value) { (snapshot) in
            completion(snapshot)
        }
    }
    
    func checkChildExistence(parentRef: String!, childKey: String!, completion:@escaping (_ exist: Bool, _ snapshot: FIRDataSnapshot?) -> Void) {
        let ref = dbRef.child(parentRef)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            completion(snapshot.hasChild(childKey), snapshot.childSnapshot(forPath: childKey))
        })
    }
    
    func addChild(parentRef: String!, childKey: String!, values: [String: Any], completion:@escaping (Error?) -> Void) {
        let ref = dbRef.child(parentRef).child(childKey)
        ref.setValue(values) { (error, ref) in
            completion(error)
        }
    }
    
    func addChildByAutoId(parentRef: String!, values: [String: Any], completion:@escaping (Error?, String?) -> Void) {
        let ref = dbRef.child(parentRef).childByAutoId()
        ref.setValue(values) { (error, ref) in
            completion(error, ref.key)
        }
        
    }
    
    func updateValues(with childRef: String!, values: [String: Any], completion:@escaping (Error?) -> Void) {
        let ref = dbRef.child(childRef)
        ref.updateChildValues(values) { (error, ref) in
            completion(error)
        }
    }
    
    func updateValues(with childRef: FIRDatabaseReference!, values: [String: Any], completion:@escaping (Error?) -> Void) {
        childRef.updateChildValues(values) { (error, ref) in
            completion(error)
        }
    }
    
    func removeQueue(queueRef: String!, completion: @escaping (_ error: Error?) -> Void) {
        let ref = dbRef.child(queueRef)
        ref.removeValue { (error, ref) in
            if error != nil {
                completion(nil)
            } else {
                completion(error)
            }
        }
    }
    
    func removeVenue(venueRef: String!, completion: @escaping (_ error: Error?) -> Void) {
        let ref = dbRef.child(venueRef)
        ref.removeValue { (error, ref) in
            if error != nil {
                completion(nil)
            } else {
                completion(error)
            }
        }
    }
    
    func logout() {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error {
            print("Firebase log out error\(error.localizedDescription)")
        }
    }
}
