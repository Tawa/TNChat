//
//  TabBarViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseAuth

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if Auth.auth().currentUser == nil {
			performSegue(withIdentifier: SegueIdentifiers.showLogin, sender: self)
		}
	}
}
