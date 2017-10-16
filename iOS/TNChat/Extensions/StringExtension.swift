//
//  StringExtension.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import Foundation

extension String {
	static let phoneNumberSetInverted: CharacterSet = {
		return CharacterSet(charactersIn: "+0123456789").inverted
	}()
	
	var internationalizeNumber: String? {
		var number = self.components(separatedBy: String.phoneNumberSetInverted).joined()
		
		if number.hasPrefix("+") {
			return String(number.dropFirst())
		}
		
		if number.count > 2 {
			if number.hasPrefix("0") {
				if number.hasPrefix("00") {
					number = "+" + String(number.dropFirst(2))
				} else {
					number = String(number.dropFirst())
				}
			}
		}
		
		if !number.hasPrefix("+") {
			number = CountryCodeManager.current + number
		}
		
		return String(number.dropFirst())
	}
}
