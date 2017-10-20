//
//  ChatsViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

class ChatsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
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
			if let vc = segue.destination as? ConversationViewController, let contact = sender as? Contact {
				vc.contact = contact
			}
		}
	}
	
}
