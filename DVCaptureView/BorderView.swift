//
//  DVCaptureView.swift
//  DVCaptureView
//
//  Created by DimaVirych on 30.03.17.
//  Copyright © 2017 DmitriyVirych. All rights reserved.
//

import UIKit

final class Border: UIView {
    
    var borderWidth: CGFloat? {
        didSet {
            draw(frame)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        let color: UIColor = .white
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        bpath.lineWidth = borderWidth ?? 2
        backgroundColor = .clear
        
        color.set()
        bpath.stroke()
    }
}
