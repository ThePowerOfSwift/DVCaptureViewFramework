//
//  DVCaptureView.swift
//  DVCaptureView
//
//  Created by DimaVirych on 30.03.17.
//  Copyright © 2017 DmitriyVirych. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage
import GLKit


open class DVCaptureView: UIView {
    
    // MARK: Properties
    
    open var isBorderEnabled: Bool!
    open var torchEnabled = true {
        didSet {
            if let device = self.captureDevice, device.hasTorch && device.hasFlash {
                
                try! device.lockForConfiguration()
                device.torchMode = self.torchEnabled ? .on : .off
                device.unlockForConfiguration()
            }
        }
    }
    open var borderWidth: CGFloat? {
        didSet {
            let borderView = Border(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
            borderView.borderWidth = borderWidth
            overlayImage = borderView.toCIImage()
        }
    }
    
    
    // MARK: Private properties
    
    fileprivate var renderBuffer: GLuint = 0
    fileprivate var stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    fileprivate var overlayImage: CIImage!
    fileprivate var contentSize: CGSize?
    fileprivate var captureDevice: AVCaptureDevice?
    fileprivate var dataOutput: AVCaptureVideoDataOutput?
    fileprivate var glkView: GLKView!
    fileprivate var coreImageContext: CIContext?
    fileprivate var context: EAGLContext!
    fileprivate var rectangleFeature: CIRectangleFeature!
    fileprivate var captureSession: AVCaptureSession! {
        didSet {
            configureSession(captureSession)
        }
    }
    
    
    // MARK: Lifecycle
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        borderWidth = 30
    }
    
    deinit {
        captureSession?.stopRunning()
    }
    
    
    // MARK: Actions
    
    open func configureSession(_ session: AVCaptureSession) {
        defaultConfigureSession()
        // for subclasses
    }
    
    open func stopSession() {
        captureSession?.stopRunning()
    }
    
    open func startSession() {
        
        requestPermissions()
        captureSession != nil ? captureSession.startRunning() : ()
    }
    
    open func updateGLKView() {
        if glkView == nil {
            createGLKView()
        }
    }
    
    open func getImage(_ complition: @escaping (UIImage) -> Void) {
        captureImage { (image) in
            let rotatedImage = image.uiImage().image(withRotation: -(CGFloat.pi / 2))
            complition(rotatedImage)
        }
    }
    
    fileprivate func captureImage(_ complition: @escaping (CIImage) -> Void) {
        
        HUD.showWait()
        var videoConnection: AVCaptureConnection?
        for connection in self.stillImageOutput.connections as! [AVCaptureConnection] {
            for port in connection.inputPorts as! [AVCaptureInputPort] {
                if port.mediaType == AVMediaTypeVideo {
                    videoConnection = connection
                    break
                }
            }
            if let _ = videoConnection {
                break
            }
        }
        
        self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { (imageSampleBuffer, error) -> Void in
            HUD.dismiss()
            guard let jpg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer) else { return }
            var enhancedImage: CIImage = CIImage(data: jpg)!
            
            
            if self.isBorderEnabled {
                if let rectangleFeature = self.biggestRectangleInRectangles(rectangles: self.highAccuracyRectangleDetector()?.features(in: enhancedImage) as! [CIRectangleFeature]) {
                    
                    enhancedImage = self.correctPerspective(for: enhancedImage, withFeatures: rectangleFeature)
                }
            }
            complition(enhancedImage)
            self.captureSession.removeOutput(self.stillImageOutput)
        })
    }
}


// MARK: Default settings

extension DVCaptureView {
    
    fileprivate func createGLKView() {
        
        context = EAGLContext(api: .openGLES2)
        glkView = GLKView(frame: frame, context: context!)
        coreImageContext = CIContext(eaglContext: context!)
        glkView.contentScaleFactor = 1.0
        glkView.drawableDepthFormat = .format24
        insertSubview(glkView, at: 0)
    }
    
    fileprivate func defaultConfigureSession() {
        
        var input: AVCaptureDeviceInput
        
        guard let device = captureDevice else { return }
        
        do { input = try AVCaptureDeviceInput(device: device) } catch { return }
        
        captureSession.addInput(input)
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput!.alwaysDiscardsLateVideoFrames = true
        dataOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : kCVPixelFormatType_32BGRA]
        dataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.DVCameraView"))
        captureSession.addOutput(dataOutput)
        if captureSession.canAddOutput(stillImageOutput){
            captureSession.addOutput(stillImageOutput)
        }
        
        if let connection = dataOutput?.connections.first as? AVCaptureConnection {
            connection.videoOrientation = .portrait
            captureSession.canAdd(connection)
        }
        DispatchQueue.main.async {
            self.captureSession.startRunning()
        }
    }
    
    fileprivate func configureDevice() {
        
        captureDevice = AVCaptureDevice.devices().first as? AVCaptureDevice
        captureSession = AVCaptureSession()
        torchEnabled = true
    }
    
    fileprivate func requestPermissions() {
        
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { [weak self] bool in
            
            if bool {
                DispatchQueue.main.async {
                    
                    self?.configureDevice()
                }
            } else {
                MessagesManager.showAlert(title: nil, message: "Camera access is required", actions: [
                    UIAlertAction(title: "Settings", style: .default, handler: { (alert) in
                        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                    }),
                    UIAlertAction(title: "Cancel", style: .cancel)])
            }
        }
    }
}


// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

extension DVCaptureView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        DispatchQueue.main.sync {
            
            var image = CIImage(cvImageBuffer: imageBuffer)
            var border: CIRectangleFeature?
            if isBorderEnabled {
                let features = highAccuracyRectangleDetector()?.features(in: image)
                border = biggestRectangleInRectangles(rectangles: features)
            }
            if border != nil {
                image = drawHighlightOverlay(forPoints: CIImage(cvImageBuffer: imageBuffer), rect: border) ?? image
            }
            if context != EAGLContext.current() {
                EAGLContext.setCurrent(context)
            }
            
            let rect = cropImageRect(image)
            
            glkView.bindDrawable()
            coreImageContext?.draw(image, in: bounds, from: rect)
            glkView.display()
            glkView.contentMode = .scaleAspectFill
            border = nil
        }
    }
    
    func drawHighlightOverlay(forPoints image: CIImage, rect: CIRectangleFeature?) -> CIImage? {
        
        guard rect != nil else { return nil }
        
        let mask = overlayImage.resize(with: image.extent).applyingFilter("CIPerspectiveTransformWithExtent", withInputParameters: [
            "inputExtent": CIVector(cgRect: image.extent),
            "inputTopLeft": CIVector(cgPoint: rect!.topLeft),
            "inputTopRight": CIVector(cgPoint: rect!.topRight),
            "inputBottomLeft": CIVector(cgPoint: rect!.bottomLeft),
            "inputBottomRight": CIVector(cgPoint: rect!.bottomRight)
            
            ])
        
        return mask.compositingOverImage(image)
    }
    
    func correctPerspective(for image: CIImage, withFeatures rectangleFeature: CIRectangleFeature) -> CIImage {
        
        var rectangleCoordinates = [AnyHashable: Any]()
        rectangleCoordinates["inputTopLeft"] = CIVector(cgPoint: rectangleFeature.topLeft)
        rectangleCoordinates["inputTopRight"] = CIVector(cgPoint: rectangleFeature.topRight)
        rectangleCoordinates["inputBottomLeft"] = CIVector(cgPoint: rectangleFeature.bottomLeft)
        rectangleCoordinates["inputBottomRight"] = CIVector(cgPoint: rectangleFeature.bottomRight)
        
        return image.applyingFilter("CIPerspectiveCorrection", withInputParameters: rectangleCoordinates as? [String : Any])
    }
    
    func highAccuracyRectangleDetector() -> CIDetector? {
        
        var detector: CIDetector? = nil
        var onceToken: Int = 0
        if (onceToken == 0) {
            
            detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        }
        onceToken = 1
        return detector
    }
    
    func rectangleDetetor() -> CIDetector? {
        
        var detector: CIDetector? = nil
        var onceToken: Int = 0
        if (onceToken == 0) {
            detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorTracking: (true)])
        }
        onceToken = 1
        return detector!
    }
    
    func biggestRectangleInRectangles(rectangles: [CIFeature]?) -> CIRectangleFeature? {
        return rectangles?.sorted(by: { ($0.bounds.size.height * $0.bounds.size.width) > ($1.bounds.size.height * $1.bounds.size.width) }).first as? CIRectangleFeature
    }
    
    func cropImageRect(_ image: CIImage?) -> CGRect {
        
        var cropWidth = image?.extent.size.width ?? 0
        var cropHeight = image?.extent.size.height ?? 0
        if (cropWidth) > (cropHeight) {
            cropWidth = image?.extent.size.width ?? 0
            cropHeight = cropWidth * bounds.size.height / bounds.size.width
        } else if cropWidth < cropHeight {
            cropHeight = image?.extent.size.height ?? 0
            cropWidth = cropHeight * bounds.size.width / bounds.size.height
        }
        
        let rect = (image?.extent)!.insetBy(dx: ((image?.extent.size.width)! - cropWidth) / 2, dy: ((image?.extent.size.height)! - cropHeight) / 2)
        
        return rect
    }
}
