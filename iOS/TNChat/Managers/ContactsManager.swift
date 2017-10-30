//
//  ContactsManager.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import CoreData
import Contacts
import FirebaseDatabase

class ContactsManager: NSObject {
	static let shared = ContactsManager()
	var contacts = [Contact]()
	var onlineContacts = [Contact]()
	
	var syncing = false
	
	lazy var container: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "ContactsDataModel")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error {
				fatalError("Unresolved error \(error), \(error.localizedDescription)")
			}
		})
		return container
	}()
	
	lazy var context: NSManagedObjectContext = {
		return container.viewContext
	}()
	
	func saveContext() {
		let context = container.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
			}
		} else {
		}
	}
	
	let store = CNContactStore()

	func getContact(withPhoneNumber number: String) -> Contact {
		let context = self.context
		
		let request: NSFetchRequest<Contact> = Contact.fetchRequest()
		request.predicate = NSPredicate(format: "number == %@", number)
		var contact: Contact?
		do {
			let results = try context.fetch(request)
			contact = results.first
		} catch {
		}
		
		if contact == nil {
			contact = Contact(context: context)
			contact?.number = number
		}
		
		return contact!
	}
	
	func getOnlineContacts() -> [Contact] {
		let context = self.context
		
		let request: NSFetchRequest<Contact> = Contact.fetchRequest()
		let isUserPredicate = NSPredicate(format: "isUser == true")
		let numberPredicate = NSPredicate(format: "number != %@", CurrentUserManager.shared.userID ?? "")
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [isUserPredicate, numberPredicate])
		do {
			let results = try context.fetch(request)
			return results
		} catch {
			
		}
		
		return []
		
	}
	
	func loadContacts(_ completion: @escaping (_ success: Bool) -> Void) {
		store.requestAccess(for: .contacts) { (success, error) in
			if success {
				let request = CNContactFetchRequest(keysToFetch:
					[CNContactPhoneNumbersKey as NSString,
					 CNContactFormatter.descriptorForRequiredKeys(for: .fullName)])
				do {
					self.contacts.removeAll()
					try self.store.enumerateContacts(with: request, usingBlock: { (contact, stop) in
						for phone in contact.phoneNumbers {
							if let phoneNumber = phone.value.stringValue.internationalizeNumber {
								let newContact = self.getContact(withPhoneNumber: phoneNumber)
								let name = (contact.givenName + " " + contact.familyName).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
								if newContact.name != name {
									newContact.name = name
								}
								self.contacts.append(newContact)
							}
						}
					})
					completion(true)
				} catch {
					completion(false)
				}
			}
		}
	}
	
	func fetchContactsOnline(_ completion: @escaping(_ success: Bool) -> Void) {
		var found = [String: Contact]()
		var notFound = [String: Contact]()
		var unprocessed = [String: Contact]()
		
		let currentUserId = CurrentUserManager.shared.userID ?? ""
		
		for contact in contacts {
			guard contact.number != nil, contact.name != nil else { continue }
			let number = contact.number!
			unprocessed[number] = contact
			Database.database().reference().child("users/"+number).observeSingleEvent(of: .value, with: { (snapshot) in
				if snapshot.exists() {
					if number != currentUserId {
						found[number] = contact
						contact.isUser = true
					}
				} else {
					notFound[number] = contact
					contact.isUser = false
				}
				unprocessed.removeValue(forKey: number)
				if unprocessed.count == 0 {
					self.onlineContacts.removeAll()
					self.onlineContacts.append(contentsOf: Array(found.values).filter { $0.number != currentUserId })
					completion(true)
				}
			})
		}
	}
	
	func syncContacts(_ completion: @escaping(_ success: Bool) -> Void) {
		if syncing {
			return
		}
		syncing = true
		ContactsManager.shared.loadContacts { (success) in
			if success {
				ContactsManager.shared.fetchContactsOnline({ (success) in
					self.syncing = false
					completion(success)
				})
			} else {
				self.syncing = false
				completion(false)
			}
		}

	}
}
