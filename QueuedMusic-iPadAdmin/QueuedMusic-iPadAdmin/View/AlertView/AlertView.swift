//
//  AlertView.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

@objc protocol AlertViewDelegate: NSObjectProtocol {
    @objc optional func onOkButtonClicked(sender: AlertView)
    @objc optional func onCancelButtonClicked(sender: AlertView)
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
    
    private var dialogTag: Int?

    weak var delegate: AlertViewDelegate?
    
    init(title: String?, message: String?, okButtonTitle: String?, cancelButtonTitle: String?) {
        self.titleString = title
        self.messageString = message
        self.okButtonTitleString = okButtonTitle
        self.cancelButtonTitleString = cancelButtonTitle
        self.dialogTag = 0
        
        super.init(nibName: "AlertView", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.titleString = ""
        self.messageString = ""
        self.okButtonTitleString = ""
        self.cancelButtonTitleString = ""
        self.dialogTag = 0
        
        super.init(coder: aDecoder)
    }
    
    func setTagIndex(index: Int!) {
        self.dialogTag = index
    }
    
    func getTagIndex()-> Int! {
        return self.dialogTag
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
            self.delegate?.onOkButtonClicked?(sender: self)
        }
        
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true) { 
            self.delegate?.onCancelButtonClicked?(sender: self)
        }
    }
    
//    override var animationView: UIView { return contentView }
}
