//
//  ViewExtension.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

extension UIView {
	
	func shake() {
		let animation = CABasicAnimation(keyPath: "position")
		animation.duration = 0.07
		animation.repeatCount = 4
		animation.autoreverses = true
		animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - 5, y: center.y))
		animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + 5, y: center.y))
		layer.add(animation, forKey: "position")
	}
}
