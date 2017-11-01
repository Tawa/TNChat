//
//  SettingsViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseAuth
import UserNotifications

class SettingsViewController: UITableViewController {
	let notificationsIndexPath = IndexPath(row: 0, section: 0)
	let signOutIndexPath = IndexPath(row: 0, section: 1)
	
	let notificationsSwitch = UISwitch()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		notificationsSwitch.addTarget(self, action: #selector(toggleNotifications(_:)), for: .valueChanged)
		
		UNUserNotificationCenter.current().getNotificationSettings { result in
			DispatchQueue.main.sync {
				switch result.authorizationStatus {
				case .authorized:
					self.notificationsSwitch.isOn = true
				default:
					self.notificationsSwitch.isOn = false
				}
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = super.tableView(tableView, cellForRowAt: indexPath)
		
		if indexPath == notificationsIndexPath {
			cell.accessoryView = notificationsSwitch
		} else {
			cell.accessoryView = nil
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath == notificationsIndexPath {
			notificationsSwitch.isOn = !notificationsSwitch.isOn
			toggleNotifications(notificationsSwitch)
		} else if indexPath == signOutIndexPath {
			let alert = UIAlertController(title: "Warning", message: "Are you sure you want to sign out?", preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { (_) in
				do {
					try Auth.auth().signOut()
					CurrentUserManager.shared.userID = nil
					NotificationCenter.default.post(name: NotificationName.signedOut.notification, object: nil)
					self.tabBarController?.performSegue(withIdentifier: SegueIdentifiers.showLogin, sender: self)
				} catch {
					let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
					self.present(alert, animated: true)
				}
			}))
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			present(alert, animated: true)
			
		}
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	@objc func toggleNotifications(_ sender: UISwitch) {
		AppDelegate.current.isNotificationsOn = sender.isOn
		
		if sender.isOn {
			UNUserNotificationCenter.current().getNotificationSettings { result in
				switch result.authorizationStatus {
				case .denied:
					DispatchQueue.main.sync {
						let alert = UIAlertController(title: "Warning", message: "Notifications are denied for TNChat! Please enable them from the settings.", preferredStyle: .actionSheet)
						alert.addAction(UIAlertAction(title: "Enable", style: .default, handler: { (_) in
							UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
						}))
						alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
						self.present(alert, animated: true)
					}
				default:
					break
				}
			}
		}
	}
}
