//
//  UserViewController.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//


import UIKit
import CoreStore
import Whisper
import DGElasticPullToRefresh
import Spotify
import AlamofireImage

protocol CheckInDataSourceDelegate: class {
    func dataSourceDidCompleteLoad(_ dataSource: CheckInDataSource, checks: [CheckIn]?)
    func sendPNS(check: CheckIn)
}

protocol CheckInConfigurable {
    func configure(with check: CheckIn?)
}

protocol CheckInCellConfigurable: CheckInConfigurable {
    var userEmailLabel: UILabel! { get set }
    var userNameLabel: UILabel! { get set }
    var timeLabel: UILabel! { get set }
    var pnsButton: UIButton! { get set }
}

extension CheckInCellConfigurable {
    func configure(with check: CheckIn?) {
        userEmailLabel.text = check?.email
        userNameLabel.text = check?.username == "" ? "Guest" : check?.username
        
        let date = Date()
        
        let intervals = Int(date.timeIntervalSince((check?.created)!) / 60)
        
        let days = Int(intervals / 60 / 24)
        let hours = Int((intervals - days * 24 * 60) / 60)
        let mins = Int(intervals - days * 24 * 60 - hours * 60)
        
        if days == 0 {
            if hours == 0 {
                timeLabel.text = String.init(format: "%d min", mins)
            } else {
                if mins > 10 {
                    timeLabel.text = String.init(format: "%d:%d hr", hours, mins)
                } else {
                    timeLabel.text = String.init(format: "%d:0%d hr", hours, mins)
                }
            }
        } else {
            if mins > 10 {
                timeLabel.text = String.init(format: "%d day %d:%d hr", days, hours, mins)
            } else {
                timeLabel.text = String.init(format: "%d day %d:0%d hr", days, hours, mins)
            }
        }
    }
}

extension CheckInCell: CheckInCellConfigurable { }

class CheckInDataSource: NSObject, UITableViewDataSource {
    weak var delegate: CheckInDataSourceDelegate?
    var checks: [CheckIn] = []
    
    func load(venueId: String) {
        MainViewController.showProgressBar()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        CheckInDataModel.shared.loadCheckIns(venueId: venueId) { (checks) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.delegate?.dataSourceDidCompleteLoad(self, checks: checks)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CheckInCell", for: indexPath) as! CheckInCell
        
        let check = checks[indexPath.item]
        (cell as CheckInConfigurable).configure(with: check)
        
        cell.activityView.initLabels()
        cell.activityView.setNumber(num: check.activity)
        
        cell.pnsButton.tag = indexPath.item
        cell.pnsButton.addTarget(self, action: #selector(sendPNS(sender:)), for: .touchUpInside)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.checks.count
    }
    
    @IBAction func sendPNS(sender: UIButton) {
        delegate?.sendPNS(check: checks[sender.tag])
    }
}

class UserViewController : BaseViewController {
    
    @IBOutlet weak var userTableView: UITableView!
    @IBOutlet weak var averageLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    
    var loadingView: DGElasticPullToRefreshLoadingViewCircle!
    
    let dataSource = CheckInDataSource()
    var venue: Venue!
    
    var allChecks: [CheckIn] = []
    
    var currentPNSCheckId: String!
    
    class func instance()->UIViewController{
        let homeController = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "UserViewController")
        let nav = UINavigationController(rootViewController: homeController)
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.isHidden = true
        return nav
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        dataSource.delegate = self
        userTableView.dataSource = dataSource
        userTableView.tableFooterView = UIView()
        
        loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = #colorLiteral(red: 0.9999966025, green: 0.9999999404, blue: 0.9999999404, alpha: 1)
        
        venue = VenueDataModel.shared.currentVenue
        
        loadingView.startAnimating()
        dataSource.checks.removeAll()
        userTableView.reloadData()
        dataSource.load(venueId: venue.venueId)
        
        NotificationCenter.default.addObserver(self, selector: #selector(searchValueChanged), name: NSNotification.Name.UITextFieldTextDidChange, object: nil)
    }
    
    func calculateAverage() {
        if dataSource.checks.count == 0 {
            self.averageLabel.text = "00:00 hr"
            
            return
        }
        
        var intervals = 0
        let date = Date()
        
        for check in dataSource.checks {
            intervals = intervals + Int(date.timeIntervalSince((check.created)!) / 60)
        }
        
        intervals = Int(intervals / dataSource.checks.count)
        
        let days = Int(intervals / 60 / 24)
        let hours = Int((intervals - days * 24 * 60) / 60)
        let mins = Int(intervals - days * 24 * 60 - hours * 60)
        
        if days == 0 {
            if hours == 0 {
                self.averageLabel.text = String.init(format: "%d min", mins)
            } else {
                if mins > 10 {
                    self.averageLabel.text = String.init(format: "%d:%d hr", hours, mins)
                } else {
                    self.averageLabel.text = String.init(format: "%d:0%d hr", hours, mins)
                }
            }
        } else {
            if mins > 10 {
                self.averageLabel.text = String.init(format: "%d day %d:%d hr", days, hours, mins)
            } else {
                self.averageLabel.text = String.init(format: "%d day %d:0%d hr", days, hours, mins)
            }
        }
    }
    
    @IBAction func refresh(sender: UIRefreshControl?) {
        if let venueId = venue.venueId {
            dataSource.load(venueId: venueId)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func refreshUsers(sender: UIButton) {
        self.refresh(sender: nil)
    }
    
    @IBAction func sendPNSAll(sender: UIButton) {
        self.currentPNSCheckId = ""
        
        let notificationView = NotificationView(check: nil)
        notificationView.delegate = self
        self.navigationController?.present(customModalViewController: notificationView, centerYOffset: 0)
    }
    
    @IBAction func searchValueChanged(_ sender: UITextField) {
        if self.searchTextField.text == "" {
            dataSource.checks = self.allChecks
            userTableView.reloadData()
            
            return
        }
        
        var checks: [CheckIn] = []
        
        for check in self.allChecks {
            if (check.username?.lowercased().contains((self.searchTextField.text?.lowercased())!))! || (check.email?.lowercased().contains((self.searchTextField.text?.lowercased())!))! {
                checks.append(check)
            }
        }
        
        dataSource.checks = checks
        userTableView.reloadData()
    }
}

extension UserViewController: CheckInDataSourceDelegate {
    func dataSourceDidCompleteLoad(_ dataSource: CheckInDataSource, checks: [CheckIn]?) {
        MainViewController.hideProgressBar()
        
        dataSource.checks = checks!
        userTableView.reloadData()
        
        self.allChecks = checks!
        
        calculateAverage()
    }
    
    func sendPNS(check: CheckIn) {
        self.currentPNSCheckId = check.checkInId
        
        let notificationView = NotificationView(check: check)
        notificationView.delegate = self
        self.navigationController?.present(customModalViewController: notificationView, centerYOffset: 0)
    }
}

extension UserViewController: NotificationViewDelegate {
    func onOkButtonClicked(sender: NotificationView) {
        let title = sender.titleTextField.text
        let content = sender.contentTextField.text
        
        MainViewController.showProgressBar()
        
        SpotifyManager.shared.sendPNS(userId: self.currentPNSCheckId, venueId: self.venue.venueId, title: title, body: content) { (error) in
            MainViewController.hideProgressBar()
            let alertView = AlertView(title: "Success", message: "Your Push Notification was posted successfully.", okButtonTitle: "OK", cancelButtonTitle: nil)
            self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
        }
    }
    
    func onCancelButtonClicked(sender: NotificationView) {
        
    }
}

