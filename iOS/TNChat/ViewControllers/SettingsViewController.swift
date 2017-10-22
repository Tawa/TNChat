//
//  SettingsViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let alert = UIAlertController(title: "Warning", message: "Are you sure you want to sign out?", preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { (_) in
			do {
				try Auth.auth().signOut()
				NotificationCenter.default.post(name: NotificationName.signedOut.notification, object: nil)
				CurrentUserManager.shared.userID = nil
				self.tabBarController?.performSegue(withIdentifier: SegueIdentifiers.showLogin, sender: self)
			} catch {
				let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
				self.present(alert, animated: true)
			}
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
}
