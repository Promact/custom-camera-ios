//
//  CaptureImageViewController.swift
//  CustomCamera
//
//  Created by Tankar Shah on 23/09/19.
//  Copyright © 2019 Tankar Shah. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import CoreMotion

protocol updateGalleryDelegate : class {
    func updateAllImages()
}

class CaptureImageViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK:- Params
    fileprivate let myPickerController = UIImagePickerController()
    fileprivate var backCamera : AVCaptureDevice?
    fileprivate var frontCamera : AVCaptureDevice?
    fileprivate var currentDevice : AVCaptureDevice?
    fileprivate let captureSession = AVCaptureSession()
    fileprivate var sessionOutput = AVCaptureStillImageOutput()
    fileprivate var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    fileprivate var usingFrontCamera = false
    fileprivate var flashStatus = "auto"
    fileprivate var coreMotionManager: CMMotionManager!
    fileprivate var deviceOrientation: UIDeviceOrientation = .portrait
    fileprivate var cameraIsObservingDeviceOrientation = false
    weak var delegate : updateGalleryDelegate?
    
    //MARK:- IBOutlet
    @IBOutlet weak var btnFlash: UIButton!
    @IBOutlet weak var btnSwitchCamera: UIButton!
    @IBOutlet weak var btnImagePreview: UIButton!
    @IBOutlet weak var btnImageClick: UIButton!
    @IBOutlet weak var viewMiddle: UIView!
    
    open var shouldKeepViewAtOrientationChanges = false
    open var shouldRespondToOrientationChanges = true {
        didSet {
            if shouldRespondToOrientationChanges {
                _startFollowingDeviceOrientation()
            } else {
                _stopFollowingDeviceOrientation()
            }
        }
    }
    
    //MARK:- View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupInitial()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self._startFollowingDeviceOrientation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self._stopFollowingDeviceOrientation()
    }
    
    //MARK:- Memory Management Methods
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK:- Custom Methods
    /** FUNCTION COMMENT
     Use : To hide Keyboard
     From where it is called : it is called from viewDidLoad
     Arguments : NA
     Return Type : Void
     **/
    func setupInitial(){
        
        /**IF/SWITCH COMMENT :
         What to check : To check if simulator then dont need to start camera
         **/
        if !self.checkIsSimulator() {
            let cameraMediaType = AVMediaType.video
            let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
            
            switch cameraAuthorizationStatus {
            case .denied:
                
                self.perform(#selector(self.cameraEnable), with: nil, afterDelay: 0.5)
                break
            case .authorized:
                
                self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
                self.selectInputDevice()
                self.beginCamera()
                break
            case .restricted: break
                
            case .notDetermined:
                // Prompting user for the permission to use the camera.
                AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
                    if granted {
                        DispatchQueue.main.async {
                            self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
                            self.selectInputDevice()
                            self.beginCamera()
                            print("Granted access to \(cameraMediaType)")
                        }
                    } else {
                        self.perform(#selector(self.cameraEnable), with: nil, afterDelay: 0.5)
                        print("Denied access to \(cameraMediaType)")
                    }
                }
            }
        }
    }
    
    /** FUNCTION COMMENT
     Use : to check device is simulator
     From where it is called : called from
     Arguments : nil
     Return Type : Bool
     **/
    func checkIsSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /** FUNCTION COMMENT
     Use : To show popup when camera is not enabled
     From where it is called : it is called from viewDidLoad notification
     Arguments : NA
     Return Type : Void
     **/
    @objc func cameraEnable() {
        let alert = UIAlertController(title: "Information", message: "Camera permission require", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                if let aString = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(aString)
                }
                self.dismiss(animated: true, completion: nil)
                
            case .cancel:
                print("cancel")
                self.dismiss(animated: true, completion: nil)
                
            case .destructive:
                print("destructive")
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in devices {
            if device.position == position {
                return device as AVCaptureDevice
            }
        }
        return nil
    }
    
    @objc func updateGallery(){
       self.delegate?.updateAllImages()
    }
    
    //MARK:- UIAction Methods
    @IBAction func btnNextClick(_ sender: Any) {
        if self.btnImagePreview.imageView?.image != nil {
            if let viewWorkController = self.storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as? PreviewViewController {
                viewWorkController.img = self.btnImagePreview.imageView?.image
                self.navigationController?.pushViewController(viewWorkController, animated: true)
            }
        }
    }
    
    @IBAction func btnBackClick(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnImageClickAction(_ sender: Any) {
        if !self.checkIsSimulator() {
            do{
                if (currentDevice?.hasTorch)!
                {
                    
                    try currentDevice?.lockForConfiguration()
                    if self.flashStatus == "auto" {
                        currentDevice?.torchMode = .auto
                        currentDevice?.flashMode = .auto
                    }
                    else if self.flashStatus == "on" {
                        currentDevice?.torchMode = .on
                        currentDevice?.flashMode = .on
                    }
                    else {
                        currentDevice?.torchMode = .off
                        currentDevice?.flashMode = .off
                    }
                    currentDevice?.unlockForConfiguration()
                }
            }catch{
                
                print(error.localizedDescription)
            }
            if let videoConnection = sessionOutput.connection(with: AVMediaType.video) {
                
                sessionOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: {
                    buffer, error in
                    
                    guard let buffer = buffer else {
                        return
                    }
                    guard let  imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer) else
                    {
                        return
                    }
                    guard var image = UIImage(data: imageData) else {
                        return
                    }
                    
                    let outPutRect = self.cameraPreviewLayer?.metadataOutputRectConverted(fromLayerRect: (self.cameraPreviewLayer?.bounds)!)
                    let takenCGImage = image.cgImage
                    let width : size_t = (takenCGImage?.width)!
                    let height: size_t = (takenCGImage?.height)!
                    let cropRect = CGRect(x: outPutRect!.origin.x * CGFloat(width), y: outPutRect!.origin.y * CGFloat(height), width: outPutRect!.size.width * CGFloat(width), height: outPutRect!.size.height * CGFloat(height))
                    let cropCGImage = takenCGImage?.cropping(to: cropRect)
                    if let cropCGImage = cropCGImage  {
                        image = UIImage(cgImage: cropCGImage, scale: 1, orientation: image.imageOrientation)
                        
                    }
                    
                    //image rotate
                    if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                        
                        image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .up)
                    } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                        
                        image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .down)
                    } else if UIDevice.current.orientation == UIDeviceOrientation.portrait {
                        image = self.fixOrientation(withImage: image)
                        
                        if self.deviceOrientation.isLandscape{
                            switch self.deviceOrientation {
                            case .landscapeLeft:
                                print("Image is Left")
                                image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .up)
                                break
                            case .landscapeRight:
                                print("Image is Right")
                                image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .down)
                                break
                            case .portraitUpsideDown:
                                print("Image is UpsideDown")
                                image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .down)
                                break
                            case .portrait:
                                print("Image is Portrait")
                                image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .up)
                                break
                            case .unknown:
                                print("Image is unknown")
                                break
                            case .faceUp:
                                print("Image is faceUp")
                                break
                            case .faceDown:
                                print("Image is faceDown")
                                break
                            }
                            
                        } else {
                            switch self.deviceOrientation {
                            case .landscapeLeft , .landscapeRight, .portrait, .unknown,.faceUp, .faceDown:
                                print("Rotate right")
                                image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .right)
                                break
                            case .portraitUpsideDown:
                                print("Image is UpsideDown so Rotate Left")
                                image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .left)
                                break
                            }
                        }
                    } else if UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown {
                        image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .left)
                    }
                    
                    self.btnImagePreview.setImage(image, for: .normal)
                    UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
                    self.perform(#selector(self.updateGallery), with: nil, afterDelay: 0.7)
                })
            }
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                
                myPickerController.delegate = self
                myPickerController.sourceType = .photoLibrary
                self.present(myPickerController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func btnSwitchCameraAction(_ sender: Any) {
        
        captureSession.beginConfiguration()
        let currentCameraInput: AVCaptureInput = captureSession.inputs[0]
        captureSession.removeInput(currentCameraInput)
        //var newCamera: AVCaptureDevice
        if (currentCameraInput as! AVCaptureDeviceInput).device.position == .back {
            currentDevice = self.cameraWithPosition(position: .front)!
        } else {
            currentDevice = self.cameraWithPosition(position: .back)!
        }
        do {
            //currentDevice = newCamera
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            captureSession.addInput(captureDeviceInput)
        }
        catch {
            print(error.localizedDescription)
        }
        captureSession.commitConfiguration()
    }
    
    @IBAction func btnFlashClick(_ sender: Any) {
        if self.flashStatus == "off" {
            btnFlash.setImage(UIImage(named: "flash_on"), for: .normal)
            self.flashStatus = "on"
        }
        else if self.flashStatus == "on" {
            btnFlash.setImage(UIImage(named: "flash_auto"), for: .normal)
            self.flashStatus = "auto"
        }
        else {
            btnFlash.setImage(UIImage(named: "flash_off"), for: .normal)
            self.flashStatus = "off"
        }
    }
    
    @IBAction func btnPicFromGalleryAction(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            self.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    //MARK:- Custom Camera Setup Methods
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    /** FUNCTION COMMENT
     Use : To choose front ot back camera
     From where it is called : it is called from videDidLoad
     Arguments : NA
     Return Type : Void
     **/
    func selectInputDevice() {
        
        let devices = AVCaptureDevice.default(for: .video)
        
        if devices?.position == AVCaptureDevice.Position.back {
            backCamera = devices
        }
        
        currentDevice = backCamera
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            captureSession.addInput(captureDeviceInput)
            captureSession.addOutput(sessionOutput)
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    /** FUNCTION COMMENT
     Use : To beign camera session
     From where it is called : it is called from videDidLoad
     Arguments : NA
     Return Type : Void
     **/
    func beginCamera() {
        
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = CGRect(x:0.0 , y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 240)
        
        // need to change here for the camera screen
        view.backgroundColor = UIColor.black
        self.viewMiddle.layer.addSublayer(cameraPreviewLayer!)
        view.bringSubview(toFront: btnFlash)
        view.bringSubview(toFront: btnSwitchCamera)
        view.bringSubview(toFront: btnImagePreview)
        view.bringSubview(toFront: btnImageClick)
        captureSession.startRunning()
    }
    
    //MARK:- Custom Camera Observing Methods
    fileprivate func _startFollowingDeviceOrientation() {
        if shouldRespondToOrientationChanges && !cameraIsObservingDeviceOrientation {
            coreMotionManager = CMMotionManager()
            coreMotionManager.accelerometerUpdateInterval = 0.1
            if coreMotionManager.isAccelerometerAvailable {
                coreMotionManager.startAccelerometerUpdates(to: OperationQueue(), withHandler:
                    {data, error in
                        
                        guard let acceleration: CMAcceleration = data?.acceleration  else{
                            return
                        }
                        
                        let scaling: CGFloat = CGFloat(1) / CGFloat(( abs(acceleration.x) + abs(acceleration.y)))
                        
                        let x: CGFloat = CGFloat(acceleration.x) * scaling
                        let y: CGFloat = CGFloat(acceleration.y) * scaling
                        
                        if acceleration.z < Double(-0.75) {
                            self.deviceOrientation = .faceUp
                        } else if acceleration.z > Double(0.75) {
                            self.deviceOrientation = .faceDown
                        } else if x < CGFloat(-0.5) {
                            self.deviceOrientation = .landscapeLeft
                        } else if x > CGFloat(0.5) {
                            self.deviceOrientation = .landscapeRight
                        }else if y < -0.5 {
                            self.deviceOrientation = .portrait
                        }else if y > CGFloat(0.5) {
                            self.deviceOrientation = .portraitUpsideDown
                        }
                        
                        self._orientationChanged()
                })
                
                cameraIsObservingDeviceOrientation = true
            } else {
                cameraIsObservingDeviceOrientation = false
            }
        }
    }
    
    fileprivate func _stopFollowingDeviceOrientation() {
        if cameraIsObservingDeviceOrientation {
            //crash
            coreMotionManager.stopAccelerometerUpdates()
            cameraIsObservingDeviceOrientation = false
        }
    }
    
    //MARK:- Custom Camera Orientation Check Methods
    @objc fileprivate func _orientationChanged() {
        let currentConnection: AVCaptureConnection? = sessionOutput.connection(with: AVMediaType.video)
        
        if let validOutputLayerConnection = currentConnection,
            validOutputLayerConnection.isVideoOrientationSupported {
            validOutputLayerConnection.videoOrientation = _currentCaptureVideoOrientation()
        }
    }
    
    fileprivate func _currentCaptureVideoOrientation() -> AVCaptureVideoOrientation {
        
        if deviceOrientation == .faceDown
            || deviceOrientation == .faceUp
            || deviceOrientation == .unknown {
            return _currentPreviewVideoOrientation()
        }
        
        return _videoOrientation(forDeviceOrientation: deviceOrientation)
    }
    
    fileprivate func _currentPreviewVideoOrientation() -> AVCaptureVideoOrientation {
        let orientation = _currentPreviewDeviceOrientation()
        return _videoOrientation(forDeviceOrientation: orientation)
    }
    
    fileprivate func _currentPreviewDeviceOrientation() -> UIDeviceOrientation {
        if shouldKeepViewAtOrientationChanges {
            return .portrait
        }
        return UIDevice.current.orientation
    }
    
    fileprivate func _videoOrientation(forDeviceOrientation deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        //        print("Device Orientation : ---------------------- Portrait : \(deviceOrientation.isPortrait) --------------- Landscape : \(deviceOrientation.isLandscape))")
        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .faceUp:
            /*
             Attempt to keep the existing orientation.  If the device was landscape, then face up
             getting the orientation from the stats bar would fail every other time forcing it
             to default to portrait which would introduce flicker into the preview layer.  This
             would not happen if it was in portrait then face up
             */
            if let validPreviewLayer = cameraPreviewLayer, let connection = validPreviewLayer.connection  {
                return connection.videoOrientation //Keep the existing orientation
            }
            //Could not get existing orientation, try to get it from stats bar
            return _videoOrientationFromStatusBarOrientation()
        case .faceDown:
            /*
             Attempt to keep the existing orientation.  If the device was landscape, then face down
             getting the orientation from the stats bar would fail every other time forcing it
             to default to portrait which would introduce flicker into the preview layer.  This
             would not happen if it was in portrait then face down
             */
            if let validPreviewLayer = cameraPreviewLayer, let connection = validPreviewLayer.connection  {
                return connection.videoOrientation //Keep the existing orientation
            }
            //Could not get existing orientation, try to get it from stats bar
            return _videoOrientationFromStatusBarOrientation()
        default:
            return .portrait
        }
    }
    
    fileprivate func _videoOrientationFromStatusBarOrientation() -> AVCaptureVideoOrientation {
        
        var orientation: UIInterfaceOrientation?
        
        DispatchQueue.main.async {
            orientation = UIApplication.shared.statusBarOrientation
        }
        
        /*
         The following would fall into the guard every other call (it is called repeatedly) if the device was
         landscape then face up/down.  Did not seem to fail if in portrait first.
         */
        guard let statusBarOrientation = orientation else {
            return .portrait
        }
        
        switch statusBarOrientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    fileprivate func fixOrientation(withImage image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        var isMirrored = false
        let orientation = image.imageOrientation
        if orientation == .rightMirrored
            || orientation == .leftMirrored
            || orientation == .upMirrored
            || orientation == .downMirrored {
            
            isMirrored = true
        }
        
        let newOrientation = _imageOrientation(forDeviceOrientation: self.deviceOrientation, isMirrored: isMirrored)
        
        if image.imageOrientation != newOrientation {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: newOrientation)
        }
        
        return image
    }
    
    fileprivate func _imageOrientation(forDeviceOrientation deviceOrientation: UIDeviceOrientation, isMirrored: Bool) -> UIImage.Orientation {
        
        switch deviceOrientation {
        case .landscapeLeft:
            return isMirrored ? .upMirrored : .up
        case .landscapeRight:
            return isMirrored ? .downMirrored : .down
        default:
            break
        }
        
        return isMirrored ? .leftMirrored : .right
    }
    
    //MARK:- Gallery Image Capture Methods
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.btnImagePreview.setImage(image, for: .normal)
            UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
            self.perform(#selector(self.updateGallery), with: nil, afterDelay: 0.7)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK:- Deallocate Methods
    deinit {
        print("deallocated")
    }
}
