//
//  CodeVerificationViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseAuth

class CodeVerificationViewController: UIViewController {
	
	@IBOutlet weak var verificationCodeTextField: UITextField!
	
	var verificationID: String?
	
	@IBAction func verifyAction(_ sender: LoadingButton) {
		let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID ?? "", verificationCode: verificationCodeTextField.text!)

		sender.startLoading()
		
		Auth.auth().signIn(with: credential) { (_, error) in
			sender.stopLoading()
			
			if let error = error {
				let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .default))
				self.present(alert, animated: true)
			} else {
				self.dismiss(animated: true)
			}
		}
	}
}
