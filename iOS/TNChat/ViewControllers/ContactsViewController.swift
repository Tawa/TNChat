//
//  ContactsViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

// This view controller lets the user start new conversations with friends who have already signed up to the app.
class ContactsViewController: UITableViewController {
	
	var contacts = ContactsManager.shared.getOnlineContacts()
	var completion: ((Contact) -> Void)?
	var isReloading = false
	
	@IBAction func dismiss(_ sender: Any) {
		navigationController?.dismiss(animated: true)
	}

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	@IBAction func reloadAction(_ sender: Any) {
		if isReloading {
			return
		}
		isReloading = true
		ContactsManager.shared.syncContacts { [weak self] (success) in
			self?.isReloading = false
			if success {
				self?.contacts.removeAll()
				self?.contacts.append(contentsOf: ContactsManager.shared.onlineContacts)
				self?.tableView.reloadData()
			} else {
			}
		}
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
		
		cell.textLabel?.text = contacts[indexPath.row].name
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		dismiss(animated: true) {
			self.completion?(self.contacts[indexPath.row])
		}
	}
}
