//
//  StringExtension.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import Foundation
import CoreText

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
	
	var isCurrentUserID: Bool {
		return self == CurrentUserManager.shared.userID
	}
	
	init(forUserID userID1: String, andUserId userID2: String) {
		if userID1 > userID2 {
			self = userID1 + "&" + userID2
		} else {
			self = userID2 + "&" + userID1
		}
	}
}

extension UnicodeScalar {
	
	var isEmoji: Bool {
		
		switch value {
		case 0x1F600...0x1F64F, // Emoticons
		0x1F300...0x1F5FF, // Misc Symbols and Pictographs
		0x1F680...0x1F6FF, // Transport and Map
		0x2600...0x26FF,   // Misc symbols
		0x2700...0x27BF,   // Dingbats
		0xFE00...0xFE0F,   // Variation Selectors
		0x1F900...0x1F9FF,  // Supplemental Symbols and Pictographs
		65024...65039, // Variation selector
		8400...8447: // Combining Diacritical Marks for Symbols
			return true
			
		default: return false
		}
	}
	
	var isZeroWidthJoiner: Bool {
		
		return value == 8205
	}
}

extension String {
	
	var glyphCount: Int {
		
		let richText = NSAttributedString(string: self)
		let line = CTLineCreateWithAttributedString(richText)
		return CTLineGetGlyphCount(line)
	}
	
	var isSingleEmoji: Bool {
		
		return glyphCount == 1 && containsEmoji
	}
	
	var containsEmoji: Bool {
		
		return unicodeScalars.contains { $0.isEmoji }
	}
	
	var containsOnlyEmoji: Bool {
		
		return !isEmpty
			&& !unicodeScalars.contains(where: {
				!$0.isEmoji
					&& !$0.isZeroWidthJoiner
			})
	}
	
	// The next tricks are mostly to demonstrate how tricky it can be to determine emoji's
	// If anyone has suggestions how to improve this, please let me know
	var emojiString: String {
		
		return emojiScalars.map { String($0) }.reduce("", +)
	}
	
	var emojis: [String] {
		
		var scalars: [[UnicodeScalar]] = []
		var currentScalarSet: [UnicodeScalar] = []
		var previousScalar: UnicodeScalar?
		
		for scalar in emojiScalars {
			
			if let prev = previousScalar, !prev.isZeroWidthJoiner && !scalar.isZeroWidthJoiner {
				
				scalars.append(currentScalarSet)
				currentScalarSet = []
			}
			currentScalarSet.append(scalar)
			
			previousScalar = scalar
		}
		
		scalars.append(currentScalarSet)
		
		return scalars.map { $0.map{ String($0) } .reduce("", +) }
	}
	
	fileprivate var emojiScalars: [UnicodeScalar] {
		
		var chars: [UnicodeScalar] = []
		var previous: UnicodeScalar?
		for cur in unicodeScalars {
			
			if let previous = previous, previous.isZeroWidthJoiner && cur.isEmoji {
				chars.append(previous)
				chars.append(cur)
				
			} else if cur.isEmoji {
				chars.append(cur)
			}
			
			previous = cur
		}
		
		return chars
	}
}
