//
//  LoadingButton.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit

class LoadingButton: UIButton {
	
	var loading: UIActivityIndicatorView?
	var titleBackup: String?
	
	func startLoading() {
		if loading == nil {
			loading = UIActivityIndicatorView(frame: bounds)
			addSubview(loading!)
			loading?.isUserInteractionEnabled = true
			loading?.activityIndicatorViewStyle = .white
			loading?.startAnimating()
			
			titleBackup = title(for: .normal)
			setTitle("", for: .normal)
		}
	}
	
	func stopLoading() {
		if loading != nil {
			loading?.removeFromSuperview()
			loading?.stopAnimating()
			loading = nil
			setTitle(titleBackup, for: .normal)
		}
	}
}
