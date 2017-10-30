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
	
	@IBOutlet weak var scrollDownButton: UIButton!
	@IBOutlet weak var scrollDownBottomConstraint: NSLayoutConstraint!
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
	var newMessagesSeparator: NewMessagesSeparator?
	var newMessagesTimestamp: Int64 = 0
	
	var datePanValue: CGFloat = 0

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
		
		if conversation.cacheTime > conversation.updatedTime {
			tableView.register(UINib(nibName: "NewMessagesCell", bundle: Bundle.main), forCellReuseIdentifier: "newMessagesCell")
			
			newMessagesTimestamp = conversation.updatedTime
			newMessagesSeparator = NewMessagesSeparator(conversation.updatedTime, ChatDataManager.shared.newMessagesCount(forConversation: conversation))
			let _ = messages.add(message: newMessagesSeparator!)
		}
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
			tableView.scrollToRow(at: lastIndexPath, at: .none, animated: false)
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
		self.scrollDownBottomConstraint.constant = bottom + 8
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
		if let _ = newMessagesSeparator {
			for day in messages.days {
				if let row = day.messages.index(where: { (data) -> Bool in
					return data is NewMessagesSeparator
				}) {
					let section = messages.days.index(of: day)!
					day.messages.remove(at: row)
					tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: .fade)
				}
			}
		}
		
		ConversationsManager.shared.send(message: inputViewContainer.textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
		inputViewContainer.textView.text = ""
		inputViewContainer.textViewDidChange(inputViewContainer.textView)
	}
	
	@IBAction func scrollDownAction(_ sender: Any) {
		if let lastIndexPath = lastIndexPath {
			tableView.scrollToRow(at: lastIndexPath, at: .top, animated: true)
		}
	}
	
	@IBAction func chatPan(_ sender: UIPanGestureRecognizer) {
		
		switch sender.state {
		case .changed:
			let translation = -sender.translation(in: tableView).x
			datePanValue = min(48, max(0, translation))
			panCells(datePanValue)
		default:
			datePanValue = 0
			panCells(0)
		}
	}
	
	func panCells(_ x: CGFloat) {
		if x > 0 {
			for cell in tableView.visibleCells {
				if let cell = cell as? ChatCell {
					cell.chatCellPan(to: x)
				}
			}
		} else {
			for cell in tableView.visibleCells {
				if let cell = cell as? ChatCell {
					cell.chatCellPanReset()
				}
			}
		}
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
				self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
			})
		} else {
		}
		
		if let newMessagesSeparator = newMessagesSeparator {
			newMessagesSeparator.count = ChatDataManager.shared.newMessagesCount(forConversation: conversation, afterTimestamp: newMessagesTimestamp)
			for day in messages.days {
				if let row = day.messages.index(where: { (data) -> Bool in
					return data is NewMessagesSeparator
				}) {
					let section = messages.days.index(of: day)!
					tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .none)
				}
			}
		}
	}
	
	func conversationObserver(updatedMessage message: ChatMessage) {
		if conversation.updatedTime < message.timestamp {
			conversation.updatedTime = message.timestamp

			ChatDataManager.shared.saveContext()
		}
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
		let data = messages.message(forIndexPath: indexPath)
		if let message = data as? ChatMessage {
			let cell: ChatCell
			
			if message.userID!.isCurrentUserID {
				cell = tableView.dequeueReusableCell(withIdentifier: "sentCell") as! ChatCell
			} else {
				cell = tableView.dequeueReusableCell(withIdentifier: "receivedCell") as! ChatCell
			}
			
			cell.message = message
			
			cell.chatCellPan(to: datePanValue)
			
			return cell
		} else if let data = data as? NewMessagesSeparator {
			let count = data.count
			
			let cell = tableView.dequeueReusableCell(withIdentifier: "newMessagesCell") as! NewMessagesCell
			
			cell.label.text = "\(count) New Messages"
			
			return cell
		}
		
		return UITableViewCell()
	}
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath == lastIndexPath && !scrollDownButton.isHidden {
			UIView.animate(withDuration: 0.1, animations: {
				self.scrollDownButton.alpha = 0
			}, completion: { (_) in
				self.scrollDownButton.isHidden = true
			})
		}

		let message = messages.message(forIndexPath: indexPath)
		
		if conversation.updatedTime < message.timestamp {
			conversation.updatedTime = message.timestamp
			
			ConversationsManager.shared.refreshApplicationBadgeCount()
			
			ChatDataManager.shared.saveContext()
		}
	}
	
	func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath == lastIndexPath && scrollDownButton.isHidden {
			scrollDownBottomConstraint.constant = tableView.contentInset.bottom + 8
			scrollDownButton.isHidden = false
			scrollDownButton.alpha = 0
			UIView.animate(withDuration: 0.3, animations: {
				self.scrollDownButton.alpha = 1
			})
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

extension ConversationViewController: UIGestureRecognizerDelegate {
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if let pan = gestureRecognizer as? UIPanGestureRecognizer {
			let translation = pan.translation(in: tableView)
			return abs(translation.x) > abs(translation.y)
		}
		return true
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}
