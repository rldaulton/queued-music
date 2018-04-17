//
//  Xib.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 31.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

protocol UIViewLoading {}

extension UIViewLoading where Self : UIView {
    
    static func loadFromNib() -> Self {
        let nibName = "\(self)".characters.split{$0 == "."}.map(String.init).last!
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as! Self
    }
    
}
