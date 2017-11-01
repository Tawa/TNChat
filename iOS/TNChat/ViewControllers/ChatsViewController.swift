//
//  ChatsViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import CoreData

class ChatsViewController: UITableViewController {
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(openChat(_:)), name: NotificationName.openChat.notification, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(getContacts), name: NotificationName.signedIn.notification, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(resetFetchedController), name: NotificationName.signedOut.notification, object: nil)
    }
	
	@objc func getContacts() {
		ContactsManager.shared.syncContacts { (_) in
			self.tableView.reloadData()
		}
	}
	
	@objc func openChat(_ notification: Notification) {
		if let contact = notification.object as? Contact {
			if let presented = presentedViewController {
				presented.dismiss(animated: false)
			}
			if ConversationsManager.shared.currentfriendID == contact.number {
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
		return fetchedResultsController?.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sectionInfo = fetchedResultsController!.sections![section]
		return sectionInfo.numberOfObjects
    }
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "conversationCell") as! ConversationCell
		
		cell.conversation = fetchedResultsController!.object(at: indexPath)
		
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
						let friendID = fetchedResultsController?.object(at: indexPath).friendID {
						let contact = ContactsManager.shared.getContact(withPhoneNumber: friendID)
						vc.contact = contact
					}
				}
			default:
				break
			}
		}
	}
	
	private var _fetchedResultsController: NSFetchedResultsController<ChatConversation>? = nil
	var fetchedResultsController: NSFetchedResultsController<ChatConversation>? {
		if _fetchedResultsController != nil {
			return _fetchedResultsController!
		}
		
		guard let userID = CurrentUserManager.shared.userID else { return nil }
		
		let fetchRequest: NSFetchRequest<ChatConversation> = ChatConversation.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "userID == %@", userID)

		let sortDescriptor = NSSortDescriptor(key: "conversationTime", ascending: false)
		
		fetchRequest.sortDescriptors = [sortDescriptor]
		
		let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ChatDataManager.shared.context, sectionNameKeyPath: nil, cacheName: "Conversations")
		aFetchedResultsController.delegate = self
		_fetchedResultsController = aFetchedResultsController
		
		do {
			try _fetchedResultsController!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
		
		return _fetchedResultsController!
	}
	@objc func resetFetchedController() {
		_fetchedResultsController = nil
		tableView.reloadData()
	}
}

extension ChatsViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		switch type {
		case .insert:
			tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
		case .delete:
			tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
		default:
			break
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: .fade)
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: .fade)
		case .update:
			tableView.reloadRows(at: [indexPath!], with: .fade)
		case .move:
			if let cell = tableView.cellForRow(at: indexPath!) as? ConversationCell,
				let conversation = anObject as? ChatConversation {
				cell.conversation = conversation
			}
			tableView.moveRow(at: indexPath!, to: newIndexPath!)
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}
}
