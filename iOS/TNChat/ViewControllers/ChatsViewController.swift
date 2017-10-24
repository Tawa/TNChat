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
		
		
		
		ConversationsManager.shared.delegate = self
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		ConversationsManager.shared.reloadData()
		tableView.reloadData()
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
		if segue.identifier == SegueIdentifiers.showContactsList {
			if  let nav = segue.destination as? UINavigationController,
				let vc = nav.viewControllers.first as? ContactsViewController {
				vc.completion = { contact in
					self.performSegue(withIdentifier: SegueIdentifiers.showConversation, sender: contact)
				}
			}
		} else if segue.identifier == SegueIdentifiers.showConversation {
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
		}
	}
}

extension ChatsViewController: ConversationsManagerDelegate {
	func updatedConversation(forUserId userID: String) {
		tableView.reloadData()
	}
	
	func addedConversation(forUserId userID: String) {
		tableView.reloadData()
	}
}
