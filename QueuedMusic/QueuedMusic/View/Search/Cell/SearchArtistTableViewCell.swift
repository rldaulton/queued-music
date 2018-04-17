//
//  SearchArtistTableViewCell.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 30.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify

final class SearchArtistTableViewCell: UITableViewCell, TitlePresentable, SubtitlePresentable, IconImageViewPresentable {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    var model: SPTPartialArtist?
}

extension SearchArtistTableViewCell: Configurable {
    
    func configureWithModel(_ model: SPTPartialArtist) {
        self.model = model
        setTitle(title: model.name)
        setSubtitle(subTitle: "Artist")

        if let artistURI = model.uri {
            
            guard let auth = SPTAuth.defaultInstance() else { return }
            guard let session = auth.session else { return }
            let accessToken = session.accessToken
            
            SPTArtist.artist(withURI: artistURI,
                             accessToken: accessToken,
                             callback: { (error, object) in
                if let error = error {
                    print("error:\(error.localizedDescription) while retrieving full artist object: \(model.identifier) name:\(model.name)")
                } else if let artist = object as? SPTArtist,
                    let image = artist.smallestImage,
                    let imageURL = image.imageURL {
                    self.setImage(with: imageURL)
                }
            })
        }
    }
    
}
