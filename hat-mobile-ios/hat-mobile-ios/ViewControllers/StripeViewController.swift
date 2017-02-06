/**
 * Copyright (C) 2017 HAT Data Exchange Ltd
 *
 * SPDX-License-Identifier: MPL2
 *
 * This file is part of the Hub of All Things project (HAT).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/
 */

import UIKit
import Alamofire
import BEMCheckBox
import SwiftyJSON

// MARK: Class

/// The class responsible for buying stuff via Stripe
class StripeViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    // MARK: - Variables
    
    /// the SKU determining the product user wants to buy
    var sku: String = ""
    /// Stripe token for this purchase
    var token: String = ""
    /// The domain of the selected hat
    var domain: String = ""
    /// the file url
    private var fileURL: String = ""
    
    /// the image of the selected hat
    var hatImage: UIImage? = nil
    
    /// The purchase model to work on and push to the hat later
    private var purchaseModel: PurchaseModel = PurchaseModel()
    /// An array with all the countries
    private let countriesArray: [String] = StripeViewController.getCountries()
    /// A picker view to show as inputView on keyboard later
    private let privatePicker = UIPickerView()
    
    // MARK: - IBOutlets
    
    /// An IBOutlet for handling the arrow bar on top of the view
    @IBOutlet weak var arrowBarImage: UIImageView!
    /// An IBOutlet for handling the hat provider image
    @IBOutlet weak var hatProviderImage: UIImageView!
    
    /// An IBOutlet for handling the first name textField
    @IBOutlet weak var firstNameTextField: UITextField!
    /// An IBOutlet for handling the last name textField
    @IBOutlet weak var lastNameTextField: UITextField!
    /// An IBOutlet for handling the nickname textField
    @IBOutlet weak var nicknameTextField: UITextField!
    /// An IBOutlet for handling the email textField
    @IBOutlet weak var emailTextField: UITextField!
    /// An IBOutlet for handling the personal HAT address textField
    @IBOutlet weak var personalHATAddressTextField: UITextField!
    /// An IBOutlet for handling the password textField
    @IBOutlet weak var passwordTextField: UITextField!
    /// An IBOutlet for handling the country textField
    @IBOutlet weak var countryTextField: UITextField!
    
    /// An IBOutlet for handling the terms and conditions button
    @IBOutlet weak var termsAndConditionsButton: UIButton!
    /// An IBOutlet for handling the terms and conditions of rumpel lite button
    @IBOutlet weak var rumpelLiteTermsAndConditionsButton: UIButton!
    /// An IBOutlet for handling create hat button
    @IBOutlet weak var createHatButton: UIButton!
    
    /// An IBOutlet for handling the data view
    @IBOutlet weak var dataView: UIView!
    
    /// An IBOutlet for handling the scrollView
    @IBOutlet weak var scrollView: UIScrollView!
    
    /// An IBOutlet for handling the hat terms checkBox
    @IBOutlet weak var hatTermsCheckBox: BEMCheckBox!
    /// An IBOutlet for handling the rumpel lite checkBox
    @IBOutlet weak var rumpelLiteCheckBox: BEMCheckBox!
    
    // MARK: - IBActions
    
    /**
     Terms and conditions button action
     
     - parameter sender: The object called this method
     */
    @IBAction func termsAndConditionsButtonAction(_ sender: Any) {
        
        // get the file url to the pdf and show it to the terms and conditions view controller
        self.fileURL = (Bundle.main.url(forResource: "2.1 HATTermsofService v1.0", withExtension: "pdf", subdirectory: nil, localization: nil)?.absoluteString)!
        self.performSegue(withIdentifier: "termsSegue", sender: self)
    }
    
    /**
     Rumpel lite terms and conditions button action
     
     - parameter sender: The object called this method
     */
    @IBAction func rumpelLiteTermsAndConditionsButtonAction(_ sender: Any) {
        
        // get the file url to the pdf and show it to the terms and conditions view controller
        self.fileURL = (Bundle.main.url(forResource: "Rumpel Lite iOS Application Terms of Service", withExtension: "pdf", subdirectory: nil, localization: nil)?.absoluteString)!
        self.performSegue(withIdentifier: "termsSegue", sender: self)
    }
    
    /**
     Creates a hat
     
     - parameter sender: The object called this method
     */
    @IBAction func createHATButtonAction(_ sender: Any) {
        
        // check if what user entered is ok
        let isDataOK = self.checkIfDataAreOK()
        
        // if it is
        if isDataOK {
            
            // change create hat button accordingly
            self.createHatButton.setTitle("Authenticating... Please wait", for: .normal)
            self.createHatButton.isUserInteractionEnabled = false
            
            // configure the purchaseModel basen on the info entered
            purchaseModel.address = (self.personalHATAddressTextField.text?.replacingOccurrences(of: self.domain, with: ""))!
            purchaseModel.country = self.countryTextField.text!
            purchaseModel.email = self.emailTextField.text!
            purchaseModel.firstName = self.firstNameTextField.text!
            purchaseModel.lastName = self.lastNameTextField.text!
            purchaseModel.nick = self.nicknameTextField.text!
            purchaseModel.password = self.passwordTextField.text!
            
            purchaseModel.sku = self.sku
            purchaseModel.token = self.token
            purchaseModel.termsAgreed = true
            
            // create the json file based on the purchaseModel
            let json = JSONHelper.createPurchaseJSONFrom(purchaseModel: purchaseModel)
            
            // url to make the request
            let url = "https://hatters.hubofallthings.com/api/products/hat/purchase"
            
            // request the creation of the hat
            let _ = Alamofire.request(url, method: .post, parameters: json, encoding: Alamofire.JSONEncoding.default, headers: nil).responseJSON(completionHandler: { [weak self] response in
                
                if let status = response.response?.statusCode {
                    
                    switch(status) {
                        
                    case 400:
                        
                        if let result = response.result.value {
                            
                            // check json for errors from the server and show alerts for each one
                            let json = JSON(result)
                            
                            let errorCause = json["cause"].stringValue
                            if let details = json["details"].dictionary {
                                
                                if let country = details["hat.country"] {
                                    
                                    self?.createClassicOKAlertWith(alertMessage: country.stringValue, alertTitle: "Please review form", okTitle: "OK", proceedCompletion: {() -> Void in return})
                                }
                                if let email = details["user.email"] {
                                    
                                    self?.createClassicOKAlertWith(alertMessage: email.stringValue, alertTitle: "Please review form", okTitle: "OK", proceedCompletion: {() -> Void in return})
                                }
                                if let password = details["user.password"] {
                                    
                                    self?.createClassicOKAlertWith(alertMessage: password.stringValue, alertTitle: "Please review form", okTitle: "OK", proceedCompletion: {() -> Void in return})
                                }
                                if let nickname = details["user.nick"] {
                                    
                                    self?.createClassicOKAlertWith(alertMessage: nickname.stringValue, alertTitle: "Please review form", okTitle: "OK", proceedCompletion: {() -> Void in return})
                                }
                                if let phata = details["hat.hat.address"] {
                                    
                                    self?.createClassicOKAlertWith(alertMessage: phata.stringValue, alertTitle: "Please review form", okTitle: "OK", proceedCompletion: {() -> Void in return})
                                }
                            } else if errorCause == "Your card was declined. Please try again." {
                                
                                // card error
                                self?.createClassicOKAlertWith(alertMessage: errorCause, alertTitle: "Please review card info", okTitle: "OK", proceedCompletion: {() -> Void in return})
                            } else {
                                
                                // generic error
                                self?.createClassicOKAlertWith(alertMessage: "There was an error", alertTitle: "Please review your info", okTitle: "OK", proceedCompletion: {() -> Void in return})
                            }
                        }
                    case 200:
                        
                        // everything ok go to the next screen
                        self?.performSegue(withIdentifier: "completePurchaseSegue", sender: nil)
                    default:
                        
                        break
                    }
                    
                    // return create hat button to its original state
                    self?.createHatButton.isUserInteractionEnabled = true
                    self?.createHatButton.setTitle("Create HAT", for: .normal)
                }
            })
        } else {
            
            // if something wrong show message
            self.createClassicOKAlertWith(alertMessage: "Please check your information again", alertTitle: "Information missing", okTitle: "OK", proceedCompletion: {() -> Void in return})
        }
    }
    
    // MARK: - View controller methods

    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // config the arrowBar
        arrowBarImage.image = arrowBarImage.image!.withRenderingMode(.alwaysTemplate)
        arrowBarImage.tintColor = UIColor.rumpelVeryLightGray()
        
        // add border to terms and conditions button
        self.termsAndConditionsButton.addBorderToButton(width: 1, color: .lightGray)
        self.rumpelLiteTermsAndConditionsButton.addBorderToButton(width: 1, color: .lightGray)
        
        // configure the pickerView
        self.privatePicker.dataSource = self
        self.privatePicker.delegate = self
        
        // add the pickerView as an inputView to the textField
        self.countryTextField.inputView = self.privatePicker
        
        // create 2 notification observers for listening to the keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHandling(sender:)), name:.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHandling(sender:)), name:.UIKeyboardWillHide, object: nil);
        
        // add handling for taps
        self.hideKeyboardWhenTappedAround()
        
        // check for image
        if self.hatImage != nil {
            
            self.hatProviderImage.image = hatImage
        }
        // one country for now
        countryTextField.text = "United Kingdom"
        
        // add delegate for the text field to control it
        self.personalHATAddressTextField.delegate = self
        
        // add a target if user is editing the text field
        personalHATAddressTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // check domain if empty or ., if it is then default to .hubofallthings.net
        if self.domain == "" || self.domain == "." {
            
            self.domain = ".hubofallthings.net"
        }
    }
    
    func textFieldDidChange() {
        
        // add the domain to what user is entering
        personalHATAddressTextField.text = personalHATAddressTextField.text!.replacingOccurrences(of: self.domain, with: "") + self.domain
        
        // only if there is a currently selected range
        if let selectedRange = personalHATAddressTextField.selectedTextRange {
            
            // and only if the new position is valid
            if let newPosition = personalHATAddressTextField.position(from: selectedRange.start, offset: -self.domain.characters.count) {
                
                // set the new position
                personalHATAddressTextField.selectedTextRange = personalHATAddressTextField.textRange(from: newPosition, to: newPosition)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Get Countries
    
    /**
     Creates and returns an array with all the countries
     
     - returns: An array of String
     */
    class func getCountries() -> [String] {
        
//        let locale: NSLocale = NSLocale.current as NSLocale
//        let countryArray = Locale.isoRegionCodes
//        let unsortedCountryArray: [String] = countryArray.map { (countryCode) -> String in
//            
//            return locale.displayName(forKey: NSLocale.Key.countryCode, value: countryCode)!
//        }
//        
//        return unsortedCountryArray.sorted()
        return ["United Kingdom"]
    }
    
    // MARK: - UIPickerView methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return countriesArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return countriesArray[row] as String
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        self.countryTextField.text = self.countriesArray[row]
    }
    
    // MARK: - Keyboard handling
    
    /**
     Function executed before the keyboard is shown to the user
     
     - parameter sender: The object that called this method
     */
    func keyboardHandling(sender: NSNotification) {
        
        let userInfo = sender.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if sender.name == Notification.Name.UIKeyboardWillHide {
            
            self.scrollView.contentInset = UIEdgeInsets.zero
        } else {
            
            self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height + 60, right: 0)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "termsSegue" {
            
            // pass data to next view
            let termsVC = segue.destination as! TermsAndConditionsViewController
            
            termsVC.filePathURL = self.fileURL
        } else if segue.identifier == "completePurchaseSegue" {
            
            let completeVC = segue.destination as! CompletePurchaseViewController
            
            completeVC.image = self.hatImage
        }
    }
    
    // MARK: - Check data OK
    
    /**
     Checks if user has entered correct data in the text fields
     
     - returns: A bool, true if ok, false if error
     */
    private func checkIfDataAreOK() -> Bool {
    
        if firstNameTextField.text == "" {
            
            self.createClassicOKAlertWith(alertMessage: "Please fill your first name", alertTitle: "First Name field is empty", okTitle: "OK", proceedCompletion: {() -> Void in return})
            
            return false
        }
        
        if lastNameTextField.text == "" {
            
            self.createClassicOKAlertWith(alertMessage: "Please fill your last name", alertTitle: "Last Name field is empty", okTitle: "OK", proceedCompletion: {() -> Void in return})
            
            return false
        }
        
        if nicknameTextField.text == "" {
            
            self.createClassicOKAlertWith(alertMessage: "Please fill your nickname", alertTitle: "Nickname field is empty", okTitle: "OK", proceedCompletion: {() -> Void in return})
            
            return false
        }
        
        if emailTextField.text == "" {
            
            self.createClassicOKAlertWith(alertMessage: "Please fill your email", alertTitle: "Email field is empty", okTitle: "OK", proceedCompletion: {() -> Void in return})
            
            return false
        }
        
        if personalHATAddressTextField.text == "" {
            
            self.createClassicOKAlertWith(alertMessage: "Please fill your personal HAT address", alertTitle: "Personal HAT address field is empty", okTitle: "OK", proceedCompletion: {() -> Void in return})
            
            return false
        }
        
        if passwordTextField.text == "" {
            
            self.createClassicOKAlertWith(alertMessage: "Please fill your password", alertTitle: "Password field is empty", okTitle: "OK", proceedCompletion: {() -> Void in return})
            
            return false
        }
        
        if countryTextField.text == "" {
            
            self.createClassicOKAlertWith(alertMessage: "Please fill your desired location for your HAT", alertTitle: "Desired location field is empty", okTitle: "OK", proceedCompletion: {() -> Void in return})
            
            return false
        }
        
        if countryTextField.text != "United Kingdom" {
            
            self.createClassicOKAlertWith(alertMessage: "Currently we have servers in United Kingdom only", alertTitle: "Sorry we don't have servers in this country yet", okTitle: "OK", proceedCompletion: {() -> Void in return})
            
            return false
        }
        
        if self.hatTermsCheckBox.on == false || self.rumpelLiteCheckBox.on == false {
            
            self.createClassicOKAlertWith(alertMessage: "You have to accept both terms and condition first. ", alertTitle: "Please accept Terms & Conditions", okTitle: "OK", proceedCompletion: {() -> Void in return})
            
            return false
        }
        
        return true
    }
    
    // MARK: - Text field delegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        // delete the domain every time user taps on it
        textField.text = textField.text?.replacingOccurrences(of: domain, with: "")
        self.textFieldDidChange()
    }
}