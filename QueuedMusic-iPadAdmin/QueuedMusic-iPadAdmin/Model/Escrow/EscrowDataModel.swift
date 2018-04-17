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

class Escrow {
    var firstName: String?
    var lastName: String?
    var birthDay: String?
    var birthMonth: String?
    var birthYear: String?
    var ssn: String?
    var businessFullName: String?
    var businessTax: String?
    var address1: String?
    var address2: String?
    var city: String?
    var state: String?
    var zip: String?
    var email: String?
    var accountHolderName: String?
    var accountRoutingNumber: String?
    var accountNumber: String?
    
    func initValues() {
        self.firstName = ""
        self.lastName = ""
        self.birthDay = ""
        self.birthYear = ""
        self.birthMonth = ""
        self.ssn = ""
        self.businessTax = ""
        self.businessFullName = ""
        self.address1 = ""
        self.address2 = ""
        self.city = ""
        self.state = ""
        self.zip = ""
        self.email = ""
        self.accountNumber = ""
        self.accountHolderName = ""
        self.accountRoutingNumber = ""
    }
}

class EscrowSummary: NSObject {
    let ID: String?
    let objectValue: String?
    let amount: Int?
    let amountReversed: Int?
    let balanceTransaction: String?
    let created: Int?
    let currency: String?
    let destination: String?
    let destinationPayment: String?
    let livemode: Bool?
    let metadata: String?
    let reversed: Bool?
    let sourceTransaction: String?
    let sourceType: String?
    let transferGroup: String?
    let reversals: EscrowReversal?
    
    struct EscrowSummaryKey {
        static let idKey = "id"
        static let objectKey = "object"
        static let amountKey = "amount"
        static let amountReversedKey = "amount_reversed"
        static let balanceTransactionKey = "balance_transaction"
        static let createdKey = "created"
        static let currencyKey = "currency"
        static let destinationKey = "destination"
        static let destinationPaymentKey = "destination_payment"
        static let livemodeKey = "livemodeKey"
        static let metadataKey = "metadata"
        static let reversedKey = "reversed"
        static let sourceTransactionKey = "source_transaction"
        static let sourceTypeKey = "source_type"
        static let transferGroupKey = "transfer_gruop"
        static let reversalsKey = "reversals"
    }
    
    init?(json: JSON) {
        ID = json[EscrowSummaryKey.idKey].stringValue
        objectValue = json[EscrowSummaryKey.objectKey].stringValue
        amount = json[EscrowSummaryKey.amountKey].intValue
        amountReversed = json[EscrowSummaryKey.amountReversedKey].intValue
        balanceTransaction = json[EscrowSummaryKey.balanceTransactionKey].stringValue
        created = json[EscrowSummaryKey.createdKey].intValue
        currency = json[EscrowSummaryKey.currencyKey].stringValue
        destination = json[EscrowSummaryKey.destinationKey].stringValue
        destinationPayment = json[EscrowSummaryKey.destinationPaymentKey].stringValue
        livemode = json[EscrowSummaryKey.livemodeKey].boolValue
        metadata = json[EscrowSummaryKey.metadataKey].stringValue
        reversed = json[EscrowSummaryKey.reversedKey].boolValue
        sourceTransaction = json[EscrowSummaryKey.sourceTransactionKey].stringValue
        sourceType = json[EscrowSummaryKey.sourceTypeKey].stringValue
        transferGroup = json[EscrowSummaryKey.transferGroupKey].stringValue
        reversals = EscrowReversal(json: json[EscrowSummaryKey.reversedKey])
    }
}

class EscrowReversal : NSObject {
    let objectValue: String?
    let data: JSON?
    let hasMore: Bool?
    let totalCount: Int?
    let url: String?
    
    struct EscrowReversalKey {
        static let objectKey = "object"
        static let dataKey = "data"
        static let hasMoreKey = "has_more"
        static let totalCountKey = "total_count"
        static let urlKey = "url"
    }
    
    init?(json: JSON) {
        objectValue = json[EscrowReversalKey.objectKey].stringValue
        data = json[EscrowReversalKey.dataKey]
        hasMore = json[EscrowReversalKey.hasMoreKey].boolValue
        totalCount = json[EscrowReversalKey.totalCountKey].intValue
        url = json[EscrowReversalKey.urlKey].stringValue
        
        super.init()
    }
}

class EscrowDataModel {
    static let shared: EscrowDataModel = EscrowDataModel()
    
    func setupEscrow(escrow: Escrow!, ipAddress: String!, completion: @escaping (_ error: Error?, _ message: String?) -> Void) {
        let external_account = [
            "object": "bank_account",
            "account_number": escrow.accountNumber,
            "routing_number": escrow.accountRoutingNumber,
            "account_holder_name": escrow.accountHolderName,
            "account_holder_type":"company",
            "country":"US",
            "currency":"usd"
        ]
        
        let tos_acceptance = [
            "ip": ipAddress ?? "",
            "date": Date().timeIntervalSince1970.rounded()
        ] as [String : Any]
        
        let payout_schedule = [
            "interval":"manual"
        ]
        
        let address = [
            "city": escrow.city,
            "country": "US",
            "line1": escrow.address1,
            "line2": escrow.address2 ?? nil,
            "postal_code": escrow.zip,
            "state": escrow.state
        ]
        
        var ssnLast4 = escrow.ssn
        if (escrow.ssn?.characters.count)! > 4 {
            var start = Int((escrow.ssn?.characters.count)!)
            start = start - 4
            let index = escrow.ssn?.index((escrow.ssn?.startIndex)!, offsetBy: start)
            ssnLast4 = escrow.ssn?.substring(from: index!)
        }
        
        let legal_entity = [
            "business_name": escrow.businessFullName ?? "",
            "first_name": escrow.firstName ?? "",
            "last_name": escrow.lastName ?? "",
            "type":"company",
            "business_tax_id": escrow.businessTax ?? "",
            "ssn_last_4": ssnLast4 ?? "", // see below ****
            "personal_id_number": escrow.ssn ?? "",
            "dob": [
                "day": escrow.birthDay,
                "month": escrow.birthMonth,
                "year": escrow.birthYear
            ],
            "address": address
        ] as [String: Any]
        
        let parameters: Parameters = [
            "business_name": escrow.businessFullName ?? "",
            "default_currency": "usd",
            "email": escrow.email ?? "",
            "external_account": external_account,
            "tos_acceptance": tos_acceptance,
            "payout_schedule": payout_schedule,
            "legal_entity": legal_entity
        ]
        
        Alamofire.request("https://my-cloud-endpoint/createVenue/registerVenue", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON(completionHandler: { response in
            if response.result.isSuccess {
                if let data = response.data {
                    let json = JSON(data: data)
                    let paymentID = json["id"].stringValue
                    
                    if paymentID != "" {
                        VenueDataModel.shared.updateVenue(venueId: VenueDataModel.shared.currentVenue.venueId!, paymentID: paymentID, verified: true, completion: { (error) in
                            if error == nil {
                                let venue = VenueDataModel.shared.currentVenue
                                venue?.paymentId = paymentID
                                venue?.verified = true
                                
                                VenueDataModel.shared.currentVenue = venue
                                
                                completion(nil, "")
                            } else {
                                completion(error, error?.localizedDescription)
                            }
                        })
                    } else {
                        completion(nil, json["message"].stringValue)
                    }
                }
            } else {
                completion(response.error, response.error?.localizedDescription)
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
    
    func loadBalanceAmount(accountID: String!, completion: @escaping (_ amount: String?, _ pending: String?, _ error: Error?) -> Void) {
        Alamofire.request(String.init(format: "https://my-cloud-endpoint/accountBalance/%@", accountID), method: .get, encoding: JSONEncoding.default).responseJSON(completionHandler: { response in
            if response.result.isSuccess {
                if let data = response.data {
                    let json = JSON(data: data)
                    completion("\(json["available"][0]["amount"])", "\(json["pending"][0]["amount"])", nil)
                }
            } else {
                completion("0", "0", response.error)
            }
        })
    }
}
