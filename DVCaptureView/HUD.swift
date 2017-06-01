//
//  HUD.swift
//  DVCaptureView
//
//  Created by Dmitriy Virych on 6/1/17.
//  Copyright © 2017 DmitriyVirych. All rights reserved.
//

import Foundation
import UIKit

private let viewToShow = UIApplication.shared.windows.first?.rootViewController?.view

struct HUD {
    
    
    static private var spinner: UIActivityIndicatorView = {
        
        let act = UIActivityIndicatorView()
        act.hidesWhenStopped = true
        act.activityIndicatorViewStyle = .whiteLarge
        act.startAnimating()
        
        return act
    }()
    
    static func showWait() {
        viewToShow?.addSubview(spinner)
    }
    
    static func dismiss() {
        
        spinner.stopAnimating()
        spinner.removeFromSuperview()
    }
}
