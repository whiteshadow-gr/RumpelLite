/** Copyright (C) 2016 HAT Data Exchange Ltd
 * SPDX-License-Identifier: AGPL-3.0
 *
 * This file is part of the Hub of All Things project (HAT).
 *
 * RumpelLite is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License
 * as published by the Free Software Foundation, version 3 of
 * the License.
 *
 * RumpelLite is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
 * the GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General
 * Public License along with this program. If not, see
 * <http://www.gnu.org/licenses/>.
 */

import KeychainSwift
import Alamofire
import SwiftyJSON
import Crashlytics
import JWTDecode
import SwiftyRSA

// MARK: Class

/// A class about the methods concerning the HAT
class HatAccountService {
    
    // MARK: - User's settings
    
    /**
     Get the Market Access Token for the iOS data plug
     
     - returns: HATUsername
     */
    class func TheHATUsername() -> Constants.HATUsernameAlias {
        
        return Constants.HATDataPlugCredentials.HAT_Username
    }
    
    /**
     Get the Market Access Token for the iOS data plug
     
     - returns: HATPassword
     */
    class func TheHATPassword() -> Constants.HATPasswordAlias {
        
        return Constants.HATDataPlugCredentials.HAT_Password
    }
    
    /**
     Get the Market Access Token for the iOS data plug
     
     - returns: UserHATDomainAlias
     */
    class func TheUserHATDomain() -> Constants.UserHATDomainAlias {
        
        if let hatDomain = Helper.GetKeychainValue(key: Constants.Keychain.HATDomainKey) {
            
            return hatDomain
        }
        
        return ""
    }
    
    /**
     Gets user's token from keychain
     
     - returns: The token as a string
     */
    class func getUsersTokenFromKeychain() -> String {
        
        // check if the token has been saved in the keychain and return it. Else return an empty string
        if let token = Helper.GetKeychainValue(key: "UserToken") {
            
            return token
        }
        
        return ""
    }
    
    /**
     Gets user token completion function
     
     - parameter callback: A function variable of type, @escaping (String) -> Void) -> (_ r: Helper.ResultType)
     */
    private class func getUserTokenCompletionFunction (callback: @escaping (String) -> Void) -> (_ r: Helper.ResultType) -> Void {
        
        // return the token if success
        return { (_ r: Helper.ResultType) -> Void in
            
            switch r {
                
            case .error(let error, let statusCode):
                
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["error" : error.localizedDescription, "statusCode: " : String(describing: statusCode)])
            case .isSuccess(let isSuccess, _, let result):
                
                if isSuccess {
                    
                    let checkResult: String = "accessToken"
                    
                    if result[checkResult].exists() {
                        
                        callback(result[checkResult].stringValue)
                        print(result[checkResult].stringValue)
                    }
                }
            }
        }
    }
    
    // MARK: - Delete from hat
    
    /**
     Deletes a record from hat
     
     - parameter token: The user's token
     - parameter recordId: The record id to delete
     - parameter success: A callback called when successful of type @escaping (String) -> Void
     */
    class func deleteHatRecord(token: String, recordId: Int, success: @escaping (String) -> Void) {
        
        // get user's domain
        let userDomain = HatAccountService.TheUserHATDomain()
        
        // form the url
        let url = "https://"+userDomain+"/data/record/"+String(recordId)
        
        // create parameters and headers
        let parameters = ["": ""]
        let headers = ["X-Auth-Token": token]
        
        // make the request
        NetworkHelper.AsynchronousRequest(url, method: .delete, encoding: Alamofire.URLEncoding.default, contentType: Constants.ContentType.JSON, parameters: parameters, headers: headers, completion: { (r: Helper.ResultType) -> Void in
            
            // handle result
            switch r {
            
            case .isSuccess(let isSuccess, _, _):
            
                if isSuccess {
                
                    success(token)
                    
                    HatAccountService.triggerHatUpdate()
                }
            
            case .error(let error, let statusCode):
            
                print("error res: \(error)")
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["error" : error.localizedDescription, "statusCode: " : String(describing: statusCode)])
            }
        })
    }
    
    // MARK: - Create table in hat
    
    /**
     Creates the notables table on the hat
     
     - parameter token: The token returned from the hat
     */
    class func createHatTable(token: String, notablesTableStructure: Dictionary<String, Any>) -> (_ callback: Void) -> Void {
        
        return { (_ callback: Void) -> Void in
            
            // create headers and parameters
            //let parameters = JSONHelper.createNotablesTableJSON()
            let headers = Helper.ConstructRequestHeaders(token)
            let url = "https://" + HatAccountService.TheUserHATDomain() + "/data/table"
            
            // make async request
            NetworkHelper.AsynchronousRequest(url, method: HTTPMethod.post, encoding: Alamofire.JSONEncoding.default, contentType: Constants.ContentType.JSON, parameters: notablesTableStructure, headers: headers, completion: { (r: Helper.ResultType) -> Void in
                
                // handle result
                switch r {
                    
                case .isSuccess(let isSuccess, _, _):
                    
                    if isSuccess {
                        
                        callback
                    }
                    
                case .error(let error, let statusCode):
                    
                    print("error res: \(error)")
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["error" : error.localizedDescription, "statusCode: " : String(describing: statusCode)])
                }
            })
        }
    }
    
    /**
     Checks if a table exists
     
     - parameter tableName: The table we are looking as String
     - parameter sourceName: The source name as String
     - parameter authToken: The user's token as String
     - parameter successCallback: A callback called when successful of type @escaping (NSNumber) -> Void
     - parameter errorCallback: A callback called when failed of type @escaping (Void) -> Void)
     */
    class func checkHatTableExists(tableName: String, sourceName: String, authToken: String, successCallback: @escaping (NSNumber) -> Void, errorCallback: @escaping (Void) -> Void) -> Void {
        
        // create the url
        let tableURL = Helper.TheUserHATCheckIfTableExistsURL(tableName: tableName, sourceName: sourceName)
        
        // create parameters and headers
        let parameters = ["": ""]
        let header = ["X-Auth-Token": authToken]
        
        // make async request
        NetworkHelper.AsynchronousRequest(
            tableURL,
            method: HTTPMethod.get,
            encoding: Alamofire.URLEncoding.default,
            contentType: Constants.ContentType.JSON,
            parameters: parameters,
            headers: header,
            completion: {(r: Helper.ResultType) -> Void in
                
                switch r {
                    
                case .error(let error, let statusCode):
                    
                    if statusCode == 404 {
                        
                        errorCallback()
                    } else {
                        
                        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["error" : error.localizedDescription, "statusCode: " : String(describing: statusCode)])
                    }
                case .isSuccess(let isSuccess, let statusCode, let result):
                    
                    if isSuccess {
                        
                        let tableID = result["fields"][0]["tableId"].number
                        
                        //table found
                        if statusCode == 200 {
                            
                            // get notes
                            if tableID != nil {
                                
                                successCallback(tableID!)
                            }
                            //table not found
                        } else if statusCode == 404 {
                            
                            errorCallback()
                        }
                    }
                }
        })
    }
    
    /**
     Checks if a table exists
     
     - parameter tableName: The table we are looking as String
     - parameter sourceName: The source name as String
     - parameter authToken: The user's token as String
     - parameter successCallback: A callback called when successful of type @escaping (NSNumber) -> Void
     - parameter errorCallback: A callback called when failed of type @escaping (Void) -> Void)
     */
    class func checkHatTableExistsForUploading(tableName: String, sourceName: String, authToken: String, successCallback: @escaping (Dictionary<String, Any>) -> Void, errorCallback: @escaping (Void) -> Void) -> Void {
        
        // create the url
        let tableURL = Helper.TheUserHATCheckIfTableExistsURL(tableName: tableName, sourceName: sourceName)
        
        // create parameters and headers
        let parameters = ["": ""]
        let header = ["X-Auth-Token": authToken]
        
        // make async request
        NetworkHelper.AsynchronousRequest(
            tableURL,
            method: HTTPMethod.get,
            encoding: Alamofire.URLEncoding.default,
            contentType: Constants.ContentType.JSON,
            parameters: parameters,
            headers: header,
            completion: {(r: Helper.ResultType) -> Void in
                
                switch r {
                    
                case .error(let error, let statusCode):
                    
                    if statusCode == 404 {
                        
                        errorCallback()
                    } else {
                        
                        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["error" : error.localizedDescription, "statusCode: " : String(describing: statusCode)])
                    }
                case .isSuccess(let isSuccess, let statusCode, let result):
                    
                    if isSuccess {
                        
                        //table found
                        if statusCode == 200 {
                            
                            guard let dictionary = result.dictionary else {
                                
                                break
                            }
                            successCallback(dictionary)
                        //table not found
                        } else if statusCode == 404 {
                            
                            errorCallback()
                        }
                    }
                }
        })
    }
    
    // MARK: - Get hat values from a table

    /**
     Gets values from a particular table
     
     - parameter token: The token in String format
     - parameter tableID: The table id as NSNumber
     - parameter successCallback: A callback called when successful of type @escaping ([JSON]) -> Void
     - parameter errorCallback: A callback called when failed of type @escaping (Void) -> Void)
     */
    class func getHatTableValues(token: String, tableID: NSNumber, successCallback: @escaping ([JSON]) -> Void, errorCallback: @escaping (Void) -> Void) {
    
    // get user's hat domain
    let userDomain = self.TheUserHATDomain()
            
    // form the url
    let url = "https://"+userDomain+"/data/table/"+tableID.stringValue+"/values?pretty=true"
    
    // create parameters and headers
    let parameters = ["starttime": "0"]
    let headers = ["X-Auth-Token": token]
    
    // make the request
    NetworkHelper.AsynchronousRequest(url, method: .get, encoding: Alamofire.URLEncoding.default, contentType: Constants.ContentType.JSON, parameters: parameters, headers: headers,
                                      completion:
                                        { (r: Helper.ResultType) -> Void in
                                            
                                            switch r {
                                                
                                            case .error(let error, let statusCode):
                                                
                                                errorCallback()
                                                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["error" : error.localizedDescription, "statusCode: " : String(describing: statusCode)])
                                            case .isSuccess(let isSuccess, _, let result):
                                                
                                                if isSuccess {
                                                    
                                                    guard let array = result.array else {
                                                        
                                                        errorCallback()
                                                        return
                                                    }
                                                    
                                                    successCallback(array)
                                                }
                                            }
                                        }
        )
    }
    
    // MARK: - Trigger an update
    
    /**
     Triggers an update to hat servers
     */
    class func triggerHatUpdate() -> Void {
        
        // get user domain
        let userDomain = HatAccountService.TheUserHATDomain()
        // define the url to connect to
        let url = "https://notables.hubofallthings.com/api/bulletin/tickle?"
        
        // make the request
        Alamofire.request(url, method: .get, parameters: ["phata": userDomain], encoding: Alamofire.URLEncoding.default, headers: nil).responseString { response in
                
                HatAccountService.errorHandlingWith(response: response)
        }
    }
    
    /**
     <#Function Details#>
     
     - parameter <#Parameter#>: <#Parameter description#>
     */
    private class func errorHandlingWith(response: DataResponse<String>) {
        
        // handle error codes
        print("Success: \(response.result.isSuccess)")
        print("Response String: \(response.result.value)")
        
        // check for numerous errors
        var statusCode = response.response?.statusCode
        if let error = response.result.error as? AFError {
            
            statusCode = error._code // statusCode private
            switch error {
                
            case .invalidURL(let url):
                
                print("Invalid URL: \(url) - \(error.localizedDescription)")
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Invalid URL" : "\(url) - \(error.localizedDescription)"])
            case .parameterEncodingFailed(let reason):
                
                print("Parameter encoding failed: \(error.localizedDescription)")
                print("Failure Reason: \(reason)")
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Parameter encoding failed:" : "\(error.localizedDescription)", "Failure Reason:" : "\(reason)"])
            case .multipartEncodingFailed(let reason):
                
                print("Multipart encoding failed: \(error.localizedDescription)")
                print("Failure Reason: \(reason)")
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Multipart encoding failed:" : "\(error.localizedDescription)", "Failure Reason:" : "\(reason)"])
            case .responseValidationFailed(let reason):
                
                print("Response validation failed: \(error.localizedDescription)")
                print("Failure Reason: \(reason)")
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Response validation failed:" : "\(error.localizedDescription)", "Failure Reason:" : "\(reason)"])
                switch reason {
                    
                case .dataFileNil, .dataFileReadFailed:
                    
                    print("Downloaded file could not be read")
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Failure Reason:" : "Downloaded file could not be read"])
                case .missingContentType(let acceptableContentTypes):
                    
                    print("Content Type Missing: \(acceptableContentTypes)")
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Content Type Missing:" : "\(acceptableContentTypes)"])
                case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                    
                    print("Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)")
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Response content type:" : "\(responseContentType) was unacceptable: \(acceptableContentTypes)"])
                case .unacceptableStatusCode(let code):
                    
                    print("Response status code was unacceptable: \(code)")
                    statusCode = code
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Response status code was unacceptable:" : "\(code)"])
                }
            case .responseSerializationFailed(let reason):
                
                print("Response serialization failed: \(error.localizedDescription)")
                print("Failure Reason: \(reason)")
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Response serialization failed:" : "\(error.localizedDescription)", "Failure Reason:" : "\(reason)"])
                // statusCode = 3840 ???? maybe..
            }
            
            print("Underlying error: \(error.underlyingError)")
            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Underlying error:" : "\(error.underlyingError)"])
        } else if let error = response.result.error as? URLError {
            
            print("URLError occurred: \(error)")
            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["URLError occurred:" : "\(error)"])
        } else {
            
            print("Unknown error: \(response.result.error)")
            if let error = response.result.error {
                
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Unknown error:" : "\(error)"])
            }
        }
        
        print(statusCode!) // the status code
    }
    
    // MARK: - Verify domain
    
    /**
     Verify the domain if it's what we expect
     
     - parameter domain: The formated doamain
     - returns: Bool, true if the domain matches what we expect and false otherwise
     */
    class func verifyDomain(_ domain: String) -> Bool {
        
        if domain == "hubofallthings.net" || domain == "warwickhat.net" {
            
            return true
        }
        
        return false
    }
    
    /**
     Log in button pressed. Begin authorization
     
     - parameter userHATDomain: The user's domain
     - parameter successfulVerification: The function to execute on successful verification
     - parameter failedVerification: The function to execute on failed verification
     */
    class func logOnToHAT(userHATDomain: String?, successfulVerification: @escaping (String) -> Void, failedVerification: @escaping () -> Void) {
        
        var userDomain = userHATDomain
        // trim values
        guard let hatDomain = userDomain?.TrimString() else {
            
            return
        }
        
        // username guard
        guard let _userDomain = userDomain, !hatDomain.isEmpty else {
            
            userDomain = ""
            return
        }
        
        // split text field text by .
        var array = hatDomain.components(separatedBy: ".")
        // remove the first string
        array.remove(at: 0)
        
        // form one string
        var domain = ""
        for section in array {
            
            domain += section + "."
        }
        
        // chack if we are out of bounds and drop last leter
        if domain.characters.count > 1 {
            
            domain = String(domain.characters.dropLast())
        }
        
        // verify if the domain is what we want
        if HatAccountService.verifyDomain(domain) {
            
            // authorise user
            successfulVerification(_userDomain)
        } else {
            
            //show alert
            failedVerification()
        }
    }
    
    /**
     Log in authorization process
     
     - parameter userDomain: The user's domain
     - parameter url: The url to connect
     - parameter selfViewController: The UIViewController that calls this method
     */
    class func loginToHATAuthorization(userDomain: String, url: NSURL, selfViewController: LoginViewController) {
        
        // get token out
        if let token = Helper.GetQueryStringParameter(url: url.absoluteString, param: Constants.Auth.TokenParamName) {
            
            // save token in keychain
            let savedSuccesfully = Helper.SetKeychainValue(key: "UserToken", value: token)
            
            if savedSuccesfully {
                
                // make asynchronous call
                // parameters..
                let parameters = ["": ""]
                // auth header
                let headers = ["Accept": Constants.ContentType.Text, "Content-Type": Constants.ContentType.Text]
                // HAT domain
                let hatDomain = userDomain.TrimString()
                
                if let url = Helper.TheUserHATDOmainPublicKeyURL(hatDomain) {
                    
                    //. application/json
                    NetworkHelper.AsynchronousStringRequest(url, method: HTTPMethod.get, encoding: Alamofire.URLEncoding.default, contentType: Constants.ContentType.Text, parameters: parameters as Dictionary<String, AnyObject>, headers: headers) { [weak selfViewController](r: Helper.ResultTypeString) -> Void in
                        
                        guard let weakSelf = selfViewController else { return }
                        
                        switch r {
                        case .isSuccess(let isSuccess, _, let result):
                            
                            if isSuccess {
                                
                                // decode the token and get the iss out
                                let jwt = try! decode(jwt: token)
                                
                                // guard for the issuer check, “iss” (Issuer)
                                guard let HATDomainFromToken = jwt.issuer else {
                                    
                                    weakSelf.createClassicOKAlertWith(alertMessage: NSLocalizedString("auth_error_general", comment: "auth"), alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
                                    return
                                }
                                
                                /*
                                 The token will consist of header.payload.signature
                                 To verify the token we use header.payload hashed with signature in base64 format
                                 The public PEM string is used to verify also
                                 */
                                let tokenAttr: [String] = token.components(separatedBy: ".")
                                
                                // guard for the attr length. Should be 3 [header, payload, signature]
                                guard tokenAttr.count == 3 else {
                                    
                                    weakSelf.createClassicOKAlertWith(alertMessage: NSLocalizedString("auth_error_general", comment: "auth"), alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
                                    return
                                }
                                
                                // And then to access the individual parts of token
                                let header: String = tokenAttr[0]
                                let payload: String = tokenAttr[1]
                                let signature: String = tokenAttr[2]
                                
                                // decode signature from baseUrl64 to base64
                                let decodedSig = signature.fromBase64URLToBase64(s: signature)
                                
                                // data to be verified header.payload
                                let headerAndPayload = header + "." + payload
                                
                                // SwiftyRSA.verifySignatureString
                                let result: VerificationResult = SwiftyRSA.verifySignatureString(headerAndPayload, signature: decodedSig, publicKeyPEM: result, digestMethod: .SHA256)
                                
                                /*
                                 if successful ,we performSegue to the map view
                                 else, we display a message
                                 */
                                if (result.isSuccessful) {
                                    
                                    weakSelf.authoriseAppToWriteToCloud(hatDomain, HATDomainFromToken)
                                } else {
                                    
                                    weakSelf.createClassicOKAlertWith(alertMessage: NSLocalizedString("auth_error_invalid_token", comment: "auth"), alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
                                }
                            } else {
                                
                                // alamo fire http fail
                                weakSelf.createClassicOKAlertWith(alertMessage: result, alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
                            }
                            
                        case .error(let error, let statusCode):
                            
                            let msg: String = Helper.ExceptionFriendlyMessage(statusCode, defaultMessage: error.localizedDescription)
                            weakSelf.createClassicOKAlertWith(alertMessage: msg, alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
                        }
                    }
                }
            } else {
                
                selfViewController.createClassicOKAlertWith(alertMessage: "Could not save in keychain", alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
            }
        } else {
            
            // no token in url callback redirect
            selfViewController.createClassicOKAlertWith(alertMessage: NSLocalizedString("auth_error_no_token_in_callback", comment: "auth"), alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
        }
    }
    
    /**
     Registers app to write on HAT
     
     - parameter userDomain: The user's domain
     - parameter HATDomainFromToken: The HAT domain from token
     - parameter viewController: The UIViewController that calls this method
     */
    class func authoriseAppToWriteToCloud(_ userDomain: String, _ HATDomainFromToken: String, viewController: LoginViewController) {
        
        // parameters..
        let parameters = ["" : ""]
        
        // auth header
        let headers: [String : String] = Helper.ConstructRequestHeaders(Helper.TheMarketAccessToken())
        // construct url
        let url = Helper.TheAppRegistrationWithHATURL(userDomain)
        
        // make asynchronous call
        NetworkHelper.AsynchronousRequest(url, method: HTTPMethod.get, encoding: Alamofire.URLEncoding.default, contentType: "application/json", parameters: parameters, headers: headers) { [weak viewController](r: Helper.ResultType) -> Void in
            
            guard let weakSelf = viewController else { return }
            switch r {
            case .isSuccess(let isSuccess, _, let result):
                
                if isSuccess {
                    
                    // belt and braces.. check we have a message in the returned JSON
                    if result["message"].exists() {
                        
                        // save the hatdomain from the token to the device Keychain
                        if(Helper.SetKeychainValue(key: Constants.Keychain.HATDomainKey, value: HATDomainFromToken)) {
                            
                            weakSelf.performSegue(withIdentifier: "ShowTabBarController", sender: viewController)
                            
                            // else show error in the saving in keychain
                        } else {
                            
                            weakSelf.createClassicOKAlertWith(alertMessage: NSLocalizedString("auth_error_keychain_save", comment: "keychain"), alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
                        }
                        // No message field in JSON file
                    } else {
                        
                        weakSelf.createClassicOKAlertWith(alertMessage: "Message not found", alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
                    }
                    // general error
                } else {
                    
                    weakSelf.createClassicOKAlertWith(alertMessage: result.rawString()!, alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
                }
                
            case .error(let error, let statusCode):
                
                //show error
                let msg: String = Helper.ExceptionFriendlyMessage(statusCode, defaultMessage: error.localizedDescription)
                weakSelf.createClassicOKAlertWith(alertMessage: msg, alertTitle: NSLocalizedString("error_label", comment: "error"), okTitle: "OK", proceedCompletion: {() -> Void in return})
            }
        }
    }
}