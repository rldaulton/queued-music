//
//  SearchTrackTableViewCell.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 30.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify

protocol SearchTrackTableViewCellDelegate {
    func trackCellDidPressAddToQueue(_ cell:SearchTrackTableViewCell)
}

final class SearchTrackTableViewCell: UITableViewCell, TitlePresentable, SubtitlePresentable {
    
    var delegate:SearchTrackTableViewCellDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var addToQueueButton: UIButton!{
        didSet {
            addToQueueButton.layer.cornerRadius = 2.0
            addToQueueButton.layer.borderWidth = 1.0
            addToQueueButton.layer.borderColor = #colorLiteral(red: 1, green: 0.3568627451, blue: 0.3568627451, alpha: 1).cgColor
            addToQueueButton.layer.masksToBounds = true
        }
    }
    
    var model: SPTPartialTrack?
    
    @IBAction func addToQueueButtonTouchUpInside(_ sender: Any) {
        delegate?.trackCellDidPressAddToQueue(self)
    }
    
}

extension SearchTrackTableViewCell: Configurable {
    func configureWithModel(_ model: SPTPartialTrack) {
        self.model = model
        
        if let artistsList = model.artists as? [SPTPartialArtist] {
            let artists = artistsList.map{ $0.name! }
            setSubtitle(subTitle: artists.joined(separator: ","))
        } else {
            setSubtitle(subTitle: "Unknown artist")
        }
        
        setTitle(title: model.name)
    }
    
}
