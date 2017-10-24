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
	var messages = [ChatMessage]()
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
	
	func include(message: ChatMessage) -> (ComparisonResult, Int) {
		let calendar = Calendar.current
		if calendar.isDate(date, inSameDayAs: message.date) {
			var newIndex: Int = 0
			for i in 0...messages.count {
				if i == messages.count {
					newIndex = i
					break
				}
				let oldMessage = messages[i]
				newIndex = i
				if oldMessage.timestamp > message.timestamp {
					break
				}
			}
			messages.insert(message, at: newIndex)
			return (.orderedSame, newIndex)
		} else {
			return (date.compare(message.date), -1)
		}
	}
}
