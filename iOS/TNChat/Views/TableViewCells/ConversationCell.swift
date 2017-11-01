//
//  ConversationCell.swift
//  TNChat
//
//  Created by Tawa Nicolas on 24/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

extension ChatConversation {
	var newMessagesCount: Int {
		return ChatDataManager.shared.newMessagesCount(forConversation: self)
	}
}

class ConversationCell: UITableViewCell {
	@IBOutlet weak var pictureView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var lastMessageLabel: UILabel!
	@IBOutlet weak var indicator: UILabel!
	
	weak var conversation: ChatConversation? {
		didSet {
			if let conversation = conversation, let friendID = conversation.friendID {
				let contact = ContactsManager.shared.getContact(withPhoneNumber: friendID)
				nameLabel.text = contact.name ?? ("+"+contact.number!)
				lastMessageLabel.text = conversation.message
				let date = conversation.conversationTime.date
				let formatter = DateFormatter()
				formatter.dateStyle = .short
				formatter.timeStyle = .short
				formatter.doesRelativeDateFormatting = true
				dateLabel.text = formatter.string(from: date)
				
				let count = conversation.newMessagesCount
				indicator.isHidden = count == 0
				if count > 0 {
					indicator.text = "\(count)"
				}
			}
		}
	}
}
