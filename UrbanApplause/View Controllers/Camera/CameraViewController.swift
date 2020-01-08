//
//  CameraViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-08.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MapKit

// Orientation transition flow.
//
// 1. User rotates device --> Device orientation change.
// 2. Device orientation change --> If orientation supported by that view controller, triggers UIInterfaceOrientationShould change
// 3. UIInterfaceOrienation change --> Triggers call to VC method `viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)`. For this VC, the viewWillTransition method has override that triggers change in cameraPreviewView 's videoPreviewLayer orientation.
// 4. User presses capture button --> stillImageOutput's orientation set to match videoPreviewLayer.

protocol CameraViewDelegate: class {
    func cameraController(_ controller: CameraViewController, didFinishWithImage: UIImage?, data: Data?, atLocation location: CLLocation?)
}

class CameraViewController: UIViewController {
    private var appContext: AppContext
    weak var delegate: CameraViewDelegate?
    
    private var awaitingLocationToComplete = false
    private var isSessionRunning = false
    private var captureSession: AVCaptureSession?
    private var stillImageOutput: AVCapturePhotoOutput?
    private var previewView = CameraPreviewView()
    private let sessionQueue = DispatchQueue.global(qos: .userInitiated)
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    init(appContext: AppContext) {
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Style constants
    var toolbarHeight: CGFloat = 200
    var overlayColor: UIColor = UIColor.black.withAlphaComponent(0.5)

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    var errorMessage: String? = nil {
        didSet {
            guard errorMessage != nil else { return }
            // this usually gets set on global queue, so dispatch to main
            DispatchQueue.main.async {
                self.showAlert(title: "Something went wrong", message: self.errorMessage)
            }
        }
    }

    var capturedPhoto: AVCapturePhoto?

    lazy var capturedImageView: UIImageView = {
        let capturedImageView = UIImageView()
        capturedImageView.translatesAutoresizingMaskIntoConstraints = false
        capturedImageView.accessibilityIdentifier = "capturedImageView"
        capturedImageView.contentMode = .scaleAspectFill
        capturedImageView.backgroundColor = .black
        capturedImageView.autoresizesSubviews = true
        return capturedImageView
    }()

    // MARK: Toolbar views
    lazy var shutterButton = ShutterButton()
    lazy var shutterButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shutterButton)
        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.topAnchor.constraint(equalTo: view.topAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        return view
    }()
    lazy var retakeButton = UAButton(title: "Retake",
                                      target: self,
                                      action: #selector(clearCapturedImage(_:)))

    lazy var doneButton: UAButton = {
        let button = UAButton(title: "Done", target: self, action: #selector(finish(_:)))
        return button
    }()

    lazy var toolbarStackView: UIStackView = {
        let toolbarStackView = UIStackView(arrangedSubviews: [shutterButtonContainer, retakeButton, doneButton])
        toolbarStackView.axis = .vertical
        toolbarStackView.spacing = StyleConstants.contentMargin
        toolbarStackView.accessibilityIdentifier = "toolbarStackView"
        toolbarStackView.translatesAutoresizingMaskIntoConstraints = false
        return toolbarStackView
    }()

    lazy var toolbarView: UIView = {
        let toolbarView = UIView()
        toolbarView.accessibilityIdentifier = "toolbarView"
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(toolbarStackView)
        toolbarView.layer.backgroundColor = overlayColor.cgColor
        toolbarView.layoutMargins = StyleConstants.defaultMarginInsets
        toolbarStackView.fillWithinMargins(view: toolbarView)
        return toolbarView
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func checkPermissions(_ callback: @escaping (Bool) -> Void) {
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                DispatchQueue.main.async {
                    if !granted {
                        callback(false)
                    } else {
                        callback(true)
                        self.sessionQueue.resume()
                    }
                }
            })
        } else {
            callback(true)
            self.sessionQueue.resume()
        }
    }

    lazy var closeButton = IconButton(image: UIImage(systemName: "xmark"),
                                      imageColor: .white,
                                      size: CGSize(width: 30, height: 30),
                                      imageSize: CGSize(width: 24, height: 24),
                                      target: self, action: #selector(closeCamera(_:)))

    func setCapturedImage(with capturedImage: UIImage?) {
        capturedImageView.image = capturedImage

        let didTakePhoto = capturedImage != nil

        // capturedImage ui: hidden when no cpatured image to show
        capturedImageView.isHidden = !didTakePhoto
        retakeButton.isHidden = !didTakePhoto
        doneButton.isHidden = !didTakePhoto

        // camera ui: hidden when user has captured image
        shutterButtonContainer.isHidden = didTakePhoto
        previewView.isHidden = didTakePhoto
        toolbarStackView.layoutIfNeeded()

    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI Setup
        self.hidesBottomBarWhenPushed = true
        view.addSubview(capturedImageView)
        capturedImageView.fill(view: view)

        view.addSubview(toolbarView)
        view.addSubview(closeButton)
        view.layoutMargins = StyleConstants.defaultMarginInsets
        NSLayoutConstraint.activate([
            toolbarView.leftAnchor.constraint(equalTo: view.leftAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbarView.rightAnchor.constraint(equalTo: view.rightAnchor),
            closeButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            closeButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor)

            ])
        view.backgroundColor = .black
        setCapturedImage(with: nil)
        shutterButton.addTarget(self, action: #selector(capturePhoto(_:)), for: .touchUpInside)
        
        // focus on tap screen
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap(_:)))
        previewView.addGestureRecognizer(recognizer)
        
        // Disable the UI. Enable the UI later, if and only if the session starts running.
        shutterButton.isEnabled = false
        
        checkPermissions { granted in
            if granted {
                self.sessionQueue.async {
                    self.configureSession()
                }
            } else {
                self.showAlertForDeniedPermissions(permissionType: "camera", onDismiss: {
                    self.dismiss(animated: true, completion: nil)
                }, appContext: self.appContext)
            }
        }
    }

    @objc func closeCamera(_: UIButton) {
        if let navController = self.navigationController {
            navController.dismiss(animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = self.view.layer.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.captureSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }

    func configureSession() {
        // Tutorial used: https://github.com/codepath/ios_guides/wiki/Creating-a-Custom-Camera-View
        sessionQueue.async { // Dispatch on global queue otherwise causes lag in rendering views
            self.captureSession = AVCaptureSession()
            // self.captureSession!.beginConfiguration()
            // Step 1 - Session setup
            self.captureSession!.sessionPreset = .photo

            // Step 2 - Input device (front or back camera) setup
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                            for: AVMediaType.video,
                                                            position: .back) else {
                self.errorMessage = "Unabled to access camera"
                return
            }
            
            do {
                self.videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

                // Step 3 - Output setup
                self.stillImageOutput = AVCapturePhotoOutput()

                // Step 4 - Add input and output to session
                if self.captureSession!.canAddInput(self.videoDeviceInput) &&
                    self.captureSession!.canAddOutput(self.stillImageOutput!) {
                    DispatchQueue.main.async {
                        self.shutterButton.isEnabled = true
                    }
                    self.captureSession!.addInput(self.videoDeviceInput)
                    self.captureSession!.addOutput(self.stillImageOutput!)

                    DispatchQueue.main.async {
                        // Step 5 - Setup live preview
                        self.previewView.videoPreviewLayer.session = self.captureSession

                        if let sharedApplication = self.appContext.sharedApplication {
                            self.previewView.videoPreviewLayer.connection?.videoOrientation =
                                UIInterfaceOrientation(rawValue: sharedApplication.statusBarOrientation.rawValue)!
                                    .getAVOrientation()
                        }

                        self.captureSession!.startRunning()
                        self.previewView.videoPreviewLayer.videoGravity = .resizeAspectFill

                        self.previewView.videoPreviewLayer.frame = self.view.layer.bounds
                        self.view.addSubview(self.previewView)
                        self.view.bringSubviewToFront(self.closeButton)
                        self.view.bringSubviewToFront(self.toolbarView)
                    }
                } else {
                    self.errorMessage = "Unable to use camera"
                }
            } catch let error {
                log.debug(error)
                self.errorMessage = "Unable to access camera"
            }
        }
    }
    
    @objc private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer
            .captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }
    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {
        
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    @objc private func capturePhoto(_ sender: Any) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        if let photoOutputConnection = stillImageOutput?.connection(with: AVMediaType.video) {
            photoOutputConnection.videoOrientation = self.previewView
                .videoPreviewLayer
                .connection!
                .videoOrientation

            stillImageOutput?.capturePhoto(with: settings, delegate: self)
        }
    }
    @objc private func clearCapturedImage(_: UIButton) {
        setCapturedImage(with: nil)
    }

    @objc private func finish(_: UIButton) {
        // Force orientation back to allowed value
        
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        let data = capturedPhoto?.fileDataRepresentation()
        if awaitingLocationToComplete {
            // 2nd time user has pressed this - complete immediately
            delegate?.cameraController(self, didFinishWithImage: capturedImageView.image, data: data, atLocation: nil)
        }
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        if let location = locationManager.location {
            delegate?.cameraController(self, didFinishWithImage: capturedImageView.image, data: data, atLocation: location)
        } else {
            self.awaitingLocationToComplete = true
            locationManager.requestLocation()
        }
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension CameraViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if awaitingLocationToComplete {
            if !(status == .authorizedAlways || status == .authorizedWhenInUse) {
                delegate?.cameraController(self,
                                           didFinishWithImage: capturedImageView.image,
                                           data: capturedPhoto?.fileDataRepresentation(),
                                           atLocation: nil)
            }
        }
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if awaitingLocationToComplete, let location = locations.first {
            delegate?.cameraController(self,
            didFinishWithImage: capturedImageView.image,
            data: capturedPhoto?.fileDataRepresentation(),
            atLocation: location)
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // see: https://stackoverflow.com/questions/46852521/how-to-generate-an-uiimage-from-avcapturephoto-with-correct-orientation
        self.capturedPhoto = photo

        if let cgImageRepresentation = photo.cgImageRepresentation(),
            let orientationInt = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
            let imageOrientation = UIImage.Orientation.orientation(fromCGOrientationRaw: orientationInt) {

            // Create image with proper orientation
            let cgImage = cgImageRepresentation.takeUnretainedValue()
            self.setCapturedImage(with: UIImage(cgImage: cgImage,
                                                scale: 1,
                                                orientation: imageOrientation))
        }
    }
}

// see https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/setting_up_a_capture_session

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    // Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
