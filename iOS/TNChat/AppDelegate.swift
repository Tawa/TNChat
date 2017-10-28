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
	static var current: AppDelegate {
		return UIApplication.shared.delegate as! AppDelegate
	}

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		FirebaseApp.configure()

		askForPushNotificationsPermissions()
		
		return true
	}
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		Auth.auth().setAPNSToken(deviceToken, type: .prod)
		Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
	
	var isNotificationsOn: Bool {
		set {
			UserDefaults.standard.set(newValue, forKey: "NotificationsStatus")
		}
		get {
			return UserDefaults.standard.bool(forKey: "NotificationsStatus")
		}
	}
	
	func askForPushNotificationsPermissions() {
		let center = UNUserNotificationCenter.current()
		center.delegate = self
		
		center.getNotificationSettings { result in
			switch result.authorizationStatus {
			case .notDetermined:
				center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
					if granted {
						self.isNotificationsOn = true
						DispatchQueue.main.async {
							UIApplication.shared.registerForRemoteNotifications()
						}
					} else {
						self.isNotificationsOn = false
					}
				}
			case .denied:
				break
			case .authorized:
				DispatchQueue.main.async {
					UIApplication.shared.registerForRemoteNotifications()
				}
			}
		}
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		if let friendID = userInfo["userID"] as? String, friendID != ConversationsManager.shared.currentfriendID {
			let key: String = (userInfo["key"] as? String)!
			let message: String = (userInfo["message"] as? String)!
			let timestamp: Int = Int(userInfo["timestamp"] as! String)!
			
			let (conversation, _) = ChatDataManager.shared.conversation(withFriendID: friendID)
			let (chatMessage, _) = ChatDataManager.shared.chatMessage(forUserID: friendID, date: timestamp, message: message, key: friendID+key)
			conversation.addToMessages(chatMessage)
			
			ChatDataManager.shared.saveContext()
			
			application.applicationIconBadgeNumber += 1
			
			if AppDelegate.current.isNotificationsOn {
				let contact = ContactsManager.shared.getContact(withPhoneNumber: friendID)
				
				let content = UNMutableNotificationContent()
				content.title = contact.name ?? ("+"+friendID)
				content.body = message
				content.userInfo = ["userID":friendID]
				content.sound = UNNotificationSound(named: "default")
				content.badge = NSNumber(integerLiteral: application.applicationIconBadgeNumber + 1)
				
				let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.001, repeats: false)
				
				let notificationRequest = UNNotificationRequest(identifier: "\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
				
				UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: nil)
			}
		}
		completionHandler(.noData)
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		
		if let sender = response.notification.request.content.userInfo["userID"] as? String {
			let contact = ContactsManager.shared.getContact(withPhoneNumber: sender)
			NotificationCenter.default.post(name: NotificationName.openChat.notification, object: contact)
		}
		
		completionHandler()
	}
	
	func removeAllNotifications(forSenderID senderID: String? = nil) {
		let center = UNUserNotificationCenter.current()
		if let senderID = senderID {
			center.getDeliveredNotifications { (notifications) in
				var identifiers = [String]()
				for notification in notifications {
					if  let userID = notification.request.content.userInfo["userID"] as? String,
						userID == senderID {
						identifiers.append(notification.request.identifier)
					}
				}
				if identifiers.count > 0 {
					center.removeDeliveredNotifications(withIdentifiers: identifiers)
				}
			}
		} else {
			center.getDeliveredNotifications { (notifications) in
				var identifiers = [String]()
				for notification in notifications {
					if  let _ = notification.request.content.userInfo["userID"] as? String {
						identifiers.append(notification.request.identifier)
					}
				}
				if identifiers.count > 0 {
					center.removeDeliveredNotifications(withIdentifiers: identifiers)
				}
			}
		}
	}
}
