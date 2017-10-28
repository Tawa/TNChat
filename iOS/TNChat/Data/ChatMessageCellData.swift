//
//  ChatMessageCellData.swift
//  TNChat
//
//  Created by Tawa Nicolas on 28/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

enum ChatMessageCellType {
	case message
	case newMessages
}

protocol ChatMessageCellData {
	var type: ChatMessageCellType { get }
}

extension ChatMessage: ChatMessageCellData {
	var type: ChatMessageCellType {
		return .message
	}
}

class NewMessagesSeparator: ChatMessageCellData {
	var type: ChatMessageCellType {
		return .newMessages
	}
}
