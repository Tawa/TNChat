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

// This class manages user's contacts.
// It asks for the permissions, fetches the contacts list, and checks which ones are signed up to the application.
// ContactsManager uses CoreData to cache contacts.
class ContactsManager {
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
			try? context.save()
		}
	}
	
	let store = CNContactStore()

	// This function fetches the contact object with the current phone number, in case it doesn't exist, it creates a new one.
	func getContact(withPhoneNumber number: String) -> Contact {
		let context = self.context
		
		let request: NSFetchRequest<Contact> = Contact.fetchRequest()
		request.predicate = NSPredicate(format: "number == %@", number)
		var contact: Contact?
		if let existingContact: Contact? = try? context.fetch(request).first {
			contact = existingContact
		} else {
			contact = Contact(context: context)
			contact?.number = number
		}
		
		return contact!
	}
	
	// This function gets the cached contacts who are signed up to the app on Firebase.
	func getOnlineContacts() -> [Contact] {
		let context = self.context
		
		let request: NSFetchRequest<Contact> = Contact.fetchRequest()
		let isUserPredicate = NSPredicate(format: "isUser == true")
		let numberPredicate = NSPredicate(format: "number != %@", CurrentUserManager.shared.userID ?? "")
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [isUserPredicate, numberPredicate])
		if let results: [Contact] = try? context.fetch(request) {
			return results
		}
		
		return []
		
	}
	
	// This method asks for contacts permission, and fetches them.
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
	
	// This contacts loops over all the contacts and checks which ones are signed up to the application in Firebase.
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
	
	// This function does all the necessary code to fetch the contacts from the phone's directory, and check which ones are signed up to the application in Firebase.
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
