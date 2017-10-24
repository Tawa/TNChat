//
//  ChatCell.swift
//  TNChat
//
//  Created by Tawa Nicolas on 24/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

class ChatCell: UITableViewCell {
	@IBOutlet weak var container: UIView!
	@IBOutlet weak var messageText: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	weak var message: ChatMessage? {
		didSet {
			if let message = message {
				let messageString = message.message ?? ""
				
				let now = message.date
				let dateFormatter = DateFormatter()
				dateFormatter.dateStyle = .medium
				dateFormatter.doesRelativeDateFormatting = true
				
				let timeFormatter = DateFormatter()
				timeFormatter.timeStyle = .short
				dateLabel.text = timeFormatter.string(from: now)
				
				messageText.text = messageString
			}
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		container.layer.cornerRadius = 8
		messageText.layer.masksToBounds = false
	}
}
