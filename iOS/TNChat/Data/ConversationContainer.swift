//
//  ConversationContainer.swift
//  TNChat
//
//  Created by Tawa Nicolas on 24/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

class ConversationContainer: NSObject {
	var days = [MessageContainer]()
	var count: Int {
		return days.count
	}
	
	var first: ChatMessage? {
		return days.first?.messages.first
	}
	var last: ChatMessage? {
		return days.last?.messages.last
	}
	
	func count(forDay day: Int) -> Int {
		return days[day].count
	}
	
	func add(message: ChatMessage) -> (IndexPath, Bool) {
		if days.count == 0 {
			days.append(MessageContainer(withMessage: message))
			return (IndexPath(row: 0, section: 0), true)
		}
		
		for i in 0...days.count {
			if i == days.count {
				days.append(MessageContainer(withMessage: message))
				return (IndexPath(row: 0, section: i), true)
			}
			let (result, index) = days[i].include(message: message)
			if result == .orderedSame {
				return (IndexPath(row: index, section: i), false)
			} else if result == .orderedAscending {
				continue
			} else {
				days.insert(MessageContainer(withMessage: message), at: i)
				return (IndexPath(row: 0, section: i), true)
			}
		}
		return (IndexPath(), false)
	}
	
	func clear() {
		days.removeAll()
	}
	
	func message(forIndexPath indexPath: IndexPath) -> ChatMessage {
		return days[indexPath.section].messages[indexPath.row]
	}
}
