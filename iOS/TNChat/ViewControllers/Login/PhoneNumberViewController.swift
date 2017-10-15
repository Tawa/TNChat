//
//  PhoneNumberViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseAuth

class PhoneNumberViewController: UIViewController {

	@IBOutlet weak var phoneNumberTextField: UITextField!
	
	@IBAction func loginAction(_ sender: LoadingButton) {
		sender.startLoading()
		
		PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberTextField.text ?? "", uiDelegate: nil, completion: { (verificationID, error) in
			sender.stopLoading()
			if let error = error {
				let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .default))
				self.present(alert, animated: true)
			} else if let verificationID = verificationID {
				self.gotoVerificationScreen(withVerificationID: verificationID)
			}
		})
	}
	
	func gotoVerificationScreen(withVerificationID verificationID: String) {
		performSegue(withIdentifier: SegueIdentifiers.showVerification, sender: verificationID)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let verificationID = sender as! String
		let vc = segue.destination as! CodeVerificationViewController
		vc.verificationID = verificationID
	}
}
