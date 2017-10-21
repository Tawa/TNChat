//
//  ConversationViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 17/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ChatCell: UITableViewCell {
	@IBOutlet weak var container: UIView!
	@IBOutlet weak var messageText: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	weak var message: ChatMessage? {
		didSet {
			if let message = message {
				let messageString = message.message ?? ""
				
				let now = message.timestamp.date
				let dateFormatter = DateFormatter()
				dateFormatter.dateStyle = .medium
				dateFormatter.doesRelativeDateFormatting = true
				
				let timeFormatter = DateFormatter()
				timeFormatter.timeStyle = .short
				
				var dateText = timeFormatter.string(from: now)
				if now.timeIntervalSinceNow < -24*3600 {
					dateText = dateFormatter.string(from: now) + ", " + dateText
				}
				dateLabel.text = dateText
				
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
		sendButton.isEnabled = textView.text.count > 0
		
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
	
	var contact: Contact? {
		didSet {
			if let number = contact?.number {
				conversation = ChatDataManager.shared.conversation(withFriendID: number).0
				messages.removeAll()
				if let array = conversation?.messages?.array as? [ChatMessage] {
					messages.append(contentsOf: array)
				}
			}
		}
	}
	var chatID: String? {
		if let contact = contact, let number = contact.number, let userID = CurrentUserManager.shared.userID {
			return String(forUserID: number, andUserId: userID)
		}
		return nil
	}
	var conversation: ChatConversation?
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet var inputViewContainer: InputAccessoryView!
	
	override var inputAccessoryView: UIView! {
		return inputViewContainer
	}
	override var canBecomeFirstResponder: Bool {
		return true
	}
	
	var messagesQueryReference: DatabaseQuery!
	var database: DatabaseReference?
	var messages = [ChatMessage]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)), name: Notification.Name.UIKeyboardDidChangeFrame, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if database == nil {
			if let chatID = chatID {
				database = Database.database().reference().child("chats/" + chatID + "/messages")
				if let start = conversation?.updatedTime {
					messagesQueryReference = database?.queryOrdered(byChild: "timestamp").queryStarting(atValue: start, childKey: "timestamp")
				} else {
					messagesQueryReference = database?.queryOrdered(byChild: "timestamp")
				}
				messagesQueryReference?.observe(.childAdded, with: { (data) in
					let key = (self.contact?.number ?? "")+data.key
					if let data = data.value as? [String: Any],
						let message = data["message"] as? String,
						let userID = data["userID"] as? String,
						let timestamp = data["timestamp"] as? Int {
						let (chatMessage, isNew) = ChatDataManager.shared.chatMessage(forUserID: userID, date: timestamp, message: message, key: key)
						
						if isNew {
							self.conversation?.addToMessages(chatMessage)
							self.messages.append(chatMessage)
							let indexPath = IndexPath(row: self.messages.count-1, section: 0)
							self.tableView.insertRows(at: [indexPath], with: .fade)
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
								self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
							})
							ChatDataManager.shared.saveContext()
						}
					}
				})
				database?.observe(.childChanged, with: { (data) in
					let key = (self.contact?.number ?? "")+data.key
					if let data = data.value as? [String: Any],
						let message = data["message"] as? String,
						let userID = data["userID"] as? String,
						let timestamp = data["timestamp"] as? Int {
						let (chatMessage, _) = ChatDataManager.shared.chatMessage(forUserID: userID, date: timestamp, message: message, key: key)
						let timestamp = Int64(timestamp)
						self.conversation?.updatedTime = timestamp
						chatMessage.timestamp = timestamp
						ChatDataManager.shared.saveContext()
					}
				})
			}
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		messagesQueryReference?.removeAllObservers()
		database = nil
	}
	
	@objc func keyboardDidChangeFrame(_ notification: Notification) {
		
		let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
		let oldBottom = tableView.contentInset.bottom
		
		let tableFrame = tableView.convert(tableView.bounds, to: tableView.window)
		let inputFrame = inputAccessoryView.convert(inputAccessoryView.bounds, to: inputAccessoryView.window)
		
		let bottom: CGFloat = (tableFrame.origin.y + tableFrame.height) - inputFrame.origin.y
		let oldOffset = tableView.contentOffset.y
		
		let animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut) {
			self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
			let finalHeight = self.tableView.frame.height - self.tableView.contentInset.bottom
			let contentHeight = self.tableView.contentSize.height
			let deltaHeight = contentHeight - finalHeight
			if oldBottom < bottom {
				if finalHeight < contentHeight {
					if deltaHeight < finalHeight {
						self.tableView.contentOffset = CGPoint(x: 0, y: deltaHeight)
					} else {
						self.tableView.contentOffset = CGPoint(x: 0, y: oldOffset - (oldBottom - bottom))
					}
				}
			}
		}
		animator.startAnimation()
	}
	
	@IBAction func sendAction(_ sender: Any) {
		let data: [String: Any] = ["message":inputViewContainer.textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
		                           "userID":CurrentUserManager.shared.userID!,
		                           "timestamp":ServerValue.timestamp()]
		database?.childByAutoId().setValue(data)
		
		inputViewContainer.textView.text = ""
		inputViewContainer.textViewDidChange(inputViewContainer.textView)
	}
}

extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let row = indexPath.row
		let cell: ChatCell
		let message = messages[row]
		
		if message.userID!.isCurrentUserID {
			cell = tableView.dequeueReusableCell(withIdentifier: "sentCell") as! ChatCell
		} else {
			cell = tableView.dequeueReusableCell(withIdentifier: "receivedCell") as! ChatCell
		}
		
		cell.message = message
		
		if let conversation = conversation {
			if conversation.updatedTime < message.timestamp {
				conversation.updatedTime = message.timestamp
				
				ChatDataManager.shared.saveContext()
			}
		}
		
		return cell
	}
	
	var lastIndexPath: IndexPath {
		return IndexPath(row: tableView(tableView, numberOfRowsInSection: 0)-1, section: 0)
	}
}
