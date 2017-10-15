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

class ContactsManager: NSObject {
	static let shared = ContactsManager()
	
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
				fatalError("Unresolved error \(error), \(error.localizedDescription)")
			}
		}
	}
	
	let store = CNContactStore()

	func getContact(withPhoneNumber number: String) -> Contact {
		let context = self.context
		
		let request: NSFetchRequest<Contact> = Contact.fetchRequest()
		request.predicate = NSPredicate(format: "number == %@", number)
		var contact: Contact?
		do {
			contact = try context.fetch(request).first
		} catch {
			contact = Contact(context: context)
			contact?.number = number
		}
		
		return contact!
	}
	
	func loadContacts(_ completion: @escaping (_ success: Bool) -> Void) {
		store.requestAccess(for: .contacts) { (success, error) in
			if success {
				let request = CNContactFetchRequest(keysToFetch: [CNContactPhoneNumbersKey as NSString, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)])
				do {
					try self.store.enumerateContacts(with: request, usingBlock: { (contact, stop) in
						for phone in contact.phoneNumbers {
							if let phoneNumber = phone.value.stringValue.internationalizeNumber {
								print("\(contact.givenName) \(contact.familyName) : \(phone.value.stringValue) : \(phoneNumber)")
							}
//							let newContact = self.getContact(withPhoneNumber: phone.value.stringValue)
						}
					})
//					self.saveContext()
					completion(true)
				} catch {
					completion(false)
				}
			}
		}
	}
}
