//
//  DateExtension.swift
//  TNChat
//
//  Created by Tawa Nicolas on 21/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import Foundation

extension Int64 {
	// This helps convert Firebase's timestamps to Date objects
	var date: Date {
		return Date(timeIntervalSince1970: Double(self) * 0.001)
	}
}

extension ChatMessage {
	var date: Date {
		return timestamp.date
	}
}
