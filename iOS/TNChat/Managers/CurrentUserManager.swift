//
//  CurrentUserManager.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseMessaging

// This class helps save the ID of the current user, and subscribe/unsubscribe from the Push Notification topic from Firebase.
// The topic is used to receive notifications when a friend sends a message to the user.
class CurrentUserManager {
	static let shared = CurrentUserManager()
	
	var userID: String? {
		set {
			if  let oldValue = userID,
				let oldNumber = Int(oldValue) {
				Messaging.messaging().unsubscribe(fromTopic: String(oldNumber))
			}
			
			UserDefaults.standard.setValue(newValue, forKey: "userID")
			
			if  let userID = newValue,
				let newNumber = Int(userID) {
				Messaging.messaging().subscribe(toTopic: String(newNumber))
			}
		}
		get {
			return UserDefaults.standard.value(forKey: "userID") as? String
		}
	}
}
