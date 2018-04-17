//
//  AlertView.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

@objc protocol AlertViewDelegate: NSObjectProtocol {
    @objc optional func onOkButtonClicked()
    @objc optional func onCancelButtonClicked()
    @objc optional func onPerformActionClicked(action: Int)
}

class AlertView: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    @IBOutlet weak var okButtonLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButtonRightConstraint: NSLayoutConstraint!
    
    private let titleString: String?
    private let messageString: String?
    private let okButtonTitleString: String?
    private let cancelButtonTitleString: String?

    weak var delegate: AlertViewDelegate?
    
    public var tag: Int! = 0
    
    init(title: String?, message: String?, okButtonTitle: String?, cancelButtonTitle: String?) {
        self.titleString = title
        self.messageString = message
        self.okButtonTitleString = okButtonTitle
        self.cancelButtonTitleString = cancelButtonTitle
        
        super.init(nibName: "AlertView", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.titleString = ""
        self.messageString = ""
        self.okButtonTitleString = ""
        self.cancelButtonTitleString = ""
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }

    func setup() {
        titleLabel.text = titleString
        messageLabel.text = messageString
        
        if (okButtonTitleString ?? "").isEmpty {
            okButton.isHidden = true
            contentView.removeConstraint(cancelButtonRightConstraint)
            cancelButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
            cancelButton.setTitle(cancelButtonTitleString, for: .normal)
        } else if (cancelButtonTitleString ?? "").isEmpty {
            cancelButton.isHidden = true
            contentView.removeConstraint(okButtonLeftConstraint)
            okButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
            okButton.setTitle(okButtonTitleString, for: .normal)
        } else {
            okButton.setTitle(okButtonTitleString, for: .normal)
            cancelButton.setTitle(cancelButtonTitleString, for: .normal)
        }
    }
    
    @IBAction func onOk(_ sender: Any) {
        dismiss(animated: true) {
            if self.tag == 0 {
                self.delegate?.onOkButtonClicked?()
            } else {
                self.delegate?.onPerformActionClicked!(action: self.tag)
            }
        }
        
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true) { 
            self.delegate?.onCancelButtonClicked?()
        }
    }    
}
