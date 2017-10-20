//
//  ConversationViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 17/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

class InputAccessoryView: UIView {
	
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var sendButton: UIButton!
	@IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		autoresizingMask = .flexibleHeight
		
		textViewDidChange(textView)
	}
	
	override var intrinsicContentSize: CGSize {
		return CGSize(width: UIViewNoIntrinsicMetric, height: 100)
	}
}

extension InputAccessoryView: UITextViewDelegate, UIScrollViewDelegate {
	func textViewDidChange(_ textView: UITextView) {
		let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: 100))
		let constraintHeight = min(100, max(32, ceil(size.height)))
		if constraintHeight != textViewHeightConstraint.constant {
			invalidateIntrinsicContentSize()
			textViewHeightConstraint.constant = constraintHeight
		}
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if scrollView.frame.size.height >= scrollView.contentSize.height {
			scrollView.contentOffset = CGPoint.zero
		}
	}
}

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
	@IBAction func sendAction(_ sender: Any) {
	}
	
}
