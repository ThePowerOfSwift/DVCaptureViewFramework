//
//  DVCaptureView.swift
//  DVCaptureView
//
//  Created by DimaVirych on 30.03.17.
//  Copyright © 2017 DmitriyVirych. All rights reserved.
//

import UIKit
import CoreImage

extension CIImage {
    
    func uiImage() -> UIImage {
        
        let context = CIContext.init(options: nil)
        let cgImage = context.createCGImage(self, from: self.extent)!
        let image = UIImage.init(cgImage: cgImage)
        
        return image
    }
    
    func resize(with rect: CGRect) -> CIImage {
        
        let newWidth = rect.width
        let newHeight = rect.height
        
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        self.uiImage().draw(in: CGRect(x: 0, y: 0,width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return CIImage(cgImage: newImage!.cgImage!)
    }
}
