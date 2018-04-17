//
//  MainViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import PKHUD

class MainViewController : BaseViewController {
    
    var tabController:AZTabBarController!
    var homeViewController : UIViewController? = nil
    
    @IBOutlet weak var allowView: UIView?
    @IBOutlet weak var allowSwitch: UISwitch?
    @IBOutlet weak var tabView: UIView?
    
    var isFirstLoading: Bool! = true
    
    public static var dependencies: PlaylistViewControllerDependencies! = nil
    
    typealias PlaylistViewControllerDependencies = (player: LGAudioPlayer, bundle: Bundle, notificationCenter: NotificationCenter)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var icons = [UIImage]()
        icons.append(#imageLiteral(resourceName: "ic_home"))
        icons.append(#imageLiteral(resourceName: "ic_queue"))
        //icons.append(#imageLiteral(resourceName: "ic_analytics"))
        icons.append(#imageLiteral(resourceName: "ic_users"))
        icons.append(#imageLiteral(resourceName: "ic_setting_selected"))
        icons.append(#imageLiteral(resourceName: "ic_logout"))
        
        var sIcons = [UIImage]()
        sIcons.append(#imageLiteral(resourceName: "ic_home"))
        sIcons.append(#imageLiteral(resourceName: "ic_queue"))
        //sIcons.append(#imageLiteral(resourceName: "ic_analytics"))
        sIcons.append(#imageLiteral(resourceName: "ic_users"))
        sIcons.append(#imageLiteral(resourceName: "ic_setting_selected"))
        sIcons.append(#imageLiteral(resourceName: "ic_logout"))
        
        self.allowView?.isHidden = true
        //init
        //tabController = AZTabBarController.insert(into: self, withTabIconNames: icons)
        tabController = AZTabBarController.insert(into: self, view: self.tabView!, withTabIcons: icons, andSelectedIcons: sIcons)
        
        //set delegate
        tabController.delegate = self
        
        //set child controllers
        
        self.homeViewController = HomeViewController.instance()
        
        tabController.setViewController(self.homeViewController!, atIndex: 0)
        
        tabController.setViewController(QueueViewController.instance(), atIndex: 1)
        
        //tabController.setViewController(AnalyticsViewController.instance(), atIndex: 2)
        
        tabController.setViewController(UserViewController.instance(), atIndex: 2)
        
        tabController.setViewController(SettingViewController.instance(), atIndex: 3)
        
        //tabController.setViewController(HomeViewController.instance(), atIndex: 5)
        
        
        //customize
        
        tabController.buttonsBackgroundColor = #colorLiteral(red: 0.09803921569, green: 0.1607843137, blue: 0.2039215686, alpha: 1)
        
        tabController.selectedColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) //UIColor(colorLiteralRed: 14.0/255, green: 122.0/255, blue: 254.0/255, alpha: 1.0)
        
        tabController.highlightColor = #colorLiteral(red: 0.1803921569, green: 0.8, blue: 0.4431372549, alpha: 1)
        
        tabController.defaultColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        tabController.buttonsBackgroundColor = UIColor(colorLiteralRed: (247.0/255), green: (247.0/255), blue: (247.0/255), alpha: 1.0)//#colorLiteral(red: 0.2039215686, green: 0.2862745098, blue: 0.368627451, alpha: 1)
        
        tabController.selectionIndicatorHeight = 0
        
        tabController.selectionIndicatorColor = #colorLiteral(red: 0.1803921569, green: 0.8, blue: 0.4431372549, alpha: 1)
        
        tabController.tabBarWidth = 80
        
        tabController.setAction(atIndex: 3){
            self.allowView?.isHidden = false
            guard let currentVenue = VenueDataModel.shared.currentVenue else { return }
            self.allowSwitch?.isOn = currentVenue.openSession
        }
        
        tabController.setAction(atIndex: 0) {
            self.allowView?.isHidden = true
            
            if self.isFirstLoading == false {
                if (VenueDataModel.shared.currentVenue != nil) {
                    let controller = self.homeViewController?.childViewControllers[0] as? HomeViewController
                    controller?.reloadEscrowData()
                }
            }
        }
        
        tabController.setAction(atIndex: 1) {
            self.allowView?.isHidden = true
        }
        
        tabController.setAction(atIndex: 2) {
            self.allowView?.isHidden = true
        }
        
        tabController.setAction(atIndex: 4) {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: 10000), execute: { 
                let alertView = AlertView(title: "Warning", message: "Are you sure to log out?", okButtonTitle: "Yes", cancelButtonTitle: "No")
                alertView.delegate = self
                self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
            })
        }
        
        tabController.setIndex(0, animated: false)
        
        tabController.animateTabChange = true
        
        self.isFirstLoading = true
        
        SettingViewController.mainViewController = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isFirstLoading == true {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: 10000), execute: {
                self.getVenueInfo()
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchValueChanged(_ sender: Any) {
        guard var currentVenue = VenueDataModel.shared.currentVenue else { return }
        
        VenueDataModel.shared.updateVenue(venueId: currentVenue.venueId, openSession: self.allowSwitch?.isOn) { (error) in
            currentVenue.openSession = (self.allowSwitch?.isOn)!
            VenueDataModel.shared.currentVenue = currentVenue
        }
    }
    
    func gotoQueuePage() {
        tabController.setIndex(1, animated: true)
    }
    
    func getVenueInfo() {
        MainViewController.showProgressBar()
        
        VenueDataModel.shared.loadVenues { (venues) in
            for venue in venues {
                if UserDataModel.shared.currentUser()?.venueID == venue.venueId {
                    VenueDataModel.shared.currentVenue = venue
                }
            }
            
            MainViewController.hideProgressBar()
            self.isFirstLoading = false
            
            if (VenueDataModel.shared.currentVenue != nil) {
                if let view = self.view as? MainView {
                    VenueView.mainView = view
                    view.updateVenueNameLabel(name: VenueDataModel.shared.currentVenue.name!)
                    let controller = self.homeViewController?.childViewControllers[0] as? HomeViewController
                    controller?.setParentViewController(controller: self)
                    controller?.loadData()
                }
            }
        }
    }
}

extension MainViewController {
    static func showProgressBar() {
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
    }
    
    static func hideProgressBar() {
        PKHUD.sharedHUD.hide()
    }
}

extension MainViewController: AZTabBarDelegate{
    func tabBar(_ tabBar: AZTabBarController, statusBarStyleForIndex index: Int) -> UIStatusBarStyle {
        return (index % 2) == 0 ? .default : .lightContent
    }
    
    func tabBar(_ tabBar: AZTabBarController, shouldLongClickForIndex index: Int) -> Bool {
        return false//index != 2 && index != 3
    }
    
    func tabBar(_ tabBar: AZTabBarController, shouldAnimateButtonInteractionAtIndex index: Int) -> Bool {
        return true //index != 2
    }
    
    func tabBar(_ tabBar: AZTabBarController, didMoveToTabAtIndex index: Int) {
        print("didMoveToTabAtIndex \(index)")
    }
    
    func tabBar(_ tabBar: AZTabBarController, didSelectTabAtIndex index: Int) {
        print("didSelectTabAtIndex \(index)")
    }
    
    func tabBar(_ tabBar: AZTabBarController, willMoveToTabAtIndex index: Int) {
        print("willMoveToTabAtIndex \(index)")
    }
    
    func tabBar(_ tabBar: AZTabBarController, didLongClickTabAtIndex index: Int) {
        print("didLongClickTabAtIndex \(index)")
    }
    /*
    func tabBar(_ tabBar: AZTabBarController, systemSoundIdForButtonAtIndex index: Int) -> SystemSoundID? {
        return tabBar.selectedIndex == index ? nil : audioId
    }*/
}

extension MainViewController: AlertViewDelegate {
    func onOkButtonClicked(sender: AlertView) {
        if VenueDataModel.shared.currentVenue != nil && QueueViewController.userTracks.count > 0 {
            for track in QueueViewController.userTracks {
                if track.playing == true {
                    let venueId = VenueDataModel.shared.currentVenue.venueId!
                    let trackId = track.trackId!
                    
                    QueueDataModel.shared.updatePlayingStatus(venueId: venueId, trackId: trackId, status: false) { (error) in
                        
                    }
                }
            }
        }
        UserDataModel.shared.logout()
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    func onCancelButtonClicked(sender: AlertView) {
        
    }
}

