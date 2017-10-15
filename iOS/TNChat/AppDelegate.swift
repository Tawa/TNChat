//
//  AppDelegate.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		FirebaseApp.configure()
		
		askForPushNotificationsPermissions()
		
		return true
	}

}

extension AppDelegate: UNUserNotificationCenterDelegate {
	func askForPushNotificationsPermissions() {
		let center = UNUserNotificationCenter.current()
		center.delegate = self
		center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
			if granted {
				DispatchQueue.main.async {
					UIApplication.shared.registerForRemoteNotifications()
				}
			}
		}
	}
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		Auth.auth().setAPNSToken(deviceToken, type: .prod)
		Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
	}
}
