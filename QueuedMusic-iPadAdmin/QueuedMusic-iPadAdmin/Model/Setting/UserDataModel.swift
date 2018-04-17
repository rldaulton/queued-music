//
//  UserDataModel.swift
//  QueuedMusic
//
//  Created by Micky on 2/21/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import Firebase
import GoogleSignIn
import AlamofireImage

enum LoginType: String {
    case spotify = "spotify"
    case google = "google"
    case email = "email"
}

class User: NSObject, NSCoding {
    let userId: String!
    let userName: String?
    var venueID: String?
    let email: String?
    var loginType: LoginType!
    var googleAuth: GIDAuthentication?
    let joined: Date?
    let photoUrl: String?
    var takeoverID: String?
    var allowPlayback: String?
    
    struct UserKey {
        static let userIdKey = "userId"
        static let userNameKey = "userName"
        static let emailKey = "email"
        static let venueIdKey = "venueID"
        static let loginTypeKey = "userType"
        static let googleAuthKey = "googleAuth"
        static let joinedKey = "joined"
        static let photoUrlKey = "photoUrl"
        static let takeoverIDKey = "takeoverID"
        static let allowPlaybackKey = "allowPlayback"
    }
    
    init(userId: String!, userName: String?, email: String?, venueID: String?, loginType: LoginType!, joined: Date?, photoUrl: String?) {
        self.userId = userId
        self.userName = userName
        self.email = email
        self.venueID = venueID
        self.loginType = loginType
        self.joined = joined
        self.photoUrl = photoUrl
        self.takeoverID = ""
        self.allowPlayback = "true"
        
        super.init()
    }
    
    init?(key:String, json: JSON) {
        userId = key
        userName = json[UserKey.userNameKey].stringValue
        email = json[UserKey.emailKey].stringValue
        venueID = json[UserKey.venueIdKey].stringValue
        joined = Date(dateString: json[UserKey.joinedKey].stringValue)
        photoUrl = json[UserKey.photoUrlKey].stringValue
        takeoverID = json[UserKey.takeoverIDKey].stringValue
        allowPlayback = json[UserKey.allowPlaybackKey].stringValue
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        userId = aDecoder.decodeObject(forKey: UserKey.userIdKey) as! String!
        userName = aDecoder.decodeObject(forKey: UserKey.userNameKey) as! String?
        email = aDecoder.decodeObject(forKey: UserKey.emailKey) as! String?
        venueID = aDecoder.decodeObject(forKey: UserKey.venueIdKey) as! String?
        loginType = LoginType(rawValue: aDecoder.decodeObject(forKey: UserKey.loginTypeKey) as! String!)
        googleAuth = aDecoder.decodeObject(forKey: UserKey.googleAuthKey) as! GIDAuthentication?
        joined = aDecoder.decodeObject(forKey: UserKey.joinedKey) as! Date?
        photoUrl = aDecoder.decodeObject(forKey: UserKey.photoUrlKey) as! String?
        takeoverID = aDecoder.decodeObject(forKey: UserKey.takeoverIDKey) as! String?
        allowPlayback = aDecoder.decodeObject(forKey: UserKey.allowPlaybackKey) as! String?
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(userId, forKey: UserKey.userIdKey)
        aCoder.encode(userName, forKey: UserKey.userNameKey)
        aCoder.encode(email, forKey: UserKey.emailKey)
        aCoder.encode(venueID, forKey: UserKey.venueIdKey)
        aCoder.encode(loginType.rawValue, forKey: UserKey.loginTypeKey)
        aCoder.encode(googleAuth, forKey: UserKey.googleAuthKey)
        aCoder.encode(joined, forKey: UserKey.joinedKey)
        aCoder.encode(photoUrl, forKey: UserKey.photoUrlKey)
        aCoder.encode(takeoverID, forKey: UserKey.takeoverIDKey)
        aCoder.encode(allowPlayback, forKey: UserKey.allowPlaybackKey)
    }
}

class UserDataModel {
    static let shared: UserDataModel = UserDataModel()
    
    private let currentUserKey = "current_user_key"
    private let escrowSetupKey = "escrow_setup"
    
    func login(userId: String!, loginType: LoginType!, googleAuth: GIDAuthentication?, completion:@escaping (_ error: Error?, _ user: User?) -> Void) {
        switch loginType! {
        case .spotify:
            FirebaseManager.shared.loginAnonymously(completion: { (firebaseUser, error) in
                if error == nil, let userId = userId {
                    FirebaseManager.shared.observeSingleEvent(with: "admin_user/\(userId)", completion: { (snapshot) in
                        let json = JSON(snapshot.value ?? "")
                        if json == nil {
                            completion(nil, nil)
                        } else {
                            let user = User(key: userId, json: json)
                            completion(nil, user)
                            self.downloadProfilePicture(url: user?.photoUrl)
                        }
                    })
                } else {
                    completion(error, nil)
                }
            })
            break;
            
        case .google:
            guard let authentication = googleAuth else { return }
            let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                              accessToken: authentication.accessToken)
            FirebaseManager.shared.loginWithCredential(credential: credential, completion: { (firebaseUser, error) in
                if error == nil, let userId = userId {
                    FirebaseManager.shared.observeSingleEvent(with: "admin_user/\(userId)", completion: { (snapshot) in
                        let json = JSON(snapshot.value ?? "")
                        let user = User(key: userId, json: json)
                        self.downloadProfilePicture(url: user?.photoUrl)
                        SpotifyManager.shared.requestToken(username: userId, completion: { (error, session) in
                            if error == nil {
                                SpotifyManager.shared.storeSession(session)
                            }
                            
                            completion(nil, user)
                        })
                    })
                } else {
                    completion(error, nil)
                }
            })
            break;
            
        default:
            break;
        }
    }
    
    func register(user: User!, completion:@escaping (_ error: Error?) -> Void) {
        FirebaseManager.shared.loginAnonymously { (firebaseUser, error) in
            if let error = error {
                completion(error)
            } else {
                FirebaseManager.shared.checkChildExistence(parentRef: "admin_user", childKey: user.userId, completion: { (exist, snapshot) in
                    if !exist {
                        let values: [String : Any] = [User.UserKey.userNameKey:user.userName ?? "",
                                                      User.UserKey.emailKey:user.email ?? "",
                                                      User.UserKey.joinedKey:user.joined?.string() ?? "",
                                                      User.UserKey.photoUrlKey:user.photoUrl ?? "",
                                                      User.UserKey.venueIdKey: "",
                                                      User.UserKey.takeoverIDKey: "",
                                                      User.UserKey.allowPlaybackKey: true]
                        self.downloadProfilePicture(url: user?.photoUrl)
                        FirebaseManager.shared.addChild(parentRef: "admin_user", childKey: user.userId, values: values, completion: { (error) in
                            if let error = error {
                                completion(error)
                            } else {
                                print("Firebase added a user successfully")
                                switch user.loginType! {
                                case .spotify:
                                    completion(error)
                                    break;
                                    
                                case .google:
                                    guard let authentication = user.googleAuth else { return }
                                    let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                                                      accessToken: authentication.accessToken)
                                    FirebaseManager.shared.loginWithCredential(credential: credential, completion: { (firebaseUser, error) in
                                        SpotifyManager.shared.requestToken(username: user.userId, completion: { (error, session) in
                                            if error == nil {
                                                SpotifyManager.shared.storeSession(session)
                                            }
                                            
                                            completion(nil)
                                        })
                                    })
                                    break;
                                    
                                default:
                                    completion(nil)
                                    break;
                                }
                            }
                        })
                    } else {
                        completion(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"User already exists"]))
                    }
                })
            }
        }
    }
    
    func updateFCMToken(token: String!, completion:@escaping (_ error: Error?) -> Void) {
        guard let userId = currentUser()?.userId else { return }
        FirebaseManager.shared.updateValues(with: "admin_user/\(userId)", values: ["FCMToken" : token]) { (error) in
            completion(error)
        }
    }
    
    func updateVenueID(venueId: String!, completion:@escaping (_ error: Error?) -> Void) {
        guard let userId = currentUser()?.userId else { return }
        FirebaseManager.shared.updateValues(with: "admin_user/\(userId)", values: ["venueID" : venueId]) { (error) in
            completion(error)
        }
    }
    
    func updateTakeoverID(takeoverId: String!, completion:@escaping (_ error: Error?) -> Void) {
        guard let userId = currentUser()?.userId else { return }
        FirebaseManager.shared.updateValues(with: "admin_user/\(userId)", values: ["takeoverID" : takeoverId]) { (error) in
            completion(error)
        }
    }
    
    func updatePlayback(allowPlayback: Bool!, completion:@escaping (_ error: Error?) -> Void) {
        guard let userId = currentUser()?.userId else { return }
        FirebaseManager.shared.updateValues(with: "admin_user/\(userId)", values: [User.UserKey.allowPlaybackKey : allowPlayback == true ? "true" : "false"]) { (error) in
            completion(error)
        }
    }
    
    func storeCurrentUser(user: User!) {
        let userData = NSKeyedArchiver.archivedData(withRootObject: user)
        UserDefaults.standard.set(userData, forKey: currentUserKey)
        UserDefaults.standard.synchronize()
    }
    
    func currentUser() -> User? {
        let data = UserDefaults.standard.value(forKey: currentUserKey)
        if let userData = data as? Data {
            let user = NSKeyedUnarchiver.unarchiveObject(with: userData) as? User
            return user
        }
        
        return nil
    }
    
    func removeCurrentUser() {
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        UserDefaults.standard.synchronize()
    }
    
    func storeEscrowSetupStatus(status: Bool!) {
        UserDefaults.standard.set(status, forKey: escrowSetupKey)
        UserDefaults.standard.synchronize()
    }
    
    func escrowSetupStatus() -> Bool? {
        let res = UserDefaults.standard.value(forKey: escrowSetupKey) as? Bool
        
        return res
    }
    
    func logout() {
        SpotifyManager.shared.removeSession()
        GoogleAuth.shared.logout()
        FirebaseManager.shared.logout()
        removeCurrentUser()
    }
    
    func removeAccount(userId: String!, completion: @escaping (_ error: Error?) -> Void) {
        guard let userId = userId else { return }
        
        FirebaseManager.shared.removeVenue(venueRef: "admin_user/\(userId)", completion: { (error) in
            if error != nil {
                completion(error)
            } else {
                completion(nil)
            }
        })
    }
    
    func downloadProfilePicture(url: String?) {
        guard let url = url else { return }
        if url == "" {
            return
        }
        
        let urlRequest = URLRequest(url: URL(string: url)!)
        ImageDownloader.default.download(urlRequest) { (response) in
            if let image = response.result.value {
                ImageDownloader.default.imageCache?.add(image, for: urlRequest, withIdentifier: url)
            }
        }
    }
}
