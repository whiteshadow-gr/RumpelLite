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

import UIKit

// MARK: Class

/// The UITabBarViewController
class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
    // MARK: - View controller functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // disable left navigation button
        self.navigationItem.leftBarButtonItems = nil
        // hide back button
        self.navigationItem.hidesBackButton = true
        
        // change tint color, the color of the selected icon in tab bar
        self.tabBar.tintColor = UIColor.tealColor()
        // set delete to self in order to receive the calls from tab bar controller
        self.delegate = self

        // set tint color, if translucent and the bar tint color of navigation bar
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.tealColor()
        
        // change navigation bar title
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSForegroundColorAttributeName: UIColor.white,
             NSFontAttributeName: UIFont(name: "OpenSans-Bold", size: 21)!]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // create bar button in navigation bar
        self.createBarButtonsFor(viewController: self.selectedViewController)
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Tab bar controller funtions
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        self.createBarButtonsFor(viewController: self.selectedViewController)
    }
    
    // MARK: - Buttons functions
    
    /**
     Create default buttons in navigation bar
     */
    func createBarButtonsFor(viewController: UIViewController?) {
        
        // remove buttons on the left and right of the navigation bar
        self.navigationItem.leftBarButtonItems = nil
        self.navigationItem.rightBarButtonItems = nil
        
        if viewController is MapViewController {
            
            // set title in navigation bar
            self.navigationItem.title = "Location"
            
            // create buttons
            let button1 = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettingsViewController))
            let button2 = UIBarButtonItem(title: "Data", style: .plain, target: self, action: #selector(showDataViewController))
            let button3 = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(logoutUser))
            
            // add buttons to navigation bar
            self.navigationItem.leftBarButtonItems = [button1, button2]
            self.navigationItem.rightBarButtonItem = button3
        } else {
            
            // change title in navigation bar
            self.navigationItem.title = "Notables"
            
            // create buttons
            let button = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(logoutUser))
            
            // add buttons to navigation bar
            self.navigationItem.rightBarButtonItem = button
        }
    }
    
    /**
     Goes to data ViewController
     */
    func showDataViewController() {
        
        self.performSegue(withIdentifier: "dataSegue", sender: self)
    }
    
    /**
     Goes to settings ViewController
     */
    func showSettingsViewController() {
        
        self.performSegue(withIdentifier: "settingsSegue", sender: self)
    }
    
    /**
     Logout procedure
     */
    func logoutUser() -> Void {
        
        let yesAction = { () -> Void in
            
            // reset the stack to avoid allowing back
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            super.navigationController?.title = ""
            let navigation = super.navigationController
            _ = super.navigationController?.popToRootViewController(animated: false)
            navigation?.pushViewController(loginViewController, animated: false)
            
            // delete keys from keychain
            let clearUserToken = Helper.ClearKeychainKey(key: "UserToken")
            let clearUserDomain = Helper.ClearKeychainKey(key: "user_hat_domain")
            
            if (!clearUserToken || !clearUserDomain) {
                
                // show alert that the log out was not completed for some reason
                // MARK: TODO
            }
        }
        
        self.createClassicAlertWith(alertMessage: NSLocalizedString("logout_message_label", comment:  "logout message"),
                                    alertTitle: NSLocalizedString("logout_label", comment:  "logout"),
                                    cancelTitle: NSLocalizedString("no_label", comment:  "no"),
                                    proceedTitle: NSLocalizedString("yes_label", comment:  "yes"),
                                    proceedCompletion: yesAction,
                                    cancelCompletion: {() -> Void in return})
    }
}