//
//  SettingViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify
import AlamofireImage

class SettingViewController : BaseViewController {
    
    @IBOutlet weak var escrowView: UIView!
    @IBOutlet weak var adminView: UIView!
    @IBOutlet weak var venueView: UIView!
    @IBOutlet weak var setupButton: UIButton!
    @IBOutlet weak var takeoverImageView: UIImageView!
    @IBOutlet weak var takeoverEmptyView: UIView!
    @IBOutlet weak var takeoverSwitch: UISwitch!
    
    public static var playlists: [SPTPartialPlaylist] = []
    public static var listPage: SPTListPage?
    public static var featuredPlaylists: [SPTPartialPlaylist] = []
    public static var featuredListPage: SPTListPage?
    
    public static var mainViewController: MainViewController? = nil
    
    class func instance()->UIViewController{
        let homeController = UIStoryboard(name: "Setting", bundle: nil).instantiateViewController(withIdentifier: "SettingViewController")
        let nav = UINavigationController(rootViewController: homeController)
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.isHidden = true
        return nav
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.escrowViewTouch(_:)))
        self.escrowView.addGestureRecognizer(tap)
        self.escrowView.isUserInteractionEnabled = true
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(self.adminViewTouch(_:)))
        self.adminView.addGestureRecognizer(tap1)
        self.adminView.isUserInteractionEnabled = true
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.venueViewTouch(_:)))
        self.venueView.addGestureRecognizer(tap2)
        self.venueView.isUserInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if VenueDataModel.shared.currentVenue.paymentId == "" {
            self.setupButton.isHidden = false
        } else {
            self.setupButton.isHidden = true
        }
        
        if UserDataModel.shared.currentUser()?.allowPlayback == "true" {
            self.takeoverSwitch.isOn = true
        } else {
            self.takeoverSwitch.isOn = false
        }
        
        self.loadPlaylist()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func setupClicked(_ sender: Any) {
        if let parentViewController = self.parent?.parent?.parent as? MainViewController {
            EscrowSetupViewController.isEscrowSetting = true
            EscrowSetupViewController.homeViewController = nil
            parentViewController.performSegue(withIdentifier: "toEscrowSettingSetupController", sender: parentViewController)
        }
    }
    
    @IBAction func chooseTakeoverClicked(_ sender: Any) {
        self.loadPlaylists()
    }
    
    @IBAction func browseFeaturedClicked(_ sender: Any) {
        self.loadFeaturedPlaylists()
    }
    
    @IBAction func switchValueChanged(_ sender: Any) {
        UserDataModel.shared.updatePlayback(allowPlayback: self.takeoverSwitch.isOn) { (error) in
            let user = UserDataModel.shared.currentUser()
            user?.allowPlayback = self.takeoverSwitch.isOn == true ? "true" : "false"
            UserDataModel.shared.storeCurrentUser(user: user)
        }
    }
    
    func escrowViewTouch(_ sender: UITapGestureRecognizer) {
        if VenueDataModel.shared.currentVenue.paymentId == "" {
            if let parentViewController = SettingViewController.mainViewController  {
                EscrowSetupViewController.isEscrowSetting = true
                EscrowSetupViewController.homeViewController = nil
                parentViewController.performSegue(withIdentifier: "toEscrowSettingSetupController", sender: parentViewController)
            }
        } else {
            if let parentViewController = SettingViewController.mainViewController  {
                parentViewController.performSegue(withIdentifier: "openEscrowAccount", sender: parentViewController)
            }
        }
    }
    
    func adminViewTouch(_ sender: UITapGestureRecognizer) {
        if let parentViewController = SettingViewController.mainViewController  {
            parentViewController.performSegue(withIdentifier: "openAccount", sender: parentViewController)
        }
    }
    
    func venueViewTouch(_ sender: UITapGestureRecognizer) {
        let venueView = VenueView()
        venueView.delegate = self
        self.present(customModalViewController: venueView, centerYOffset: 0)
    }
    
    func loadPlaylists() {
        if SettingViewController.listPage == nil {
            MainViewController.showProgressBar()
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            SpotifyManager.shared.loadPlaylists(listPage: nil) { (listPage) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                MainViewController.hideProgressBar()
                SettingViewController.listPage = listPage
                SettingViewController.playlists.removeAll()
                if let items = listPage?.items {
                    for item in items {
                        if let playlist = item as? SPTPartialPlaylist {
                            SettingViewController.playlists.append(playlist)
                        }
                    }
                }
                
                let takeoverView = TakeoverView(playlists: SettingViewController.playlists, listPage: SettingViewController.listPage!)
                takeoverView.delegate = self
                self.present(customModalViewController: takeoverView, centerYOffset: 0)
            }
        } else {
            let takeoverView = TakeoverView(playlists: SettingViewController.playlists, listPage: SettingViewController.listPage!)
            takeoverView.delegate = self
            self.present(customModalViewController: takeoverView, centerYOffset: 0)
        }
    }
    
    func loadFeaturedPlaylists() {
        if SettingViewController.featuredListPage == nil {
            MainViewController.showProgressBar()
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            SpotifyManager.shared.loadFeaturedPlaylists(listPage: nil) { (listPage) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                MainViewController.hideProgressBar()
                SettingViewController.featuredListPage = listPage
                SettingViewController.featuredPlaylists.removeAll()
                if let items = listPage?.items {
                    for item in items {
                        if let playlist = item as? SPTPartialPlaylist {
                            SettingViewController.featuredPlaylists.append(playlist)
                        }
                    }
                }
                
                let takeoverView = TakeoverView(playlists: SettingViewController.featuredPlaylists, listPage: SettingViewController.featuredListPage!)
                takeoverView.delegate = self
                self.present(customModalViewController: takeoverView, centerYOffset: 0)
            }
        } else {
            let takeoverView = TakeoverView(playlists: SettingViewController.featuredPlaylists, listPage: SettingViewController.featuredListPage!)
            takeoverView.delegate = self
            self.present(customModalViewController: takeoverView, centerYOffset: 0)
        }
    }
    
    func loadPlaylist() {
        guard let takeoverId = UserDataModel.shared.currentUser()?.takeoverID else { return }
        
        if takeoverId == "" {
            self.takeoverEmptyView.isHidden = false
        } else {
            self.takeoverEmptyView.isHidden = true
            
            SpotifyManager.shared.loadPlaylist(withURI: NSURL(string: takeoverId) as URL!, completion: { (snapshot) in
                if snapshot != nil {
                    let filter = ScaledToSizeWithRoundedCornersFilter(size:self.takeoverImageView.bounds.size, radius: 0)
                    self.takeoverImageView.af_setImage(withURL: (snapshot?.largestImage.imageURL)!, filter: filter)
                }
            })
        }
    }
}

extension SettingViewController: TakeoverViewDelegate {
    func onSaveButtonClicked(sender: TakeoverView) {
        self.loadPlaylist()
    }
    
    func onCancelButtonClicked(sender: TakeoverView) {
        
    }
}

extension SettingViewController: VenueViewDelegate {
    func onUpdateButtonClicked(sender: VenueView) {
        
    }
}
