//
//  ContactsManager.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import CoreData

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
}
