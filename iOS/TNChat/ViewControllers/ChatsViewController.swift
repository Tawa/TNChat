//
//  ChatsViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

class ChatsViewController: UITableViewController {
	
	var conversations: [ChatConversation] {
		return ConversationsManager.shared.conversations
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(openChat(_:)), name: NotificationName.openChat.notification, object: nil)
		
		ConversationsManager.shared.delegate = self
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		ConversationsManager.shared.reloadData()
		tableView.reloadData()
	}
	
	@objc func openChat(_ notification: Notification) {
		if let contact = notification.object as? Contact {
			if let presented = presentedViewController {
				presented.dismiss(animated: false)
			}
			if ConversationsManager.shared.currentChatID == contact.number {
				return
			}
			if navigationController!.viewControllers.count > 1 {
				navigationController!.popToRootViewController(animated: false)
			}
			performSegue(withIdentifier: SegueIdentifiers.showConversationNoAnimations, sender: contact)
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return conversations.count
    }
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let row = indexPath.row
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "conversationCell") as! ConversationCell
		
		cell.conversation = conversations[row]
		
		return cell
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let identifier = segue.identifier {
			switch identifier {
			case SegueIdentifiers.showContactsList:
				if  let nav = segue.destination as? UINavigationController,
					let vc = nav.viewControllers.first as? ContactsViewController {
					vc.completion = { contact in
						self.performSegue(withIdentifier: SegueIdentifiers.showConversation, sender: contact)
					}
				}
			case SegueIdentifiers.showConversation, SegueIdentifiers.showConversationNoAnimations:
				if let vc = segue.destination as? ConversationViewController {
					if let contact = sender as? Contact {
						vc.contact = contact
					} else if let cell = sender as? UITableViewCell,
						let indexPath = tableView.indexPath(for: cell),
						let friendID = conversations[indexPath.row].friendID {
						let contact = ContactsManager.shared.getContact(withPhoneNumber: friendID)
						vc.contact = contact
					}
				}
			default:
				break
			}
		}
	}
}

extension ChatsViewController: ConversationsManagerDelegate {
	func conversationsManager(addedForUserId userID: String) {
		let firstRow = IndexPath(row: 0, section: 0)
		tableView.insertRows(at: [firstRow], with: .top)
	}
	func conversationsManager(updatedForUserId userID: String, oldIndex index: Int) {
		let firstRow = IndexPath(row: 0, section: 0)
		let row = IndexPath(row: index, section: 0)
		tableView.moveRow(at: row, to: firstRow)
		tableView.reloadRows(at: [firstRow], with: .none)
	}
}
