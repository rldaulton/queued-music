//
//  SPTPartialArtist+TableViewCompatible.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 31.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Spotify

extension SPTPartialArtist: TableViewCompatible {
    
    var reuseIdentifier: String {
        return "\(SearchArtistTableViewCell.self)"
    }
    
    func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath) as! SearchArtistTableViewCell
        cell.configureWithModel(self)
        return cell
    }
    
}
