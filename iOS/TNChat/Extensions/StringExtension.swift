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
	
	func left(_ to: Int) -> String {
		return "\(self[..<self.index(startIndex, offsetBy: to)])"
	}
	
	func right(_ from: Int) -> String {
		return "\(self[self.index(startIndex, offsetBy: self.count-from)...])"
	}
	
	func mid(_ from: Int, amount: Int) -> String {
		let x = "\(self[self.index(startIndex, offsetBy: from)...])"
		return x.left(amount)
	}

	var internationalizeNumber: String? {
		var number = self.components(separatedBy: String.phoneNumberSetInverted).joined()
		
		if number.hasPrefix("+") {
			return number
		}
		
		if number.count > 2 {
			if number.hasPrefix("0") {
				if number.hasPrefix("00") {
					number = "+" + number.right(number.count-2)
				} else {
					number = number.right(number.count-1)
				}
			}
		}
		
		if !number.hasPrefix("+") {
			number = CountryCodeManager.current + number
		}
		
		return number
	}
}
