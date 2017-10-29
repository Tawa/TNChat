//
//  MessageContainer.swift
//  TNChat
//
//  Created by Tawa Nicolas on 24/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

class MessageContainer: NSObject {
	var date: Date
	var messages = [ChatMessageCellData]()
	var count: Int {
		return messages.count
	}
	
	init(withDate date: Date) {
		let calendar = Calendar.current
		let components = calendar.dateComponents([.year, .month, .day], from: date)
		self.date = calendar.date(from: components)!
	}
	
	convenience init(withMessage message: ChatMessage) {
		self.init(withDate: message.date)
		
		messages.append(message)
	}
	
	convenience init(withSeparator separator: NewMessagesSeparator) {
		self.init(withDate: separator.timestamp.date)
		
		messages.append(separator)
	}
	
	convenience init(withData data: ChatMessageCellData) {
		self.init(withDate: data.timestamp.date)
		
		messages.append(data)
	}
	
	func include(message: ChatMessageCellData) -> (ComparisonResult, Int) {
		let calendar = Calendar.current
		if calendar.isDate(date, inSameDayAs: message.timestamp.date) {
			var newIndex: Int = 0
			for i in 0...messages.count {
				if i == messages.count {
					newIndex = i
					break
				}
				if let oldMessage = messages[i] as? ChatMessage {
					newIndex = i
					if oldMessage.timestamp > message.timestamp {
						break
					}
				}
			}
			messages.insert(message, at: newIndex)
			return (.orderedSame, newIndex)
		} else {
			return (date.compare(message.timestamp.date), -1)
		}
	}
}
