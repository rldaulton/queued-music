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
    case guest = "guest"
}

class User: NSObject, NSCoding {
    let userId: String!
    let userName: String?
    var applePayPaymentId: String?
    var creditCardPaymentId: String?
    var customerStripeId: String?
    let email: String?
    var lifetimeVotes: Int!
    var premiumVoteBalance: Int!
    var loginType: LoginType!
    var googleAuth: GIDAuthentication?
    let joined: Date?
    let photoUrl: String?
    var FCMToken: String?
    
    struct UserKey {
        static let userIdKey = "userId"
        static let userNameKey = "userName"
        static let emailKey = "email"
        static let applePayPaymentIdKey = "applePayPaymentID"
        static let creditCardPaymentIdKey = "creditCardPaymentID"
        static let customerStripeIdKey = "customerStripeID"
        static let lifetimeVotesKey = "lifetimeVotes"
        static let premiumVoteBalanceKey = "premiumVoteBalance"
        static let loginTypeKey = "userType"
        static let googleAuthKey = "googleAuth"
        static let joinedKey = "joined"
        static let photoUrlKey = "photoUrl"
        static let tokenKey = "FCMToken"
    }
    
    init(userId: String!, userName: String?, email: String?, applePayPaymentId: String?, creditCardPaymentId: String?, customerStripeId: String?, lifetimeVotes: Int!, premiumVoteBalance: Int!, loginType: LoginType!, joined: Date?, photoUrl: String?, token: String?) {
        self.userId = userId
        self.userName = userName
        self.email = email
        self.applePayPaymentId = applePayPaymentId
        self.creditCardPaymentId = creditCardPaymentId
        self.customerStripeId = customerStripeId
        self.lifetimeVotes = lifetimeVotes
        self.premiumVoteBalance = premiumVoteBalance
        self.loginType = loginType
        self.joined = joined
        self.photoUrl = photoUrl
        self.FCMToken = token
        
        super.init()
    }
    
    init?(key:String, json: JSON) {
        userId = key
        userName = json[UserKey.userNameKey].stringValue
        email = json[UserKey.emailKey].stringValue
        applePayPaymentId = json[UserKey.applePayPaymentIdKey].stringValue
        creditCardPaymentId = json[UserKey.creditCardPaymentIdKey].stringValue
        customerStripeId = json[UserKey.customerStripeIdKey].stringValue
        lifetimeVotes = json[UserKey.lifetimeVotesKey].intValue
        premiumVoteBalance = json[UserKey.premiumVoteBalanceKey].intValue
        joined = Date(dateString: json[UserKey.joinedKey].stringValue)
        photoUrl = json[UserKey.photoUrlKey].stringValue
        FCMToken = json[UserKey.tokenKey].stringValue
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        userId = aDecoder.decodeObject(forKey: UserKey.userIdKey) as! String!
        userName = aDecoder.decodeObject(forKey: UserKey.userNameKey) as! String?
        email = aDecoder.decodeObject(forKey: UserKey.emailKey) as! String?
        applePayPaymentId = aDecoder.decodeObject(forKey: UserKey.applePayPaymentIdKey) as! String?
        creditCardPaymentId = aDecoder.decodeObject(forKey: UserKey.creditCardPaymentIdKey) as! String?
        customerStripeId = aDecoder.decodeObject(forKey: UserKey.customerStripeIdKey) as! String?
        lifetimeVotes = aDecoder.decodeObject(forKey: UserKey.lifetimeVotesKey) as! Int!
        premiumVoteBalance = aDecoder.decodeObject(forKey: UserKey.premiumVoteBalanceKey) as! Int!
        loginType = LoginType(rawValue: aDecoder.decodeObject(forKey: UserKey.loginTypeKey) as! String!)
        googleAuth = aDecoder.decodeObject(forKey: UserKey.googleAuthKey) as! GIDAuthentication?
        joined = aDecoder.decodeObject(forKey: UserKey.joinedKey) as! Date?
        photoUrl = aDecoder.decodeObject(forKey: UserKey.photoUrlKey) as! String?
        FCMToken = aDecoder.decodeObject(forKey: UserKey.tokenKey) as! String?
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(userId, forKey: UserKey.userIdKey)
        aCoder.encode(userName, forKey: UserKey.userNameKey)
        aCoder.encode(email, forKey: UserKey.emailKey)
        aCoder.encode(applePayPaymentId, forKey: UserKey.applePayPaymentIdKey)
        aCoder.encode(creditCardPaymentId, forKey: UserKey.creditCardPaymentIdKey)
        aCoder.encode(customerStripeId, forKey: UserKey.customerStripeIdKey)
        aCoder.encode(lifetimeVotes, forKey: UserKey.lifetimeVotesKey)
        aCoder.encode(premiumVoteBalance, forKey: UserKey.premiumVoteBalanceKey)
        aCoder.encode(loginType.rawValue, forKey: UserKey.loginTypeKey)
        aCoder.encode(googleAuth, forKey: UserKey.googleAuthKey)
        aCoder.encode(joined, forKey: UserKey.joinedKey)
        aCoder.encode(photoUrl, forKey: UserKey.photoUrlKey)
        aCoder.encode(FCMToken, forKey: UserKey.tokenKey)
    }
}

class UserDataModel {
    static let shared: UserDataModel = UserDataModel()
    
    private let currentUserKey = "current_user_key"
    
    func login(userId: String!, loginType: LoginType!, googleAuth: GIDAuthentication?, completion:@escaping (_ error: Error?, _ user: User?) -> Void) {
        switch loginType! {
        case .spotify:
            FirebaseManager.shared.loginAnonymously(completion: { (firebaseUser, error) in
                if error == nil, let userId = userId {
                    FirebaseManager.shared.checkChildExistence(parentRef: "user", childKey: userId, completion: { (exist, snapshot) in
                        if !exist {
                            completion(nil, nil)
                        } else {
                            FirebaseManager.shared.observeSingleEvent(with: "user/\(userId)", completion: { (snapshot) in
                                let json = JSON(snapshot.value ?? "")
                                let user = User(key: userId, json: json)
                                completion(nil, user)
                                self.downloadProfilePicture(url: user?.photoUrl)
                            })
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
                    FirebaseManager.shared.checkChildExistence(parentRef: "user", childKey: userId, completion: { (exist, snapshot) in
                        if !exist {
                            completion(nil, nil)
                        } else {
                            FirebaseManager.shared.observeSingleEvent(with: "user/\(userId)", completion: { (snapshot) in
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
                        }
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
                FirebaseManager.shared.checkChildExistence(parentRef: "user", childKey: user.userId, completion: { (exist, snapshot) in
                    if !exist {
                        let values: [String : Any] = [User.UserKey.userNameKey:user.userName ?? "",
                                                      User.UserKey.creditCardPaymentIdKey:user.creditCardPaymentId ?? "",
                                                      User.UserKey.emailKey:user.email ?? "",
                                                      User.UserKey.lifetimeVotesKey:user.lifetimeVotes,
                                                      User.UserKey.premiumVoteBalanceKey:user.premiumVoteBalance,
                                                      User.UserKey.joinedKey:user.joined?.string() ?? "",
                                                      User.UserKey.photoUrlKey:user.photoUrl ?? "",
                                                      User.UserKey.tokenKey:user.FCMToken ?? ""]
                        self.downloadProfilePicture(url: user?.photoUrl)
                        FirebaseManager.shared.addChild(parentRef: "user", childKey: user.userId, values: values, completion: { (error) in
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
                                    
                                case .guest:
                                    SpotifyManager.shared.requestToken(username: user.userId, completion: { (error, session) in
                                        if error == nil {
                                            SpotifyManager.shared.storeSession(session)
                                        }
                                        
                                        completion(nil)
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
    
    func updateUserInfo(completion:@escaping (_ error: Error?, _ user: User?) -> Void) {
        guard let userId = currentUser()?.userId else { return }
        
        FirebaseManager.shared.observeValueChanged(with: "user/\(userId)", completion: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            let user = User(key: userId, json: json)
            completion(nil, user)
        })
    }
    
    func updateFCMToken(token: String!, completion:@escaping (_ error: Error?) -> Void) {
        guard let userId = currentUser()?.userId else { return }
        let user = currentUser()
        user?.FCMToken = token
        storeCurrentUser(user: user)
        
        FirebaseManager.shared.updateValues(with: "user/\(userId)", values: ["FCMToken" : token]) { (error) in
            completion(error)
        }
    }
    
    func removeUser(userId: String!, completion: @escaping (_ error: Error?) -> Void) {
        guard let userId = userId else { return }
        
        FirebaseManager.shared.removeCheckIn(queueRef: "user/\(userId)", completion: { (error) in
            if error == nil {
                completion(nil)
            } else {
                completion(error)
            }
        })
        
        
    }
    
    func storeFirstVoteDone(value: Bool!) {
        UserDefaults.standard.set(value, forKey: "firstVoteDone")
        UserDefaults.standard.synchronize()
    }
    
    func getFirstVoteDone() -> Bool! {
        guard let data = UserDefaults.standard.value(forKey: "firstVoteDone") else {
            self.storeFirstVoteDone(value: false)
            return false
        }
        return data as! Bool
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
    
    func logout() {
        SpotifyManager.shared.removeSession()
        GoogleAuth.shared.logout()
        FirebaseManager.shared.logout()
        removeCurrentUser()
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
