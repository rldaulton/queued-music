//
//  AlertView.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

@objc protocol PickerViewDelegate: NSObjectProtocol {
    @objc optional func onOkButtonClicked(sender: PickerView)
    @objc optional func onCancelButtonClicked(sender: PickerView)
}

class PickerView: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    @IBOutlet weak var okButtonLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButtonRightConstraint: NSLayoutConstraint!
    
    private let dialogContentType: Int?
    
    private var dialogTag: Int?
    
    var monthDataSource = [String]();
    var dayDataSource = [String]();
    var yearDataSource = [String]();
    var stateDataSource = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "VI", "WA", "WV", "WI", "WY"];

    weak var delegate: PickerViewDelegate?
    
    public static let DAY_PICKER = 3
    public static let MONTH_PICKER = 2
    public static let YEAR_PICKER = 4
    public static let STATE_PICKER = 11
    
    var selectedValue : String?
    
    init(contentType: Int?) {
        self.dialogContentType = contentType
        self.dialogTag = contentType
        
        super.init(nibName: "PickerView", bundle: nil)
    }
    
    func initDataSource(start: Int!, end: Int!) -> [String] {
        var datasource = [String]();
        for i in start ... end {
            if i < 10 {
                datasource.append(String.init(format: "0%d", i))
            } else {
                datasource.append(String.init(format: "%d", i))
            }
        }
        
        return datasource
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.dialogContentType = PickerView.DAY_PICKER
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
        if self.dialogContentType == PickerView.DAY_PICKER {
            self.titleLabel.text = "Day"
        } else if self.dialogContentType == PickerView.MONTH_PICKER {
            self.titleLabel.text = "Month"
        } else if self.dialogContentType == PickerView.YEAR_PICKER {
            self.titleLabel.text = "Year"
        } else if self.dialogContentType == PickerView.STATE_PICKER {
            self.titleLabel.text = "State"
        }
        
        dayDataSource = self.initDataSource(start: 1, end: 31)
        monthDataSource = self.initDataSource(start: 1, end: 12)
        yearDataSource = self.initDataSource(start: 1900, end: 2050)
        
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if self.dialogContentType == PickerView.DAY_PICKER {
            return dayDataSource.count
        } else if self.dialogContentType == PickerView.MONTH_PICKER {
            return monthDataSource.count
        } else if self.dialogContentType == PickerView.YEAR_PICKER {
            return yearDataSource.count
        } else if self.dialogContentType == PickerView.STATE_PICKER {
            return stateDataSource.count
        }
 
        return 0
    }
    /*
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if self.dialogContentType == PickerView.DAY_PICKER {
            return dayDataSource[row]
        } else if self.dialogContentType == PickerView.MONTH_PICKER {
            return monthDataSource[row]
        } else if self.dialogContentType == PickerView.YEAR_PICKER {
            return yearDataSource[row]
        } else if self.dialogContentType == PickerView.STATE_PICKER {
            return stateDataSource[row]
        }
        
        return ""
    }*/
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var attributedString = NSAttributedString(string: "", attributes: [NSForegroundColorAttributeName : UIColor.white])
        
        if self.dialogContentType == PickerView.DAY_PICKER {
            attributedString = NSAttributedString(string: dayDataSource[row], attributes: [NSForegroundColorAttributeName : UIColor.white])
        } else if self.dialogContentType == PickerView.MONTH_PICKER {
            attributedString = NSAttributedString(string: monthDataSource[row], attributes: [NSForegroundColorAttributeName : UIColor.white])
        } else if self.dialogContentType == PickerView.YEAR_PICKER {
            attributedString = NSAttributedString(string: yearDataSource[row], attributes: [NSForegroundColorAttributeName : UIColor.white])
        } else if self.dialogContentType == PickerView.STATE_PICKER {
            attributedString = NSAttributedString(string: stateDataSource[row], attributes: [NSForegroundColorAttributeName : UIColor.white])
        }
        
        return attributedString
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if self.dialogContentType == PickerView.DAY_PICKER {
            self.selectedValue = self.dayDataSource[row]
        } else if self.dialogContentType == PickerView.MONTH_PICKER {
            self.selectedValue = self.monthDataSource[row]
        } else if self.dialogContentType == PickerView.YEAR_PICKER {
            self.selectedValue = self.yearDataSource[row]
        } else if self.dialogContentType == PickerView.STATE_PICKER {
            self.selectedValue = self.stateDataSource[row]
        }
    }
//    override var animationView: UIView { return contentView }
}
