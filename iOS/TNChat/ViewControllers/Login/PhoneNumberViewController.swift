//
//  PhoneNumberViewController.swift
//  TNChat
//
//  Created by Tawa Nicolas on 15/10/17.
//  Copyright © 2017 Tawa Nicolas. All rights reserved.
//

import UIKit
import FirebaseAuth

// This view controller lets the user input their phone number, and choose their country code.
class PhoneNumberViewController: UIViewController {

	@IBOutlet weak var phoneNumberTextField: UITextField!
	
	@IBOutlet var countryCodeButton: UIButton!
	
	@IBOutlet weak var countryCodePicker: UIPickerView!
	@IBOutlet weak var countryCodePickerHeight: NSLayoutConstraint!
	
	var countryCode: String? {
		didSet {
			if let code = countryCode {
				setCountryCode(code: code)
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		countryCodePickerHeight.constant = 0
		phoneNumberTextField.leftView = countryCodeButton
		phoneNumberTextField.leftViewMode = .always
		countryCode = CountryCodeManager.current
	}
	
	func setCountryCode(code: String) {
		countryCodeButton.setTitle(code, for: .normal)
		countryCodeButton.sizeToFit()
		countryCodeButton.frame.size.height = phoneNumberTextField.frame.height
	}
	
	@IBAction func loginAction(_ sender: LoadingButton) {
		hideCountryCodes()
		sender.startLoading()
		
		PhoneAuthProvider.provider().verifyPhoneNumber((countryCode ?? "") + (phoneNumberTextField.text ?? ""), uiDelegate: nil, completion: { (verificationID, error) in
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
	@IBAction func countryCodeAction(_ sender: UIButton) {
		let code = sender.title(for: .normal)
		if let index = CountryCodeManager.countryCodes.index(where: { (_,_, dialCode) in
			
			return "+"+dialCode == code
		}) {
			countryCodePicker.selectRow(index, inComponent: 0, animated: false)
		}
		UIView.animate(withDuration: 0.3) {
			self.countryCodePickerHeight.constant = 216
			self.view.layoutSubviews()
		}
	}
	
	func hideCountryCodes() {
		if countryCodePickerHeight.constant > 0 {
			UIView.animate(withDuration: 0.3) {
				self.countryCodePickerHeight.constant = 0
				self.view.layoutSubviews()
			}
		}
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

extension PhoneNumberViewController: UIPickerViewDelegate, UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return CountryCodeManager.countryCodes.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		let country = CountryCodeManager.countryCodes[row]
		return "\(country.name) +\(country.dialCode)"
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		let country = CountryCodeManager.countryCodes[row]
		countryCode = "+"+country.dialCode
	}
}

