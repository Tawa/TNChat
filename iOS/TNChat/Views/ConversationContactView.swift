//
//  ConversationContactView.swift
//  TNChat
//
//  Created by Tawa Nicolas on 22/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

// This view is what displays in the UINavigationItem for the conversations.
class ConversationContactView: UIView {

	@IBOutlet weak var pictureView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var statusLabel: UILabel!

	weak var contact: Contact? {
		didSet {
			if let contact = contact {
				nameLabel.text = contact.name ?? (contact.number ?? "User")
			}
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		statusLabel.text = "Loading"
		pictureView.layer.masksToBounds = true
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		pictureView.layer.cornerRadius = pictureView.frame.width * 0.5
	}
}
