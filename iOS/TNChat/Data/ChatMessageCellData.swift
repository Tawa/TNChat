//
//  ChatMessageCellData.swift
//  TNChat
//
//  Created by Tawa Nicolas on 28/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

// UITableViewCell data types
enum ChatMessageCellType {
	case message			// Message cell
	case newMessages		// New Messages separator.
}

protocol ChatMessageCellData {
	var type: ChatMessageCellType { get }
	var timestamp: Int64 { get set }
}

extension ChatMessage: ChatMessageCellData {
	var type: ChatMessageCellType {
		return .message
	}
}

class NewMessagesSeparator: ChatMessageCellData {
	var timestamp: Int64
	var count: Int
	
	var type: ChatMessageCellType {
		return .newMessages
	}
	
	init(_ timestamp: Int64, _ count: Int) {
		self.timestamp = timestamp
		self.count = count
	}
}
