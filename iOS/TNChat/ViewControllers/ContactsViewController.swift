//
//  ContactsViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

class ContactsViewController: UITableViewController {
	
	var contacts = [Contact]()
	
	@IBAction func dismiss(_ sender: Any) {
		navigationController?.dismiss(animated: true)
	}

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
		
		ContactsManager.shared.loadContacts { (success) in
			if success {
				print("Success")
				ContactsManager.shared.fetchContactsOnline({ (success) in
					if success {
						for contact in ContactsManager.shared.onlineContacts {
							print("Found: \(contact.name ?? "")")
						}
						self.contacts.append(contentsOf: ContactsManager.shared.onlineContacts)
						self.tableView.reloadData()
					} else {
						print("Done fetching")
					}
				})
			} else {
				print("Failed")
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
}
