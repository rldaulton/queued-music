//
//  PaymentsDataModel.swift
//  QueuedMusic
//
//  Created by Ryan Daulton on 2/14/17.
//  Copyright © 2017 Ryan Daulton. All rights reserved.
//

import Foundation
import Stripe
import Alamofire
import SwiftyJSON
import Firebase

class CreditCard: NSObject, NSCoding {
    let number: String!
    let expMonth: UInt!
    let expYear: UInt!
    let cvc: String?
    
    struct CreditCardKey {
        static let numberKey = "number_key"
        static let expMonthKey = "exp_month_key"
        static let expYearKey = "exp_year_key"
        static let cvcKey = "cvc_key"
    }
    
    init(number: String!, expMonth: UInt!, expYear: UInt, cvc: String?) {
        self.number = number
        self.expMonth = expMonth
        self.expYear = expYear
        self.cvc = cvc
        
        super.init()
    }
       
    required init?(coder aDecoder: NSCoder) {
        number = aDecoder.decodeObject(forKey: CreditCardKey.numberKey) as! String
        expMonth = aDecoder.decodeObject(forKey: CreditCardKey.expMonthKey) as! UInt
        expYear = aDecoder.decodeObject(forKey: CreditCardKey.expYearKey) as! UInt
        cvc = aDecoder.decodeObject(forKey: CreditCardKey.numberKey) as? String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(number, forKey: CreditCardKey.numberKey)
        aCoder.encode(expMonth, forKey: CreditCardKey.expMonthKey)
        aCoder.encode(expYear, forKey: CreditCardKey.expYearKey)
        aCoder.encode(cvc, forKey: CreditCardKey.cvcKey)
    }
}

class PaymentsDataModel {
    static let shared: PaymentsDataModel = PaymentsDataModel()
    
    private let creditCardKey = "credit_card_key"
    
    func applyCreditCard(number: String, expMonth: UInt, expYear: UInt, cvc: String, completion: @escaping ((_ error: Error?) -> Void)) {
        guard let currentUser = UserDataModel.shared.currentUser(), let userId = currentUser.userId else { return }
        
        let cardParams = STPCardParams()
        cardParams.number = number
        cardParams.expMonth = expMonth
        cardParams.expYear = expYear
        cardParams.cvc = cvc
        STPAPIClient.shared().createToken(withCard: cardParams) { (token, error) in
            if let error = error {
                print("Stripe create credit card eror \(error)")
                completion(error)
            } else if let token = token {
                if (currentUser.customerStripeId ?? "").isEmpty {
                    self.createCustomer(currentUser.email, token: token.tokenId, completion: { (error, customerId, sourceId) in
                        if let error = error {
                            completion(error)
                        } else {
                            guard let customerId = customerId, let sourceId = sourceId else { return }
                            let values: [String : Any] = [User.UserKey.customerStripeIdKey : customerId,
                                                          User.UserKey.creditCardPaymentIdKey : sourceId]
                            FirebaseManager.shared.updateValues(with: "user/\(userId)", values: values, completion: { (error) in
                                if let error = error {
                                    completion(error)
                                } else {
                                    currentUser.customerStripeId = customerId
                                    currentUser.creditCardPaymentId = sourceId
                                    UserDataModel.shared.storeCurrentUser(user: currentUser)
                                    print("Created current user's customerStripeID")
                                    print("Created current user's creditCardPaymentID")
                                    completion(nil)
                                }
                            })
                        }
                    })
                } else {
                    if (currentUser.creditCardPaymentId ?? "").isEmpty {
                        self.addPaymentSource(currentUser.customerStripeId, token: token.tokenId, completion: { (error, sourceId) in
                            if let error = error  {
                                completion(error)
                            } else {
                                guard let sourceId = sourceId else { return }
                                let values: [String : Any] = [User.UserKey.creditCardPaymentIdKey : sourceId]
                                FirebaseManager.shared.updateValues(with: "user/\(userId)", values: values, completion: { (error) in
                                    if let error = error {
                                        completion(error)
                                    } else {
                                        currentUser.creditCardPaymentId = sourceId
                                        UserDataModel.shared.storeCurrentUser(user: currentUser)
                                        print("Added current user's creditCardPaymentID")
                                        completion(nil)
                                    }
                                })
                            }
                        })
                    } else {
                        self.updatePaymentSource(currentUser.customerStripeId, oldSourceId: currentUser.creditCardPaymentId, newSourceToken: token.tokenId, completion: { (error, newSourceId) in
                            if let error = error  {
                                completion(error)
                            } else {
                                guard let newSourceId = newSourceId else { return }
                                let values: [String : Any] = [User.UserKey.creditCardPaymentIdKey : newSourceId]
                                FirebaseManager.shared.updateValues(with: "user/\(userId)", values: values, completion: { (error) in
                                    if let error = error {
                                        completion(error)
                                    } else {
                                        currentUser.creditCardPaymentId = newSourceId
                                        UserDataModel.shared.storeCurrentUser(user: currentUser)
                                        print("Updated current user's creditCardPaymentID")
                                        completion(nil)
                                    }
                                })
                            }
                        })
                    }
                }
            }
        }
    }
    
    func payWithCreditCard(amount: Int!, completion: @escaping (_ error: Error?) -> Void) {
        guard let currentUser = UserDataModel.shared.currentUser() else { return }
        
        createCharge(currentUser.customerStripeId, sourceId: currentUser.creditCardPaymentId, amount: amount) { (error) in
            completion(error)
        }
    }
    
    func payWithApplePay(payment: PKPayment!, amount: Int!, completion: @escaping (_ error: Error?) -> Void) {
        guard let currentUser = UserDataModel.shared.currentUser(), let userId = currentUser.userId else { return }
        
        if (currentUser.customerStripeId ?? "").isEmpty {
            STPAPIClient.shared().createToken(with: payment) { (token, error) in
                if let error = error {
                    print("Stripe create apple pay error \(error)")
                    completion(error)
                } else if let token = token {
                    self.createCustomer(currentUser.email, token: token.tokenId, completion: { (error, customerId, sourceId) in
                        guard let customerId = customerId, let sourceId = sourceId else { return }
                        let values: [String : Any] = [User.UserKey.customerStripeIdKey : customerId,
                                                      User.UserKey.applePayPaymentIdKey : sourceId]
                        FirebaseManager.shared.updateValues(with: "user/\(userId)", values: values, completion: { (error) in
                            if let error = error {
                                completion(error)
                            } else {
                                currentUser.customerStripeId = customerId
                                currentUser.applePayPaymentId = sourceId
                                UserDataModel.shared.storeCurrentUser(user: currentUser)
                                print("Created current user's customerStripeID")
                                print("Created current user's applePayPaymentID")
                                self.createCharge(customerId, sourceId: sourceId, amount: amount, completion: { (error) in
                                    completion(error)
                                })
                            }
                        })
                    })
                }
            }
        } else if (currentUser.applePayPaymentId ?? "").isEmpty {
            STPAPIClient.shared().createToken(with: payment) { (token, error) in
                if let error = error {
                    print("Stripe create apple pay error \(error)")
                    completion(error)
                } else if let token = token {
                    self.addPaymentSource(currentUser.customerStripeId, token: token.tokenId, completion: { (error, sourceId) in
                        guard let sourceId = sourceId else {
                            completion(error)
                            return
                        }
                        
                        let values: [String : Any] = [User.UserKey.applePayPaymentIdKey : sourceId]
                        FirebaseManager.shared.updateValues(with: "user/\(userId)", values: values, completion: { (error) in
                            if let error = error {
                                completion(error)
                            } else {
                                currentUser.applePayPaymentId = sourceId
                                UserDataModel.shared.storeCurrentUser(user: currentUser)
                                print("Created current user's applePayPaymentID")
                                self.createCharge(currentUser.customerStripeId, sourceId: sourceId, amount: amount, completion: { (error) in
                                    completion(error)
                                })
                            }
                        })
                    })
                }
            }
        } else {
            createCharge(currentUser.customerStripeId, sourceId: currentUser.applePayPaymentId, amount: amount, completion: { (error) in
                completion(error)
            })
        }
    }
    
    func createCustomer(_ email: String!, token: String!, completion: @escaping (_ error: Error?, _ customerId: String?, _ sourceId: String?) -> Void) {
        guard let email = email, let token = token else { return }
        
        let url = "https://my-cloud-endpoint/createCustomer/\(email)/\(token)"
        Alamofire.request(url).responseJSON(completionHandler: { response in
            if response.result.isSuccess {
                if let responseObject = response.result.value {
                    let json = JSON(responseObject)
                    let customerId = json["id"].stringValue
                    print("Stripe created customer id \(customerId)")
                    let sourceId = json["default_source"].stringValue
                    print("Stripe default source id \(sourceId)")
                    
                    completion(nil, customerId, sourceId)
                } else {
                    completion(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"Stripe create customer error no response"]), nil, nil)
                }
            } else {
                completion(response.error, nil, nil)
            }
        })
    }
    
    func addPaymentSource(_ customerId: String!, token: String!, completion: @escaping (_ error: Error?, _ sourceId: String?) -> Void) {
        guard let customerId = customerId, let token = token else { return }
        
        let url = "https://my-cloud-endpoint/addPaymentSource/\(customerId)/\(token)"
        Alamofire.request(url).responseJSON(completionHandler: { response in
            if response.result.isSuccess {
                if let sourceId = response.result.value as? String {
                    print("Stripe added source id \(sourceId)")
                    
                    completion(nil, sourceId)
                } else {
                    completion(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"Stripe add source error no response"]), nil)
                }
            } else {
                completion(response.error, nil)
            }
        })
    }
    
    func updatePaymentSource(_ customerId: String!, oldSourceId: String!, newSourceToken: String!, completion: @escaping (_ error: Error?, _ newSourceId: String?) -> Void) {
        guard let customerId = customerId, let sourceId = oldSourceId, let token = newSourceToken else { return }
        
        let url = "https://my-cloud-endpoint/updatePaymentSource/\(customerId)/\(sourceId)/\(token)"
        Alamofire.request(url).responseJSON(completionHandler: { response in
            print(response)
            if response.result.isSuccess {
                if let newSourceId = response.result.value as? String {
                    print("Stripe updated source id \(newSourceId)")
                    
                    completion(nil, newSourceId)
                } else {
                    completion(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"Stripe update source error no response"]), nil)
                }
            } else {
                completion(response.error, nil)
            }
        })
    }
    
    func createCharge(_ customerId: String!, sourceId: String!, amount: Int!, completion: @escaping (_ error: Error?) -> Void) {
        guard let customerId = customerId, let sourceId = sourceId, let amount = amount else { return }
        guard let venueId = VenueDataModel.shared.currentVenue.venueId else { return }
        
        let url = "https://my-cloud-endpoint/initiateCharge/\(customerId)/\(sourceId)/\(amount)/\(venueId)"
        Alamofire.request(url).responseJSON(completionHandler: { response in
            if response.result.isSuccess {
                if let responseObject = response.result.value {
                    let json = JSON(responseObject)
                    
                    print("Stripe create charge \(json)")
                    
                    completion(nil)
                } else {
                    completion(NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey:"Stripe create charge error no response"]))
                }
            } else {
                completion(response.error)
            }
        })
    }
    
    func isApplePaySupported() -> Bool {
        return PKPaymentAuthorizationViewController.canMakePayments()
    }
    
    func isApplePayConfigured() -> Bool {
        return PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [PKPaymentNetwork.amex, PKPaymentNetwork.masterCard, PKPaymentNetwork.visa])
    }
}
