//
//  DVCaptureView.swift
//  DVCaptureView
//
//  Created by DimaVirych on 30.03.17.
//  Copyright © 2017 DmitriyVirych. All rights reserved.
//

import UIKit
import CoreImage

extension UIView {
    
    func  toCIImage() -> CIImage {
        
        self.isOpaque = false
        UIGraphicsBeginImageContextWithOptions(self.layer.frame.size, false, 1)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return CIImage(cgImage: image.cgImage!)
    }
}
