//
//  UserDataModel.swift
//  QueuedMusic
//
//  Created by Micky on 2/21/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import Firebase
import GoogleSignIn
import AlamofireImage
import Alamofire

class Customer {
    var regularUpvoteNum: Int?
    var regularDownvoteNum: Int?
    var premiumUpvoteNum: Int?
    var premiumDownvoteNum: Int?
    var songRequestsNum: Int?
    var totalVotes: Int?
    var regularVotes: Int?
    var premiumVotes: Int?
    
    func initValues() {
        self.premiumUpvoteNum = 0
        self.premiumDownvoteNum = 0
        self.regularUpvoteNum = 0
        self.regularDownvoteNum = 0
        self.songRequestsNum = 0
        self.totalVotes = 0
        self.regularVotes = 0
        self.premiumVotes = 0
    }
}

class CustomerDataModel {
    static let shared: CustomerDataModel = CustomerDataModel()
    
    func loadCustomerSummary(accountID: String!, completion: @escaping (_ customer: Customer?, _ error: Error?) -> Void) {
        guard let accountID = accountID else { return }
        
        Alamofire.request("https://my-cloud-endpoint/getEventTotals/\(accountID)", method: .get, encoding: JSONEncoding.default).responseJSON(completionHandler: { response in
            if response.result.isSuccess {
                if let data = response.data {
                    let json = JSON(data: data)
                    let resData = json.arrayObject
                    let customer = Customer()
                    customer.initValues()
                    
                    if resData != nil {
                        for item in resData! {
                            let itemData = item as? NSDictionary
                            
                            if ((itemData?.object(forKey: "event_code").coreStoreDumpString)! == "201") {
                                customer.premiumDownvoteNum = Int((itemData?.object(forKey: "f0_").coreStoreDumpString)!)
                            }
                            if ((itemData?.object(forKey: "event_code").coreStoreDumpString)! == "200") {
                                customer.premiumUpvoteNum = Int((itemData?.object(forKey: "f0_").coreStoreDumpString)!)
                            }
                            if ((itemData?.object(forKey: "event_code").coreStoreDumpString)! == "101") {
                                customer.regularDownvoteNum = Int((itemData?.object(forKey: "f0_").coreStoreDumpString)!)
                            }
                            if ((itemData?.object(forKey: "event_code").coreStoreDumpString)! == "100") {
                                customer.regularUpvoteNum = Int((itemData?.object(forKey: "f0_").coreStoreDumpString)!)
                            }
                            if ((itemData?.object(forKey: "event_code").coreStoreDumpString)! == "400") {
                                customer.songRequestsNum = Int((itemData?.object(forKey: "f0_").coreStoreDumpString)!)
                            }
                        }
                    }
                    
                    customer.regularVotes = customer.regularUpvoteNum! + customer.regularDownvoteNum!
                    customer.premiumVotes = customer.premiumUpvoteNum! + customer.premiumDownvoteNum!
                    customer.totalVotes = customer.regularVotes! + customer.premiumVotes!
                    completion(customer, nil)
                }
            } else {
                let customer = Customer()
                customer.initValues()
                completion(customer, response.error)
            }
        })
    }
    
    func loadEscrowSummary(accountID: String!, completion: @escaping (_ summary: [EscrowSummary], _ error: Error?) -> Void) {
        Alamofire.request(String.init(format: "https://my-cloud-endpoint/escrowTransfers/%@", accountID), method: .get, encoding: JSONEncoding.default).responseJSON(completionHandler: { response in
            if response.result.isSuccess {
                if let data = response.data {
                    let json = JSON(data: data)
                    let resData = json["data"].arrayValue
                    var escrowSummarys: [EscrowSummary] = []
                    for i in 0..<resData.count {
                        escrowSummarys.append(EscrowSummary(json: resData[i])!)
                    }
                    completion(escrowSummarys, nil)
                }
            } else {
                completion([], response.error)
            }
        })
    }
}
