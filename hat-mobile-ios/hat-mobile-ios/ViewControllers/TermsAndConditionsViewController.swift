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

// MARK: class

/// The terms and conditions view controller class
class TermsAndConditionsViewController: UIViewController {
    
    // MARK: - Variables
    
    /// the path to the pdf file
    var filePathURL: String = ""
    
    // MARK: - IBOutlets

    /// An IBOutlet to handle the webview
    @IBOutlet weak var webView: UIWebView!
    
    // MARK: - View controller methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // if url not nil load the file
        if let url = URL(string: self.filePathURL) {
            
            let request = NSURLRequest(url: url)
            webView.loadRequest(request as URLRequest)
            // You might want to scale the page to fit
            webView.scalesPageToFit = true
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}