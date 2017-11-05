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
	func conversationObserver(deliveredMessage timestamp: Int64)
	func conversationObserver(readMessage timestamp: Int64)
}

// This class manages the conversations.
// It helps observe the conversations list, see which ones have new messages, downloads them, and caches the new messages.
// This function also helps with realtime chat. The protocol above has the methods to which the delegate should follow in order to be up to date with new messages, online and typing statuses.
class ConversationsManager: NSObject {
	static let shared = ConversationsManager()
	var database: DatabaseReference?
	var conversations = [ChatConversation]()
	
	// This variable stores which conversation is currently open.
	// This is also used to handle push notifications.
	var currentfriendID: String? = nil {
		didSet {
			if let chatID = currentfriendID {
				// When you open a conversation, remove all the current notifications from the notification center.
				AppDelegate.current.removeAllNotifications(forSenderID: chatID)
			}
		}
	}
	
	// This variable builds the current chatID in case it's possible.
	var chatID: String? {
		if let friendID = currentfriendID, let userID = CurrentUserManager.shared.userID {
			return String(forUserID: friendID, andUserId: userID)
		}
		return nil
	}
	
	// This variable helps set and remove the status of typing from the Firebase's conversation's path.
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
	var deliveredReference: DatabaseReference?
	var readReference: DatabaseReference?
	var isFriendOnline: Bool = false
	var isFriendTyping: Bool = false
	
	// When setting the value of this delegate, setup the observers for the Firebase's path to the messages, and the rest of the data like online and typing.
	// In case the delegate is nil, this means that the user exited the current conversation, or the app went to the background, and observers must stop.
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
						
						deliveredReference = databaseReference?.child("delivered").child(friendID)
						let deliveredClosure = { (data: DataSnapshot) in
							if let timestamp = data.value as? Int64 {
								conversation.deliveredTime = timestamp
								observer.conversationObserver(deliveredMessage: timestamp)
							}
						}
						deliveredReference?.observe(.value, with: deliveredClosure)
						
						readReference = databaseReference?.child("read").child(friendID)
						let readClosure = { (data: DataSnapshot) in
							if let timestamp = data.value as? Int64 {
								conversation.readTime = timestamp
								observer.conversationObserver(readMessage: timestamp)
							}
						}
						readReference?.observe(.value, with: readClosure)

						let start = conversation.updatedTime
						if start > 0 {
							messagesQueryReference = databaseReference?.child("messages").queryOrdered(byChild: "timestamp").queryStarting(atValue: start, childKey: "timestamp")
						} else {
							messagesQueryReference = databaseReference?.child("messages").queryOrdered(byChild: "timestamp")
						}
						messagesQueryReference?.observe(.childAdded, with: { (snapshot) in
							let key = friendID+snapshot.key
							if let data = snapshot.value as? [String: Any],
								let message = data["message"] as? String,
								let userID = data["userID"] as? String,
								let timestamp = data["timestamp"] as? Int {
								let (chatMessage, isNew) = ChatDataManager.shared.chatMessage(forUserID: userID, date: timestamp, message: message, key: key)
								
//								if userID == friendID {
//									snapshot.ref.removeValue()
//								}
								
								if Int64(timestamp) > conversation.cacheTime, userID == friendID, let currentUser = CurrentUserManager.shared.userID {
									self.databaseReference?.child("delivered").child(currentUser).setValue(timestamp)
								}
								
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
								observer.conversationObserver(updatedMessage: chatMessage)
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
				deliveredReference?.removeAllObservers()
				readReference?.removeAllObservers()
				
				messagesQueryReference = nil
				databaseReference = nil
				onlineReference = nil
				typingReference = nil
				deliveredReference = nil
				readReference = nil
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
		
		NotificationCenter.default.addObserver(self, selector: #selector(refreshApplicationBadgeCount), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
		
		if CurrentUserManager.shared.userID != nil {
			addObservers()
		}
	}
	
	// This function is used to send messages to the current conversation.
	func send(message: String) {
		let data: [String: Any] = ["message":message,
		                           "userID":CurrentUserManager.shared.userID!,
		                           "timestamp":ServerValue.timestamp()]
		databaseReference?.child("messages").childByAutoId().setValue(data)
	}
	
	func updateCurrentRead(forFriendID friendID: String, to timestamp: Int64) {
		if let userID = CurrentUserManager.shared.userID {
			let chatID = String(forUserID: friendID, andUserId: userID)
			Database.database().reference().child("chats/" + chatID).child("read").child(userID).setValue(timestamp)
		}
	}

	// This function is used to count the total amount of new messages and sets the application badge to that value.
	@objc func refreshApplicationBadgeCount() {
		var totalCount = 0
		for conversation in conversations {
			totalCount += conversation.newMessagesCount
		}
		UIApplication.shared.applicationIconBadgeNumber = totalCount
	}

	// This function fetches all the new messages in a conversation and caches them.
	func updateConversation(forFriendID friendID: String) {
		guard let userID = CurrentUserManager.shared.userID, friendID != currentfriendID else { return }
		if friendID != currentfriendID {
			let conversation = ChatDataManager.shared.conversation(withFriendID: friendID)
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
						var deliveredTime: Int64 = conversation.cacheTime
						var updateDeliveredTime: Bool = false
						for messageData in messages {
							let key = friendID+messageData.key
							if let data = messageData.value as? [String: Any],
								let message = data["message"] as? String,
								let userID = data["userID"] as? String,
								let timestamp = data["timestamp"] as? Int {
								let (chatMessage, _) = ChatDataManager.shared.chatMessage(forUserID: userID, date: timestamp, message: message, key: key)
								
								if conversation.cacheTime < chatMessage.timestamp {
									conversation.cacheTime = chatMessage.timestamp
									
									if userID != CurrentUserManager.shared.userID {
										updateDeliveredTime = true
										deliveredTime = conversation.cacheTime
									}
								}
								conversation.addToMessages(chatMessage)
								ChatDataManager.shared.saveContext()
								
//								if userID == friendID {
//									snapshot.ref.child(messageData.key).removeValue()
//								}
							}
						}
						if updateDeliveredTime, let userID = CurrentUserManager.shared.userID {
							database.child("delivered").child(userID).setValue(deliveredTime)
						}
					}
				}
				self.refreshApplicationBadgeCount()
			})
		}
	}
	
	// This function adds the observer to the userData, which contains all the conversations with their latest info.
	@objc func addObservers() {
		if let userID = CurrentUserManager.shared.userID {
			let chatBlock = { (data: DataSnapshot) in
				if  let messageData = data.value as? [String: Any],
					let message = messageData["message"] as? [String: Any] {
					let friendID = data.key
					
					let conversation = ChatDataManager.shared.conversation(withFriendID: friendID)
					
					let text = message["message"] as? String
					let timestamp = Int64(message["timestamp"] as! Int)
					
					if timestamp > conversation.conversationTime {
						conversation.conversationTime = Int64(timestamp)
						conversation.message = text
					}
					
					self.updateConversation(forFriendID: friendID)
					
					ChatDataManager.shared.saveContext()
				}
			}
			
			database = Database.database().reference().child("userData/" + userID)
			database?.observe(.childAdded, with: chatBlock)
			database?.observe(.childChanged, with: chatBlock)
		}
	}

	// This function removes the observer from the userData.
	@objc func removeObservers() {
		database?.removeAllObservers()
	}
}
