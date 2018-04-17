//
//  Venue.swift
//  QueuedMusic
//
//  Created by Micky on 1/25/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import Firebase
import HNKGooglePlacesAutocomplete

class Address: NSObject {
    let address: HNKGooglePlacesAutocompletePlace?
    let latitude: Float?
    let longitude: Float?
    
    init?(address: HNKGooglePlacesAutocompletePlace!, latitude: Float!, longitude: Float!) {
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        
        super.init()
    }
}
