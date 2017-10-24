//
//  ConversationsManager.swift
//  TNChat
//
//  Created by Tawa Nicolas on 21/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol ConversationsManagerDelegate {
	func updatedConversation(forUserId userID: String)
	func addedConversation(forUserId userID: String)
}

class ConversationsManager: NSObject {
	static let shared = ConversationsManager()
	var database: DatabaseReference?
	var conversations = [ChatConversation]()
	
	var currentChatID: String? = nil {
		didSet {
			if let chatID = currentChatID {
				AppDelegate.current.removeAllNotifications(forSenderID: chatID)
			}
		}
	}
	
	var delegate: ConversationsManagerDelegate?
	
	override init() {
		super.init()
		
		NotificationCenter.default.addObserver(self, selector: #selector(addObservers), name: NotificationName.signedIn.notification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(addObservers), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(removeObservers), name: NotificationName.signedOut.notification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(removeObservers), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
		
		if CurrentUserManager.shared.userID != nil {
			addObservers()
		}
	}
	
	@objc func addObservers() {
		if let userID = CurrentUserManager.shared.userID {
			let chatBlock = { (data: DataSnapshot) in
				if  let messageData = data.value as? [String: Any],
					let message = messageData["message"] as? [String: Any] {
					let friendID = data.key
					
					let (conversation, isNew) = ChatDataManager.shared.conversation(withFriendID: friendID)
					
					let text = message["message"] as? String
					let timestamp = Int64(message["timestamp"] as! Int)
					
					if timestamp > conversation.conversationTime {
						conversation.conversationTime = Int64(timestamp)
						conversation.message = text
					}
					
					ChatDataManager.shared.saveContext()
					
					self.reloadData()
					
					if isNew {
						self.delegate?.addedConversation(forUserId: friendID)
					} else {
						self.delegate?.updatedConversation(forUserId: friendID)
					}
				}
			}
			
			database = Database.database().reference().child("userData/" + userID)
			database?.observe(.childAdded, with: chatBlock)
			database?.observe(.childChanged, with: chatBlock)
		}
	}

	@objc func removeObservers() {
		database?.removeAllObservers()
	}

	func reloadData() {
		conversations = ChatDataManager.shared.conversations
		conversations.sort { (chat1, chat2) -> Bool in
			return chat1.conversationTime > chat2.conversationTime
		}
	}
}
