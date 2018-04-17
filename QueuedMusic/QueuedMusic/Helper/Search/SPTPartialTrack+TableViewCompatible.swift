//
//  SPTPartialTrack+TableViewCompatible.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 31.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Spotify

extension SPTPartialTrack: TableViewCompatible {
    
    var reuseIdentifier: String {
        return "\(SearchTrackTableViewCell.self)"
    }
    
    func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath) as! SearchTrackTableViewCell
        cell.configureWithModel(self)
        return cell
    }
    
}
