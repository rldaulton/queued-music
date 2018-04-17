//
//  LocationPermissionViewController.swift
//  QueuedMusic
//
//  Created by Micky on 2/6/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import CoreLocation

class LocationPermissionViewController: BaseViewController {
    
    private var isDialogPresented: Bool! = false
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isDialogPresented {
            let alertView = AlertView(title: "Turn On Location Services",
                                      message: "You will be able to check in to your favorite spots and get better recommendations and deals",
                                      okButtonTitle: "Allow",
                                      cancelButtonTitle: "Not Now")
            alertView.delegate = self
            present(customModalViewController: alertView, centerYOffset: 50)
            isDialogPresented = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension LocationPermissionViewController: AlertViewDelegate {
    func onOkButtonClicked() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func onCancelButtonClicked() {
        performSegue(withIdentifier: "locationToMainSegue", sender: self)
    }
}

extension LocationPermissionViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            break;
        case .authorizedAlways,
             .authorizedWhenInUse,
             .denied:
            AppSetting.shared.setLocationPermissionChecked(true)
            performSegue(withIdentifier: "locationToMainSegue", sender: self)
            break;
        default:
            break;
        }
    }
}
