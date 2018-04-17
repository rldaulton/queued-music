//
//  SearchSectionHeaderView.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 31.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

class SearchSectionHeaderView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension SearchSectionHeaderView: UIViewLoading { }

extension SearchSectionHeaderView: TitlePresentable { }
