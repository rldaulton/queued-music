//
//  Alert.swift
//  QueuedMusic
//
//  Created by Anton Dolzhenko on 30.01.17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit

protocol AlertRenderer {
    func displayMessage(_ title:String,msg:String)
    func displayError(_ error:NSError)
}

extension AlertRenderer where Self: UIViewController {
    func displayError(_ error:NSError){
        displayMessage("Error!", msg: error.localizedDescription)
    }
    
    func displayMessage(_ title:String,msg:String){
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) { (action) -> Void in
            alertController.dismiss(animated: true, completion:nil)
            //            self.eventHandler.dismiss()
        }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
}
