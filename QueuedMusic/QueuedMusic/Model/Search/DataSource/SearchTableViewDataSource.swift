//
//  SearchTableViewDataSource.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 01.02.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

final class SearchTableViewSection: TableViewSection {
    
    var sortOrder: Int = 0
    var items: [TableViewCompatible]
    var headerTitle: String?
    var footerTitle: String?
    
    required init(sortOrder: Int, items: [TableViewCompatible], headerTitle: String? = nil, footerTitle: String? = nil)  {
        self.sortOrder = sortOrder
        self.items = items
        self.headerTitle = headerTitle
        self.footerTitle = footerTitle
    }
    
}

class SearchTableViewDataSource:NSObject, UITableViewDataSource {
    
    var sections = [TableViewSection]() {
        didSet {
            sections.sort {
                $0.sortOrder < $1.sortOrder
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = sections[indexPath.section].items[indexPath.row]
        return model.cellForTableView(tableView: tableView, atIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerTitle
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerTitle
    }
    
}
