//
//  UserView.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 4/20/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import AVFoundation

public class EscrowTextView : UIView {
    
    @IBOutlet weak var textField: UITextField!
    
    var controller : EscrowSetupViewController!
    
    func initView(controller: EscrowSetupViewController!, tag: Int!) {
        self.controller = controller
        self.tag = tag
        self.textField.attributedPlaceholder = NSAttributedString(string: self.textField.placeholder!,
                                                                  attributes: [NSForegroundColorAttributeName: #colorLiteral(red: 0.3469494879, green: 0.4367325902, blue: 0.4953212738, alpha: 1)])
        
        self.textField.delegate = self
    }
    
    func validStatus(status: Bool!) {
        if status == true {
            self.layer.borderWidth = 0
        } else {
            self.layer.borderWidth = 1
            self.layer.borderUIColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        }
    }
    
    @IBAction func overlayButtonClicked(_ sender: Any) {
        self.controller.overlayButtonAction(tag: self.tag)
    }
}

extension EscrowTextView: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.controller.nextTextView(tag: self.tag)
        return true
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.validStatus(status: true)
        self.controller.hideTooltip()
        
        return true
    }
}
