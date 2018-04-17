//
//  ViewController.swift
//  QueuedMusic
//
//  Created by Ryan Daulton on 12/20/16.
//  Copyright © 2016 Red Shepard LLC. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON
import Firebase

protocol VenueDataSourceDelegate: class {
    func dataSourceDidCompleteLoad(_ dataSource: VenueDataSource)
    func venueDidCheckIn(venue: Venue!)
}

protocol VenueConfigurable {
    func configure(with venue: Venue?)
}

protocol VenueCellConfigurable: VenueConfigurable {
    var nameLabel: UILabel! { get set }
    var distanceLabel: UILabel! { get set }
    var checkInButton: UIButton! { get set }
    var locationImageView: UIImageView! { get set }
}

extension VenueCellConfigurable {
    func configure(with venue: Venue?) {
        nameLabel?.text = venue?.name
        if let distance = venue?.distance {
            distanceLabel?.text = String(format: "%.1f mi", distance)
        }
        locationImageView.image = locationImageView.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
    }
}

extension VenueCell: VenueCellConfigurable { }

class VenueDataSource:NSObject, UITableViewDataSource {
    weak var delegate: VenueDataSourceDelegate?
    private(set) var venues: [Venue] = []
    private(set) var filteredVenues: [Venue] = []
    var currentLatitude: Double?
    var currentLongitude: Double?
    
    func load() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        VenueDataModel.shared.loadVenues { (venues) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.venues = venues
            self.filter()
            self.sort()
        }
    }
    
    func filter() {
        if let latitude = self.currentLatitude, let longitude = self.currentLongitude {
            let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
            for venue in self.venues {
                if let latitude = venue.latitude, let longitude = venue.longitude {
                    venue.distance = Float(currentLocation.distance(from: CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))) /
                        1609)
                }
            }
        }
        
        // publish
        //self.filteredVenues = self.venues.filter({ return $0.openSession && $0.distance <= 1 })
        
        // local
        self.filteredVenues = self.venues.filter({ return $0.openSession && $0.distance <= 10000 })
    }
    
    func sort() {
        self.filteredVenues.sort {
            return $0.distance < $1.distance;
        }
        self.delegate?.dataSourceDidCompleteLoad(self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VenueCell", for: indexPath) as! VenueCell
        
        let venue = self.filteredVenues[indexPath.item]
        (cell as VenueConfigurable).configure(with: venue)

        cell.checkInButton.tag = indexPath.item
        cell.checkInButton.addTarget(self, action: #selector(checkIn(sender:)), for: .touchUpInside)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredVenues.count
    }
    
    @IBAction func checkIn(sender: UIButton) {
        print(sender.tag)
        let venue = filteredVenues[sender.tag]
        delegate?.venueDidCheckIn(venue: venue)
    }
}

class CheckInViewController: BaseViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var venueTableView: UITableView!
    
    let dataSource = VenueDataSource()
    let locationManager = CLLocationManager()
    var once: Bool! = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // location manager
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // data source
        self.dataSource.delegate = self
        self.venueTableView.delegate = self
        self.venueTableView.dataSource = dataSource
        self.venueTableView.tableFooterView = UIView()
        
        dataSource.load()
        
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        guard let currentVenue = VenueDataModel.shared.currentVenue else { return }
        
        VenueDataModel.shared.removeCheckIn(venueId: currentVenue.venueId, userId: currentUser.userId) { (error) in
            if error == nil {
                
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
            break;
            
        case .authorizedAlways,
             .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
            break;
            
        case .denied:
            if (!once) {
                let alertView = AlertView(title: "Alert", message: "Please enable location service for Queue'd in your device settings.", okButtonTitle: "Settings", cancelButtonTitle: nil)
                alertView.delegate = self
                present(customModalViewController: alertView, centerYOffset: 0)
                once = true
            }
            break;
            
        default:
            break;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - UITableViewDelegate
extension CheckInViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let venue = self.dataSource.filteredVenues[indexPath.item]
        if let latitude = venue.latitude, let longitude = venue.longitude {
            let center = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpanMake(0.02, 0.02))
            self.mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - VenueDataSourceDelegate
extension CheckInViewController: VenueDataSourceDelegate {
    func dataSourceDidCompleteLoad(_ dataSource: VenueDataSource) {
        self.venueTableView.reloadData()
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        for venue in dataSource.filteredVenues {
            if let latitude = venue.latitude, let longitude = venue.longitude {
                let annotation = VenueAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
                annotation.title = venue.name
                annotation.venue = venue
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func venueDidCheckIn(venue: Venue!) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            UserDataModel.shared.updateFCMToken(token: refreshedToken, completion: { (error) in
                if let error = error {
                    print("User updated FCMToken error \(error.localizedDescription)")
                } else {
                    print("User updated FCMToken successfully")
                }
            })
        }
        
        // creating check_ins
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        
        VenueDataModel.shared.removeCheckIn(venueId: venue.venueId, userId: currentUser.userId) { (error) in
            if error == nil {
                VenueDataModel.shared.addCheckIn(venueId: venue.venueId, user: currentUser, completion: { (error) in
                    if error == nil {
                        
                    }
                })
            }
        }
        
        VenueDataModel.shared.currentVenue = venue
        NotificationCenter.default.post(name: .venueCheckedInNotification, object: nil, userInfo: ["venue":venue])
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - CLLocationManagerDelegate
extension CheckInViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        manager.stopUpdatingLocation()
        self.dataSource.currentLatitude = location.coordinate.latitude
        self.dataSource.currentLongitude = location.coordinate.longitude
        self.dataSource.load()
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpanMake(0.02, 0.02))
        self.mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            break;
        case .authorizedAlways,
             .authorizedWhenInUse,
             .denied:
            AppSetting.shared.setLocationPermissionChecked(true)
            manager.startUpdatingLocation()
            break;
        default:
            break;
        }
    }
}

// MARK: - MKMapViewDelegate
extension CheckInViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "VenuePin") as? MKPinAnnotationView {
            annotationView.annotation = annotation
            return annotationView
        } else {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "VenuePin")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? VenueAnnotation {
            if let venue = annotation.venue {
                if let index = dataSource.filteredVenues.index(of: venue) {
                    venueTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .bottom, animated: true)
                }
            }
        }
    }
}

// MARK: - AlertViewDelegate
extension CheckInViewController: AlertViewDelegate {
    func onOkButtonClicked() {
        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
    }
}
