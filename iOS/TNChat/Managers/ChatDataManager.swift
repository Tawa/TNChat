//
//  ChatDataManager.swift
//  TNChat
//
//  Created by Tawa Nicolas on 21/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import CoreData

// This class helps manage Chat Data cache. It fetches conversations, chat messages, creates new objects, and more.
class ChatDataManager: NSObject {
	static let shared = ChatDataManager()
	
	// This variable returns the cached conversations for the current user.
	var conversations: [ChatConversation] {
		do {
			let request: NSFetchRequest<ChatConversation> = ChatConversation.fetchRequest()
			request.predicate = NSPredicate(format: "userID == %@", CurrentUserManager.shared.userID ?? "")
			request.sortDescriptors = [NSSortDescriptor(key: "conversationTime", ascending: false)]
			return try context.fetch(request)
		} catch {
			return [ChatConversation]()
		}
	}
	
	lazy var container: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "ChatDataModel")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error {
				fatalError("Unresolved error \(error), \(error.localizedDescription)")
			}
		})
		return container
	}()
	
	lazy var context: NSManagedObjectContext = {
		return container.viewContext
	}()
	
	func saveContext() {
		let context = container.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
			}
		}
	}
	
	// This function returns the number of new messages in a conversation after a certain timestamp.
	func newMessagesCount(forConversation conversation: ChatConversation, afterTimestamp timestamp: Int64) -> Int {
		let context = self.context
		
		let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[
			NSPredicate(format: "timestamp > %ld", timestamp),
			NSPredicate(format: "conversation == %@", conversation)
			])
		
		do {
			return try context.count(for: request)
		} catch {
		}
		
		return 0
	}
	
	// This function returns the number of new messages in a conversation which the user haven't read yet.
	func newMessagesCount(forConversation conversation: ChatConversation) -> Int {
		return newMessagesCount(forConversation: conversation, afterTimestamp: conversation.updatedTime)
	}

	func conversation(withFriendID friendID: String) -> ChatConversation {
		let context = self.context
		
		let request: NSFetchRequest<ChatConversation> = ChatConversation.fetchRequest()
		request.predicate = NSPredicate(format: "friendID == %@", friendID)
		var conversation: ChatConversation?
		do {
			conversation = try context.fetch(request).first
		} catch {
		}
		
		if conversation == nil {
			conversation = ChatConversation(context: context)
			conversation?.friendID = friendID
			conversation?.userID = CurrentUserManager.shared.userID
		}
		
		return conversation!
	}
	
	// This method returns the 20 latest messages of a conversation.
	func chatMessages(forConversationWithFriendID friendID: String, beforeTimestamp timestamp: Int64? = nil) -> [ChatMessage] {
		let context = self.context
		let conversation = self.conversation(withFriendID: friendID)
		let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
		request.fetchLimit = 20
		request.sortDescriptors = [
			NSSortDescriptor(key: "timestamp", ascending: false)
		]
		
		if let timestamp = timestamp {
			request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
				[
					NSPredicate(format: "timestamp < %ld", timestamp),
					NSPredicate(format: "conversation == %@", conversation)
				])
		} else {
			request.predicate = NSPredicate(format: "conversation == %@", conversation)
		}
		
		var messages = [ChatMessage]()
		
		do {
			let array = try context.fetch(request)
			messages.append(contentsOf: array)
		} catch {
		}
		
		return messages
	}
	
	// This function fetches a specific chat message, and creates it in case it does not exist.
	func chatMessage(forUserID userID: String, date: Int, message: String, key: String) -> (ChatMessage, Bool) {
		let context = self.context
		
		let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
		request.predicate = NSPredicate(format: "id == %@", key)
		var chat: ChatMessage?
		var isNew = false
		do {
			chat = try context.fetch(request).first
		} catch {
		}
		
		if chat == nil {
			chat = ChatMessage(context: context)
			chat?.userID = userID
			chat?.timestamp = Int64(date)
			chat?.message = message
			chat?.id = key
			isNew = true
		}
		
		return (chat!, isNew)
	}
}
