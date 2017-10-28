//
//  ConversationsManager.swift
//  TNChat
//
//  Created by Tawa Nicolas on 21/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol ConversationObserverDelegate {
	var friendID: String { get }
	var currentConversation: ChatConversation { get }
	func conversationObserver(addedNewMessage message: ChatMessage)
	func conversationObserver(updatedMessage message: ChatMessage)
	func conversationObserver(friendIsOnline online: Bool, isTyping typing: Bool)
}

protocol ConversationsManagerDelegate {
	func conversationsManager(addedForUserId userID: String)
	func conversationsManager(updatedForUserId userID: String, oldIndex index: Int)
}

class ConversationsManager: NSObject {
	static let shared = ConversationsManager()
	var database: DatabaseReference?
	var conversations = [ChatConversation]()
	
	var currentfriendID: String? = nil {
		didSet {
			if let chatID = currentfriendID {
				AppDelegate.current.removeAllNotifications(forSenderID: chatID)
			}
		}
	}
	var chatID: String? {
		if let friendID = currentfriendID, let userID = CurrentUserManager.shared.userID {
			return String(forUserID: friendID, andUserId: userID)
		}
		return nil
	}
	var isTyping: Bool = false {
		didSet {
			if let userID = CurrentUserManager.shared.userID {
				if isTyping {
					typingReference?.child(userID).setValue(true)
				} else {
					typingReference?.child(userID).removeValue()
				}
			}
		}
	}
	var messagesQueryReference: DatabaseQuery!
	var databaseReference: DatabaseReference?
	var onlineReference: DatabaseReference?
	var typingReference: DatabaseReference?
	var isFriendOnline: Bool = false
	var isFriendTyping: Bool = false
	
	var delegate: ConversationsManagerDelegate?
	var conversationObserver: ConversationObserverDelegate? {
		didSet {
			if let observer = conversationObserver {
				currentfriendID = observer.friendID
				let conversation = observer.currentConversation
				
				isFriendOnline = false
				isFriendTyping = false
				
				if databaseReference == nil {
					if let chatID = chatID, let friendID = currentfriendID {
						databaseReference = Database.database().reference().child("chats/" + chatID)
						onlineReference = databaseReference?.child("online")
						let isOnlineClosure = { (data: DataSnapshot) in
							if data.key == friendID {
								self.isFriendOnline = true
							}
							observer.conversationObserver(friendIsOnline: self.isFriendOnline, isTyping: self.isFriendTyping)
						}
						let isOfflineClosure = { (data: DataSnapshot) in
							if data.key == friendID {
								self.isFriendOnline = false
							}
							observer.conversationObserver(friendIsOnline: self.isFriendOnline, isTyping: self.isFriendTyping)
						}
						onlineReference?.observe(.childAdded, with: isOnlineClosure)
						onlineReference?.observe(.childRemoved, with: isOfflineClosure)
						
						typingReference = databaseReference?.child("typing")
						let isTypingClosure = { (data: DataSnapshot) in
							if data.key == friendID {
								self.isFriendTyping = true
							}
							observer.conversationObserver(friendIsOnline: self.isFriendOnline, isTyping: self.isFriendTyping)
						}
						let isNotTypingClosure = { (data: DataSnapshot) in
							if data.key == friendID {
								self.isFriendTyping = false
							}
							observer.conversationObserver(friendIsOnline: self.isFriendOnline, isTyping: self.isFriendTyping)
						}
						typingReference?.observe(.childAdded, with: isTypingClosure)
						typingReference?.observe(.childRemoved, with: isNotTypingClosure)
						
						let start = conversation.updatedTime
						if start > 0 {
							messagesQueryReference = databaseReference?.child("messages").queryOrdered(byChild: "timestamp").queryStarting(atValue: start, childKey: "timestamp")
						} else {
							messagesQueryReference = databaseReference?.child("messages").queryOrdered(byChild: "timestamp")
						}
						messagesQueryReference?.observe(.childAdded, with: { (data) in
							let key = friendID+data.key
							if let data = data.value as? [String: Any],
								let message = data["message"] as? String,
								let userID = data["userID"] as? String,
								let timestamp = data["timestamp"] as? Int {
								let (chatMessage, isNew) = ChatDataManager.shared.chatMessage(forUserID: userID, date: timestamp, message: message, key: key)
								
								conversation.cacheTime = Int64(timestamp)
								if isNew {
									observer.conversationObserver(addedNewMessage: chatMessage)
									ChatDataManager.shared.saveContext()
								}
							}
						})
						messagesQueryReference?.observe(.childChanged, with: { (data) in
							let key = friendID+data.key
							if let data = data.value as? [String: Any],
								let message = data["message"] as? String,
								let userID = data["userID"] as? String,
								let timestamp = data["timestamp"] as? Int {
								let (chatMessage, _) = ChatDataManager.shared.chatMessage(forUserID: userID, date: timestamp, message: message, key: key)
								let timestamp = Int64(timestamp)
								conversation.cacheTime = timestamp
								chatMessage.timestamp = timestamp
								ChatDataManager.shared.saveContext()
							}
						})
					}
				}
				if let userID = CurrentUserManager.shared.userID {
					onlineReference?.child(userID).setValue(true)
				}
				
			} else {
				messagesQueryReference?.removeAllObservers()
				
				databaseReference?.removeAllObservers()
				
				if let userID = CurrentUserManager.shared.userID {
					onlineReference?.child(userID).removeValue()
					typingReference?.child(userID).removeValue()
				}
				
				onlineReference?.removeAllObservers()
				typingReference?.removeAllObservers()
				
				messagesQueryReference = nil
				databaseReference = nil
				onlineReference = nil
				typingReference = nil
				currentfriendID = nil
			}
		}
	}
	
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
	
	func send(message: String) {
		let data: [String: Any] = ["message":message,
		                           "userID":CurrentUserManager.shared.userID!,
		                           "timestamp":ServerValue.timestamp()]
		databaseReference?.child("messages").childByAutoId().setValue(data)
	}
	
	func updateConversation(forFriendID friendID: String) {
		guard let userID = CurrentUserManager.shared.userID, friendID != currentfriendID else { return }
		if friendID != currentfriendID {
			let (conversation, _) = ChatDataManager.shared.conversation(withFriendID: friendID)
			let start = conversation.cacheTime
			let chatID = String(forUserID: friendID, andUserId: userID)
			let database = Database.database().reference().child("chats/" + chatID)
			let query: DatabaseQuery
			if start > 0 {
				query = database.child("messages").queryOrdered(byChild: "timestamp").queryStarting(atValue: start, childKey: "timestamp")
			} else {
				query = database.child("messages").queryOrdered(byChild: "timestamp")
			}
			query.observeSingleEvent(of: .value, with: { (snapshot) in
				if snapshot.exists() {
					if let messages = snapshot.value as? [String: Any] {
						for data in messages {
							let key = friendID+data.key
							if let data = data.value as? [String: Any],
								let message = data["message"] as? String,
								let userID = data["userID"] as? String,
								let timestamp = data["timestamp"] as? Int {
								let (chatMessage, isNew) = ChatDataManager.shared.chatMessage(forUserID: userID, date: timestamp, message: message, key: key)
								
								if conversation.cacheTime < chatMessage.timestamp {
									conversation.cacheTime = chatMessage.timestamp
								}
								conversation.addToMessages(chatMessage)
								let oldIndex = self.conversations.index(of: conversation)
								self.reloadData()
								self.delegate?.conversationsManager(updatedForUserId: friendID, oldIndex: oldIndex ?? -1)
								if isNew {
									ChatDataManager.shared.saveContext()
								}
							}
						}
					}
				}
			})
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
					
					self.updateConversation(forFriendID: friendID)
					
					ChatDataManager.shared.saveContext()
					
					
					if isNew {
						self.reloadData()
						self.delegate?.conversationsManager(addedForUserId: friendID)
					} else {
						let oldIndex = self.conversations.index(of: conversation)
						self.reloadData()
						self.delegate?.conversationsManager(updatedForUserId: friendID, oldIndex: oldIndex ?? -1)
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
