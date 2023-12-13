//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS) 

#if os(macOS)
import AppKit
#endif
import AVFoundation
import Merge
import Swallow
@_spi(Internal) import SwiftUIX

@MainActor
class _CaptureSessionManager: NSObject {
    weak var _representableView: AppKitOrUIKitView?
    
    private(set) var cameraIsReadyToUse = false
    
    private let session = AVCaptureSession()
    
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private lazy var capturePhotoOutput = AVCapturePhotoOutput()
    
    private let authorization = AVCaptureDevice.Authorization()
    
    private lazy var dataOutputQueue = DispatchQueue(
        label: UUID().uuidString,
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    private var onImageOutput: ((AppKitOrUIKitImage) -> Void)?
    private var snapshotImageOrientation = CGImagePropertyOrientation.upMirrored
    
    init(previewView: AppKitOrUIKitView) {
        self._representableView = previewView
        
        super.init()
        
        Task { @MainActor in
            try await prepare(previewView: previewView)
        }
    }
    
    @MainActor
    func prepare(
        previewView: AppKitOrUIKitView
    ) async throws {
        self._representableView = previewView
        
        let accessGranted = await authorization.requestAccess()
        
        guard accessGranted else {
            return
        }
        
        self.setup()
        self.start()
    }
    
    private func setup() {
        configureCaptureSession()
    }
    
    func start() {
        guard cameraIsReadyToUse else {
            return
        }
        
        let session = self.session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func stop() {
        session.stopRunning()
    }
}

extension _CaptureSessionManager {
    private func configureCaptureSession() {
        guard let previewView = _representableView else {
            assertionFailure()
            
            return
        }
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ?? AVCaptureDevice.default(for: .video) else {
            #if targetEnvironment(simulator)
            runtimeIssue("This cannot be tested on an iOS simulator.")
            #endif
            
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            session.addInput(cameraInput)
        } catch {
            assertionFailure()
            
            return
        }
        
        cameraIsReadyToUse = true
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
     
        session.addOutput(videoOutput)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isVideoMirrored = true
        
        previewView._SwiftUIX_firstLayer = previewLayer
        
        self.previewLayer = previewLayer
        
        start()
    }
}

extension _CaptureSessionManager: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard
            let onImageOutput = onImageOutput,
            let outputImage = AppKitOrUIKitImage(
                sampleBuffer: sampleBuffer,
                orientation: snapshotImageOrientation
            ) else
        {
            return
        }
        
        DispatchQueue.main.async {
            onImageOutput(outputImage)
        }
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        
    }
}

extension _CaptureSessionManager {
    func capturePhoto() async throws -> _UncheckedSendable<AppKitOrUIKitImage> {
        return await withCheckedContinuation { continuation in
            self.onImageOutput = { image in
                self.onImageOutput = nil
                
                continuation.resume(returning: _UncheckedSendable(image))
            }
        }
    }
}

#endif
