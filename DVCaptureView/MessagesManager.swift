//
//  MessagesManager.swift
//  DVCaptureView
//
//  Created by Dmitriy Virych on 6/1/17.
//  Copyright © 2017 DmitriyVirych. All rights reserved.
//

import Foundation
import UIKit



class MessagesManager {

    static private let viewControllerToPresentFrom = UIApplication.shared.windows.first?.rootViewController
    
    static func showAlert(title: String?, message: String?, actions: [UIAlertAction]? = nil){
        
        let alertControl = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if actions != nil {
            for action in actions! {
                alertControl.addAction(action)
            }
        }
        else {
            alertControl.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        viewControllerToPresentFrom?.present(alertControl, animated: true, completion: nil)
    }
}
