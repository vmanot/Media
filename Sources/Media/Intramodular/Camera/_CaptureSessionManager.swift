//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import AppKit
#endif
import AVFoundation
import Merge
import Swallow
import SwiftUIX

#if os(macOS)
class _CaptureSessionManager: NSObject {
    weak var _representableView: AppKitOrUIKitView?
    
    private(set) var cameraIsReadyToUse = false
    private let session = AVCaptureSession()
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private lazy var capturePhotoOutput = AVCapturePhotoOutput()
    private lazy var dataOutputQueue = DispatchQueue(
        label: UUID().uuidString,
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    private var captureCompletionBlock: ((NSImage) -> Void)?
    private var preparingCompletionHandler: ((Bool) -> Void)?
    private var snapshotImageOrientation = CGImagePropertyOrientation.upMirrored
    
    init(previewView: NSView) {
        self._representableView = previewView
        
        super.init()
        
        self.prepare(previewView: previewView, completion: nil)
    }
    
    func prepare(
        previewView: NSView,
        completion: ((Bool) -> Void)?
    ) {
        self._representableView = previewView
        self.preparingCompletionHandler = completion
        checkCameraAccess { allowed in
            if allowed {
                self.setup()
            }
            completion?(allowed)
            self.preparingCompletionHandler = nil
            
            self.start()
        }
    }
    
    private func setup() {
        configureCaptureSession()
    }
    func start() {
        if cameraIsReadyToUse {
            session.startRunning()
        }
    }
    func stop() {
        session.stopRunning()
    }
}

extension _CaptureSessionManager {
    
    private func checkCameraAccess(completion: ((Bool) -> Void)?) {
        // Handle camera access permission on macOS
        // macOS handles camera permissions differently and may not require explicit permission handling as iOS does
        completion?(true)
    }
    
    private func configureCaptureSession() {
        guard let previewView = _representableView else {
            assertionFailure()
            
            return
        }
        
        guard let camera = AVCaptureDevice.default(for: .video) else {
            assertionFailure()
            
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            session.addInput(cameraInput)
        } catch {
            assertionFailure()
            
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        session.addOutput(videoOutput)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isVideoMirrored = true
        
        previewView.layer = previewLayer
        
        self.previewLayer = previewLayer
        
        session.startRunning()
    }
}

extension _CaptureSessionManager: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard
            let captureCompletionBlock = captureCompletionBlock,
            let outputImage = NSImage(
                sampleBuffer: sampleBuffer,
                orientation: snapshotImageOrientation
            ) else
        {
            return
        }
        
        DispatchQueue.main.async {
            captureCompletionBlock(outputImage)
        }
    }
}


extension _CaptureSessionManager {
    func capturePhoto() async throws -> _UncheckedSendable<AppKitOrUIKitImage> {
        return await withCheckedContinuation { continuation in
            self.captureCompletionBlock = { image in
                self.captureCompletionBlock = nil
                continuation.resume(returning: _UncheckedSendable(image))
            }
        }
    }
}
#endif
