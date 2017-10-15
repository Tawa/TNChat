//
//  CurrentUserManager.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseMessaging

class CurrentUserManager: NSObject {
	static let shared = CurrentUserManager()
	
	var userId: String? {
		set {
			if  let oldValue = userId,
				let oldNumber = Int(oldValue) {
				Messaging.messaging().unsubscribe(fromTopic: String(oldNumber))
			}
			
			UserDefaults.standard.setValue(newValue, forKey: "userId")
			
			if  let userId = newValue,
				let newNumber = Int(userId) {
				Messaging.messaging().subscribe(toTopic: String(newNumber))
			}
		}
		get {
			return UserDefaults.standard.value(forKey: "userId") as? String
		}
	}
}
