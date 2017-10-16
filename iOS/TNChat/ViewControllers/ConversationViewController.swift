//
//  ConversationViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 17/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

class ConversationViewController: UIInputViewController {

	@IBOutlet weak var inputViewContainer: UIView!
	var contact: Contact?
	
	override var inputAccessoryView: UIView? {
		get {
			return inputViewContainer
		}
	}
	
	override var canBecomeFirstResponder: Bool {
		return true
	}
	
}
