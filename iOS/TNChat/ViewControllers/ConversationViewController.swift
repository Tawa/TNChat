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
		
		textView.delegate = self
		
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

class ConversationViewController: UIViewController {
	
	var contact: Contact?
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet var inputViewContainer: InputAccessoryView!
	
	override var inputAccessoryView: UIView! {
		return inputViewContainer
	}
	override var canBecomeFirstResponder: Bool {
		return true
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
	}
	
	@objc func keyboardDidChangeFrame(_ notification: Notification) {
		
		let frame = inputAccessoryView.convert(inputAccessoryView.frame, to: tableView)
		let bottom = tableView.frame.height - frame.origin.y
		tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
	}
	
	@IBAction func sendAction(_ sender: Any) {
	}
}
