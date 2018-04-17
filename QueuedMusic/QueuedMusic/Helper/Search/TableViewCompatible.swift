//
//  TableViewCompatible.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 30.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Spotify
import AlamofireImage

protocol TableViewCompatible {
    
    var reuseIdentifier: String { get }
    
    func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell
    
}

protocol TableViewSection {
    
    var sortOrder: Int { get set }
    var items: [TableViewCompatible] { get set }
    var headerTitle: String? { get set }
    var footerTitle: String? { get set }
    
    init(sortOrder: Int, items: [TableViewCompatible], headerTitle: String?, footerTitle: String?)
    
}

protocol Configurable {
    
    associatedtype T
    var model: T? { get set }
    func configureWithModel(_: T)
    
}

protocol TitlePresentable {
    
    var titleLabel: UILabel! { get set }
    
    func setTitle(title: String?)
}

extension TitlePresentable {
    
    func setTitle(title: String?) {
        titleLabel.text = title
    }
}

protocol SubtitlePresentable {
    
    var subtitleLabel: UILabel! { get set }
    
    func setSubtitle(subTitle: String?)
}

extension SubtitlePresentable {
    
    func setSubtitle(subTitle: String?) {
        subtitleLabel.text = subTitle
    }
}

protocol IconImageViewPresentable {
    
    var iconImageView: UIImageView! { get set }
    
    func setImage(with url: URL?)
}

extension IconImageViewPresentable {
    
    func setImage(with url: URL?) {
        if let url = url {
            let filter = ScaledToSizeWithRoundedCornersFilter(size:iconImageView.bounds.size,
                                                              radius:iconImageView.bounds.midY)
            iconImageView.af_setImage(withURL: url, filter: filter)
        } else {
            
        }
    }
    
}
