//
//  AlertView.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify
import AlamofireImage

@objc protocol TakeoverViewDelegate: NSObjectProtocol {
    @objc optional func onSaveButtonClicked(sender: TakeoverView)
    @objc optional func onCancelButtonClicked(sender: TakeoverView)
}

class TakeoverView: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var saveButtonLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButtonRightConstraint: NSLayoutConstraint!
    
    weak var delegate: TakeoverViewDelegate?
    
    var playlists: [SPTPartialPlaylist] = []
    var listPage: SPTListPage?
    
    var selectedIndex: Int = -1
    
    init(playlists: [SPTPartialPlaylist], listPage: SPTListPage) {
        self.playlists = playlists
        self.listPage = listPage
        
        super.init(nibName: "TakeoverView", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.playlists = []
        self.listPage = nil
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }

    func setup() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        let nibName = UINib(nibName: "TakeoverTableCell", bundle:nil)
        self.tableView.register(nibName, forCellReuseIdentifier: "takeoverTableCell")
        self.saveButton.isHidden = true
        self.tableView.tableFooterView = UIView()
        self.tableView.tableFooterView?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    @IBAction func onOk(_ sender: Any) {
        let takeoverId = playlists[self.selectedIndex - 1].uri
        
        MainViewController.showProgressBar()
        UserDataModel.shared.updateTakeoverID(takeoverId: takeoverId?.absoluteString, completion: { (error) in
            MainViewController.hideProgressBar()
            if error == nil {
                self.dismiss(animated: true, completion: {
                    let user = UserDataModel.shared.currentUser()
                    user?.takeoverID = takeoverId?.absoluteString
                    UserDataModel.shared.storeCurrentUser(user: user)
                    
                    self.delegate?.onSaveButtonClicked!(sender: self)
                })
            }
        })
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true) { 
            self.delegate?.onCancelButtonClicked?(sender: self)
        }
    }
}

extension TakeoverView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            MainViewController.showProgressBar()
            UserDataModel.shared.updateTakeoverID(takeoverId: "", completion: { (error) in
                MainViewController.hideProgressBar()
                if error == nil {
                    self.dismiss(animated: true, completion: {
                        let user = UserDataModel.shared.currentUser()
                        user?.takeoverID = ""
                        UserDataModel.shared.storeCurrentUser(user: user)
                        
                        self.delegate?.onSaveButtonClicked!(sender: self)
                    })
                }
            })
        } else {
            self.saveButton.isHidden = false
            self.selectedIndex = indexPath.row
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension TakeoverView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "takeoverTableCell", for: indexPath) as! TakeoverTableCell
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none;
        
        if indexPath.row == 0 {
            cell.playlistImage.image = UIImage(named: "ic_takeover_close")
            cell.playlistLabel.text = "No Takeover (Disable)"
            cell.checkImage.isHidden = true
        } else {
            let playlist = playlists[indexPath.item - 1]
            
            let filter = ScaledToSizeWithRoundedCornersFilter(size:cell.playlistImage.bounds.size, radius: 0)
            cell.playlistImage.af_setImage(withURL: (playlist.largestImage.imageURL)!, filter: filter)
            cell.playlistLabel.text = playlist.name
            
            if indexPath.row == self.selectedIndex {
                cell.checkImage.isHidden = false
            } else {
                cell.checkImage.isHidden = true
            }
            
            if self.selectedIndex == -1 && playlist.uri.absoluteString == UserDataModel.shared.currentUser()?.takeoverID {
                self.selectedIndex = indexPath.item
                cell.checkImage.isHidden = false
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlists.count + 1
    }
}

