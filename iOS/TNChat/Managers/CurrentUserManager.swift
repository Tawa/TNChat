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
