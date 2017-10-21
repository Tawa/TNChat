//
//  Constants.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

enum NotificationName: String {
	var notification: Notification.Name {
		return Notification.Name(self.rawValue)
	}
	
	case signedIn = "NotificationNameLoggedIn"
	case signedOut = "NotificationNameLoggedOut"
}

struct SegueIdentifiers {
	static let showLogin = "showLogin"
	static let showVerification = "showVerification"
	static let showContactsList = "showContactsList"
	static let showConversation = "showConversation"
}
