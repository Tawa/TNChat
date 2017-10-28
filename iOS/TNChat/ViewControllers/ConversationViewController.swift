//
//  ConversationViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 17/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

protocol InputAccessoryViewDelegate: NSObjectProtocol {
	func inputAccessoryView(textDidChange text: String)
}

class InputAccessoryView: UIView {
	
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var sendButton: UIButton!
	@IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
	
	weak var delegate: InputAccessoryViewDelegate?
	
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
		sendButton.isEnabled = textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count > 0
		
		let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: 100))
		let constraintHeight = min(100, max(32, ceil(size.height)))
		if constraintHeight != textViewHeightConstraint.constant {
			invalidateIntrinsicContentSize()
			textViewHeightConstraint.constant = constraintHeight
		}
		
		delegate?.inputAccessoryView(textDidChange: textView.text)
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if scrollView.frame.size.height >= scrollView.contentSize.height {
			scrollView.contentOffset = CGPoint.zero
		}
	}
}

class ConversationViewController: UIViewController {
	
	var contact: Contact! {
		didSet {
			if let number = contact.number {
				conversation = ChatDataManager.shared.conversation(withFriendID: number).0
				let chatMessages = ChatDataManager.shared.chatMessages(forConversationWithFriendID: number)
				messages.clear()
				for message in chatMessages {
					let _ = messages.add(message: message)
				}
			}
		}
	}
	
	var userID: String? {
		return CurrentUserManager.shared.userID
	}
	
	var conversation: ChatConversation!
	
	var didScrollToEnd = false
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet var inputViewContainer: InputAccessoryView!
	
	override var inputAccessoryView: UIView! {
		return inputViewContainer
	}
	override var canBecomeFirstResponder: Bool {
		return true
	}
	
	var messages = ConversationContainer()
	let refresh = UIRefreshControl()
	var contactView: ConversationContactView!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		inputViewContainer.delegate = self
		
		contactView = Bundle.main.loadNibNamed("ConversationContactView", owner: self, options: nil)!.first as! ConversationContactView
		contactView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44)
		contactView.contact = contact
		navigationItem.titleView = contactView
		
		navigationItem.backBarButtonItem?.title = ""
		
		tableView.register(UINib(nibName: "ChatDayHeader", bundle: Bundle.main), forHeaderFooterViewReuseIdentifier: "header")
		tableView.sectionHeaderHeight = 30
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)), name: Notification.Name.UIKeyboardDidChangeFrame, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(removeObservers), name: Notification.Name.UIApplicationWillResignActive, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(addObservers), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
		
		refresh.addTarget(self, action: #selector(loadMore), for: .valueChanged)
		tableView.addSubview(refresh)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func loadMore() {
		if let first = messages.first {
			DispatchQueue.global(qos: .background).async {
				let chatMessages = ChatDataManager.shared.chatMessages(forConversationWithFriendID: self.friendID, beforeTimestamp: first.timestamp)
				
				DispatchQueue.main.async {
					for message in chatMessages {
						let (indexPath, isNewSection) = self.messages.add(message: message)
						if isNewSection {
							self.tableView.insertSections([indexPath.section], with: .fade)
						} else {
							self.tableView.insertRows(at: [indexPath], with: .fade)
						}
					}
					self.refresh.endRefreshing()
				}
			}
		} else {
			refresh.endRefreshing()
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if !didScrollToEnd, let lastIndexPath = lastIndexPath {
			didScrollToEnd = true
			tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: inputViewContainer.frame.height, right: 0)
			tableView.scrollIndicatorInsets = tableView.contentInset
			tableView.scrollToRow(at: lastIndexPath, at: .top, animated: false)
		}
	}
	
	@objc func addObservers() {
		ConversationsManager.shared.conversationObserver = self
	}
	
	@objc func removeObservers() {
		ConversationsManager.shared.conversationObserver = nil
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		addObservers()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		removeObservers()
	}
	
	@objc func keyboardDidChangeFrame(_ notification: Notification) {
		
		let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
		let oldBottom = tableView.contentInset.bottom
		
		let tableFrame = tableView.convert(tableView.bounds, to: tableView.window)
		let inputFrame = inputAccessoryView.convert(inputAccessoryView.bounds, to: inputAccessoryView.window)
		
		let bottom: CGFloat = max(0, (tableFrame.origin.y + tableFrame.height) - inputFrame.origin.y)
		
		guard oldBottom != bottom, bottom < tableView.frame.height else { return }
		
		let oldOffset = tableView.contentOffset.y
		
		tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
		tableView.scrollIndicatorInsets = tableView.contentInset
		let finalHeight = tableView.frame.height - tableView.contentInset.bottom
		let contentHeight = tableView.contentSize.height
		let deltaHeight = contentHeight - finalHeight
		var contentOffset: CGFloat? = nil
		if oldBottom < bottom {
			if finalHeight < contentHeight {
				if deltaHeight < finalHeight {
					contentOffset = deltaHeight
				} else {
					contentOffset = oldOffset - (oldBottom - bottom)
				}
			}
		}
		if let contentOffset = contentOffset, tableView.contentOffset.y != contentOffset {
			let animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut) {
				self.tableView.contentOffset = CGPoint(x: 0, y: contentOffset)
			}
			animator.startAnimation()
		}
	}
	
	@IBAction func sendAction(_ sender: Any) {
		ConversationsManager.shared.send(message: inputViewContainer.textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
		inputViewContainer.textView.text = ""
		inputViewContainer.textViewDidChange(inputViewContainer.textView)
	}
}

extension ConversationViewController: ConversationObserverDelegate {
	var friendID: String {
		get {
			return contact.number!
		}
	}
	
	var currentConversation: ChatConversation {
		get {
			return conversation
		}
	}
	
	func conversationObserver(addedNewMessage message: ChatMessage) {
		var shouldScroll = false
		
		if let indexPath = self.tableView.indexPathForRow(at: CGPoint(x: UIScreen.main.bounds.width * 0.5, y: self.tableView.frame.height - self.tableView.contentInset.bottom + self.tableView.contentOffset.y - 1)),
			let lastIndexPath = self.lastIndexPath,
			lastIndexPath == indexPath {
			shouldScroll = true
		}
		
		self.conversation?.addToMessages(message)
		let (indexPath, isNewSection) = self.messages.add(message: message)
		if isNewSection {
			self.tableView.insertSections([indexPath.section], with: .fade)
		} else {
			self.tableView.insertRows(at: [indexPath], with: .fade)
		}
		if shouldScroll {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
				self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
			})
		} else {
			print("Received Message")
		}
	}
	
	func conversationObserver(updatedMessage message: ChatMessage) {
		
	}
	
	func conversationObserver(friendIsOnline online: Bool, isTyping typing: Bool) {
		if typing {
			contactView.statusLabel.text = "Typing"
		} else if online {
			contactView.statusLabel.text = "Online"
		} else {
			contactView.statusLabel.text = ""
		}
	}
}

extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return messages.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages.count(forDay: section)
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.doesRelativeDateFormatting = true
		
		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as! ChatDayHeader
		
		header.label.text = formatter.string(from: messages.days[section].date)
		
		return header
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: ChatCell
		let message = messages.message(forIndexPath: indexPath)
		
		if message.userID!.isCurrentUserID {
			cell = tableView.dequeueReusableCell(withIdentifier: "sentCell") as! ChatCell
		} else {
			cell = tableView.dequeueReusableCell(withIdentifier: "receivedCell") as! ChatCell
		}
		
		cell.message = message
		
		return cell
	}
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let message = messages.message(forIndexPath: indexPath)
		
		if conversation.updatedTime < message.timestamp {
			conversation.updatedTime = message.timestamp
			
			ChatDataManager.shared.saveContext()
		}
	}
	
	var lastIndexPath: IndexPath? {
		let section = numberOfSections(in: tableView)-1
		if section >= 0 {
			let row = tableView(tableView, numberOfRowsInSection: section)-1
			if row >= 0 {
				return IndexPath(row: row, section: section)
			}
		}
		return nil
	}
}

extension ConversationViewController: InputAccessoryViewDelegate {
	func inputAccessoryView(textDidChange text: String) {
		ConversationsManager.shared.isTyping = text.count > 0
	}
}
