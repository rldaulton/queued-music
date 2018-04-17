//
//  SearchResultsDataSource.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 01.02.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

final class SearchResultsDataSource: SearchTableViewDataSource {
    
    var delegate:SearchTrackTableViewCellDelegate?

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        guard let cellInstance = cell as? SearchTrackTableViewCell else { return cell }
        cellInstance.delegate = delegate
        return cellInstance
    }
}
