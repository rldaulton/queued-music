//
//  SpotifyManager.swift
//  QueuedMusic
//
//  Created by Micky on 2/2/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify
import SafariServices
import PKHUD
import Alamofire
import SwiftyJSON

class SpotifyManager {
    
    static let shared: SpotifyManager = SpotifyManager()
    
    fileprivate let clientId        = "spotify-client-id"
    fileprivate let callbackURL     = "qmusic://returnafterlogin"
    fileprivate let tokenSwapURL    = "https://my-token-swap-url/swap"
    fileprivate let tokenRefreshURL = "https://my-token-refresh-url/refresh"
    
    private let sessionKey = "session_key"
    
    var session: SPTSession!
    var controller: UIViewController!
    var completion: ((_ error:Error?, _ user: SPTUser?) -> Void)?
    
    private init() {
        guard let auth = SPTAuth.defaultInstance() else { return }
        
        auth.clientID = clientId
        auth.redirectURL = URL(string:callbackURL)
        auth.requestedScopes = [SPTAuthUserReadPrivateScope, SPTAuthUserReadEmailScope, SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope]
        auth.tokenSwapURL = URL(string:tokenSwapURL)
        auth.tokenRefreshURL = URL(string:tokenRefreshURL)
    }
    
    func handleCallbackURL(url: URL) {
        controller.presentedViewController?.dismiss(animated: true, completion: nil)
        
        guard let auth = SPTAuth.defaultInstance() else { return }
        if auth.canHandle(url) {
            print(url)
            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: { (error: Error?, session: SPTSession?) in
                if let error = error {
                    print("spotify auth handle url error: \(error.localizedDescription)")
                    auth.session = nil
                    self.completion?(error, nil)
                } else {
                    auth.session = session
                    SpotifyManager.shared.storeSession(session)
                    SPTUser.requestCurrentUser(withAccessToken: auth.session.accessToken, callback: { (error, response) in
                        if let error = error {
                            print("Spotify get current user error \(error.localizedDescription)")
                            self.completion?(error, nil)
                        } else if let user = response as? SPTUser {
                            self.completion?(nil, user)
                        }
                    })
                }
            })
        } else {
            print("Spotify can not handle callback url")
            completion?(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"Spotify can not handle callback url"]), nil)
        }
    }
    
    func login(controller: UIViewController, completion: @escaping (_ error: Error?, _ user: SPTUser?) -> Void) {
        self.controller = controller
        self.completion = completion
        guard let auth = SPTAuth.defaultInstance() else { return }
        
        if SPTAuth.supportsApplicationAuthentication() {
            UIApplication.shared.open(auth.spotifyAppAuthenticationURL(), options: [:], completionHandler: nil)
        } else {
            let safariController = SFSafariViewController(url: auth.spotifyWebAuthenticationURL())
            controller.present(safariController, animated: true, completion: nil)
        }
    }
    
    func requestToken(username: String!, completion: @escaping (_ error: Error?, _ session: SPTSession?) -> Void) {
        var headers: HTTPHeaders = [:]
        
        if let authorizationHeader = Request.authorizationHeader(user: "d48b884e65a244f793958a9832f60b0a", password: "228af62816db44029ceaf5bf64bf40c2") {
            headers[authorizationHeader.key]=authorizationHeader.value
        }
        
        let parameters: Parameters = ["grant_type": "client_credentials"]
        
        let urlString = "https://accounts.spotify.com/api/token"
        var URLs: URL?
        do {
            URLs = try urlString.asURL()
        } catch {
            print("ERROR: \(AFError.self)")
        }
        
        Alamofire.request(URLs!, method: .post, parameters: parameters, encoding: URLEncoding(destination: .httpBody), headers: headers).response { response in
            if let error = response.error {
                print("Spotify request access token error \(error.localizedDescription)")
                completion(error, nil)
            } else if let data = response.data {
                let json = JSON(data: data)
                let session = SPTSession(userName: username, accessToken: json["access_token"].stringValue, expirationTimeInterval: json["expires_in"].doubleValue)
                completion(nil, session)
                
            } else {
                completion(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"Can't fetch access token from Spotify"]), nil)
            }
        }
    }
    
    func trackUserActions(userID: String!, venueID: String!, eventCode: String!, eventDesc: String!, completion: @escaping (_ error: Error?) -> Void) {
        let parameters: Parameters = [
            "event_code": eventCode,
            "event_time": Int(Date().timeIntervalSince1970),
            "user_id": userID,
            "event_details_desc": eventDesc,
            "user_org": venueID
        ]
        
        Alamofire.request("https://my-cloud-endpoint/logE/", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON(completionHandler: { response in
            if response.result.isSuccess {
                completion(nil)
            } else {
                completion(response.error)
            }
        })
    }
    
    func storeSession(_ session: SPTSession!) {
        let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
        UserDefaults.standard.setValue(sessionData, forKey: sessionKey)
        UserDefaults.standard.synchronize()
    }
    
    func getSession() -> SPTSession? {
        if let sessionData = UserDefaults.standard.value(forKey: sessionKey) as? Data {
            let session = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as? SPTSession
            return session
        } else {
            return nil
        }
    }
    
    func removeSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        UserDefaults.standard.synchronize()
        
        guard let auth = SPTAuth.defaultInstance() else { return }
        auth.session = nil
    }
    
    func refreshSession(completion: @escaping () -> Void) {
        guard let auth = SPTAuth.defaultInstance() else { return }
        if auth.session == nil {
            auth.session = getSession()
        }
        
        guard let session = auth.session else { return }
        guard let user = UserDataModel.shared.currentUser() else { return }
        if !session.isValid() && auth.hasTokenRefreshService {
            if user.loginType == .google {
                SpotifyManager.shared.requestToken(username: user.userId, completion: { (error, session) in
                    if error == nil {
                        SpotifyManager.shared.storeSession(session)
                    }
                    completion()
                })
            } else {
                auth.renewSession(session, callback: { (error, newSession) in
                    if let error = error {
                        print("spotify renew session error: \(error.localizedDescription)")
                    } else {
                        auth.session = newSession
                        self.storeSession(newSession)
                    }
                    completion()
                })
            }
        } else {
            completion()
        }
    }
    
    func loadPlaylists(listPage: SPTListPage?, completion: @escaping (_ listPage: SPTListPage?) -> Void) {
        guard let auth = SPTAuth.defaultInstance() else { return }
        
        refreshSession {
            if listPage == nil {
                SPTPlaylistList.playlists(forUser: auth.session.canonicalUsername, withAccessToken: auth.session.accessToken, callback: { (error, response) in
                    if error == nil {
                        let listPage = response as! SPTListPage
                        completion(listPage);
                    } else {
                        print("spotify load playlist error: \(error?.localizedDescription)")
                        completion(nil)
                    }
                })
            } else {
                if listPage?.hasNextPage == true {
                    listPage?.requestNextPage(withAccessToken: auth.session.accessToken, callback: { (error, response) in
                        if error == nil {
                            let listPage = response as! SPTListPage
                            completion(listPage);
                        } else {
                            print("spotify load playlist error: \(error?.localizedDescription)")
                            completion(nil)
                        }
                    })
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func loadSonglist(url: URL, listPage: SPTListPage?, completion: @escaping (_ listPage: SPTListPage?) -> Void) {
        guard let auth = SPTAuth.defaultInstance() else { return }
        
        refreshSession {
            if listPage == nil {
                let marketUrlStr = String(format: "%@?market=us", url.absoluteString)
                let marketUrl = URL(string: marketUrlStr)
                SPTPlaylistSnapshot.playlist(withURI: marketUrl, accessToken: auth.session.accessToken, callback: { (error, response) in
                    if error == nil {
                        if let snapshot = response as? SPTPlaylistSnapshot {
                            let listPage = snapshot.firstTrackPage
                            completion(listPage)
                        } else {
                            print("spotify load songlist error: invalid response")
                            completion(nil)
                        }
                    } else {
                        print("spotify load songlist error: \(error?.localizedDescription)")
                        completion(nil)
                    }
                })
            } else {
                if listPage?.hasNextPage == true {
                    listPage?.requestNextPage(withAccessToken: auth.session.accessToken, callback: { (error, response) in
                        if error == nil {
                            if let page = response as? SPTListPage {
                                completion(page)
                            } else {
                                print("spotify load songlist error: invalid response")
                                completion(nil)
                            }
                        } else {
                            print("spotify load songlist error: \(error?.localizedDescription)")
                            completion(nil)
                        }
                    })
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func loadFeaturedPlaylists(listPage: SPTListPage?, completion: @escaping (_ listPage: SPTListPage?) -> Void) {
        guard let auth = SPTAuth.defaultInstance() else { return }
        
        refreshSession {
            if listPage == nil {
                SPTBrowse.requestFeaturedPlaylists(forCountry: nil, limit: 50, offset: 0, locale: nil, timestamp: nil, accessToken: auth.session.accessToken, accessTokenType: auth.session.tokenType, callback: { (error, response) in
                    if error == nil {
                        let listPage = response as! SPTListPage
                        completion(listPage);
                    } else {
                        print("spotify load featured playlist error: \(error?.localizedDescription)")
                        completion(nil)
                    }
                })
            } else {
                if listPage?.hasNextPage == true {
                    listPage?.requestNextPage(withAccessToken: auth.session.accessToken, callback: { (error, response) in
                        if error == nil {
                            let listPage = response as! SPTListPage
                            completion(listPage);
                        } else {
                            print("spotify load featured playlist error: \(error?.localizedDescription)")
                            completion(nil)
                        }
                    })
                } else {
                    completion(nil)
                }
            }
        }
    }
}
