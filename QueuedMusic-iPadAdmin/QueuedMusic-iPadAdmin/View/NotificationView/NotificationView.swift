//
//  AlertView.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

@objc protocol NotificationViewDelegate: NSObjectProtocol {
    @objc optional func onOkButtonClicked(sender: NotificationView)
    @objc optional func onCancelButtonClicked(sender: NotificationView)
}

class NotificationView: UIViewController {

    private var containedController: UIViewController?
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    weak var delegate: NotificationViewDelegate?
    
    private var originY: CGFloat? = 0
    
    private let currentCheck: CheckIn?
    
    init(check: CheckIn!) {
        self.currentCheck = check
        
        super.init(nibName: "NotificationView", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.currentCheck = nil
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containedController = self
        
        setup()
        self.titleTextField.delegate = self
        self.contentTextField.delegate = self
    }

    func setup() {
        if self.currentCheck == nil {
            self.titleLabel.text = "Compose a Push Notification for All Checked in Users:"
        } else {
            self.titleLabel.text = String.init(format: "Compose a Push Notification for %@", (self.currentCheck?.username)!)
        }
    }
    
    @IBAction func onOk(_ sender: Any) {
        self.sendPNS()
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true) { 
            self.delegate?.onCancelButtonClicked?(sender: self)
        }
    }
    
    func sendPNS() {
        let title = self.titleTextField.text
        let content = self.contentTextField.text
        if title == "" {
            let alertView = AlertView(title: "Warning", message: "Please enter title.", okButtonTitle: "OK", cancelButtonTitle: nil)
            alertView.delegate = nil
            self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
            
            return
        }
        
        if content == "" {
            let alertView = AlertView(title: "Warning", message: "Please enter title.", okButtonTitle: "OK", cancelButtonTitle: nil)
            alertView.delegate = nil
            self.navigationController?.present(customModalViewController: alertView, centerYOffset: 0)
            
            return
        }
        
        dismiss(animated: true) {
            self.delegate?.onOkButtonClicked?(sender: self)
        }
    }
    
//    override var animationView: UIView { return contentView }
}


extension NotificationView: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.titleTextField {
            self.contentTextField.becomeFirstResponder()
        } else if textField == self.contentTextField {
            self.contentTextField.resignFirstResponder()
            self.sendPNS()
        }
        
        return true
    }
}
