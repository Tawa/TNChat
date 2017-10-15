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
			if let oldValue = userId {
				Messaging.messaging().unsubscribe(fromTopic: oldValue)
			}
			
			UserDefaults.standard.setValue(newValue, forKey: "userId")
			
			if let userId = newValue {
				Messaging.messaging().subscribe(toTopic: userId)
			}
		}
		get {
			return UserDefaults.standard.value(forKey: "userId") as? String
		}
	}
}
