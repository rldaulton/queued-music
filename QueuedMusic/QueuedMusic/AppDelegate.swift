//
//  AppDelegate.swift
//  QueuedMusic
//
//  Created by Ryan Daulton on 12/20/16.
//  Copyright © 2016 Red Shepard LLC. All rights reserved.
//

import UIKit
import CoreData
import Spotify
import IQKeyboardManagerSwift
import CoreStore
import Stripe
import Firebase
import GoogleSignIn
import UserNotifications
import BRYXBanner

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let appearance: AppearanceCustomizable = AppAppearance()
    
    private var bgTask: UIBackgroundTaskIdentifier? = UIBackgroundTaskInvalid
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // app style
        appearance.apply()
        
        // stripe
        STPPaymentConfiguration.shared().publishableKey = "pk_test_my-stripe-key"
        STPPaymentConfiguration.shared().appleMerchantIdentifier = "merchant.com.my-merchant-address"
        
        // firebase
        FIRApp.configure()
        
        // google
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        
        // keyboard
        IQKeyboardManager.sharedManager().enable = true
        
        // core data
        CoreStore.defaultStack = DataStack(modelName: "QueuedMusic")
        _ = CoreStore.addStorage(SQLiteStore(fileName: "QueuedMusic.sqlite"), completion: { _ in })
        
        // login implicitly
        if let user = UserDataModel.shared.currentUser() {
            UserDataModel.shared.login(userId: user.userId, loginType: user.loginType, googleAuth: user.googleAuth, completion: { _ in })
        } else {
            FirebaseManager.shared.loginAnonymously(completion: { _ in })
        }
        
        // Status bar
        UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
        
        // remote notification
        UNUserNotificationCenter.current().delegate = self
        FIRMessaging.messaging().remoteMessageDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification(_:)), name: .firInstanceIDTokenRefresh, object: nil)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        
        bgTask = application.beginBackgroundTask(withName: "endTask", expirationHandler: {
            application.endBackgroundTask(self.bgTask!)
            self.bgTask = UIBackgroundTaskInvalid
        })
        
        DispatchQueue(label: "Task").async {
            let currentUser = UserDataModel.shared.currentUser()
            let currentVenue = VenueDataModel.shared.currentVenue
            
            if currentUser != nil && currentVenue != nil {
                FirebaseManager.shared.removeCheckIn(queueRef: "check_ins/\(currentVenue?.venueId)/\(currentUser?.userId)", completion: { (error) in
                    
                })
            }
            
            if currentUser != nil && currentUser?.loginType == .guest {
                UserDataModel.shared.logout()
                UserDataModel.shared.removeUser(userId: currentUser?.userId, completion: { (error) in
                    
                })
            }
            
            application.endBackgroundTask(self.bgTask!)
            self.bgTask = UIBackgroundTaskInvalid
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        if GoogleAuth.shared.isValid(url: url) {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: [:])
        } else {
            SpotifyManager.shared.handleCallbackURL(url: url)
            return true
        }
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "QueuedMusic")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            UserDataModel.shared.updateFCMToken(token: refreshedToken, completion: { (error) in
                if let error = error {
                    print("User updated FCMToken error \(error.localizedDescription)")
                } else {
                    print("User updated FCMToken successfully")
                }
            })
        }
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved:", deviceToken)
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .sandbox)
    }
}

@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let body = notification.request.content.body
        let title = notification.request.content.title
        
        if title.range(of:"playing your request") != nil {
            UIApplication.shared.setStatusBarHidden(true, with: .none)
            let banner = Banner(title: title, subtitle: body, image: UIImage(named: "notification_music"), backgroundColor: UIColor.white)
            banner.titleLabel.textColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
            banner.detailLabel.textColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
            banner.dismissesOnTap = true
            banner.show(duration: 3.0)
        } else {
            UIApplication.shared.setStatusBarHidden(true, with: .none)
            let banner = Banner(title: title, subtitle: body, image: UIImage(named: "notification_app"), backgroundColor: UIColor.white)
            banner.titleLabel.textColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
            banner.detailLabel.textColor = #colorLiteral(red: 0.9882352941, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
            banner.dismissesOnTap = true
            banner.show(duration: 3.0)
        }
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print(userInfo)
    }
}

extension AppDelegate : FIRMessagingDelegate {
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
}
