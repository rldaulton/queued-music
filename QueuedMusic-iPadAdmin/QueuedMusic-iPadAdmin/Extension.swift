//
//  Extension.swift
//  QueuedMusic
//
//  Created by Micky on 2/3/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

extension CALayer {
    
    var borderUIColor: UIColor {
        get { return UIColor(cgColor: borderColor!) }
        set { borderColor = newValue.cgColor }
    }
}

extension Notification.Name {
    static let venueCheckedInNotification = Notification.Name("venue_checkedin_notification")
    static let homeReselectedNotification = Notification.Name("home_reselected_notification")
}

extension UITableView {
    func layoutTableHeaderView(header: UIView) {
        self.tableHeaderView = header
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let height = header.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        var frame = header.frame
        frame.size.height = height
        header.frame = frame
        self.tableHeaderView = header
    }
    
    func layoutTableFooterView(footer: UIView) {
        self.tableFooterView = footer
        footer.setNeedsLayout()
        footer.layoutIfNeeded()
        let height = footer.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        var frame = footer.frame
        frame.size.height = height
        footer.frame = frame
        self.tableFooterView = footer
    }
}

extension Date {
    init(dateString: String!) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        if let date = dateFormatter.date(from: dateString) {
            self.init(timeInterval:0, since:date)
        } else {
            self.init()
        }
    }
    
    func string() -> String! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let dateString = dateFormatter.string(from: self)
        
        return dateString
    }
}
