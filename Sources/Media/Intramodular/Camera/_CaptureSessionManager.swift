//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS) 

#if os(macOS)
import AppKit
#endif
import AVFoundation
import CoreGraphics
import Merge
import Swallow
@_spi(Internal) import SwiftUIX

@MainActor
class _CaptureSessionManager: NSObject {
    var _representable: _CameraView
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
    
    @MainActor
    private var imageOutputHandlers: [(AppKitOrUIKitImage) -> Void] = []
    private var snapshotImageOrientation = CGImagePropertyOrientation.upMirrored
    
    init(representable: _CameraView, representableView: AppKitOrUIKitView) {
        self._representable = representable
        self._representableView = representableView
        
        super.init()
        
        Task { @MainActor in
            try await prepare(representableView)
        }
    }
    
    @MainActor
    func prepare(
        _ view: AppKitOrUIKitView
    ) async throws {
        self._representableView = view
        
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

extension AVCaptureDevice.Position {
    public init(_from position: CameraView._CameraPosition) {
        switch position {
            case .auto:
                self = .unspecified
            case .back:
                self = .back
            case .front:
                self = .front
        }
    }
}

extension _CaptureSessionManager {
    private func configureCaptureSession() {
        guard let previewView = _representableView else {
            assertionFailure()
            
            return
        }
        
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: AVCaptureDevice.Position(
                _from: _representable.configuration.cameraPosition
            )
        ) ?? AVCaptureDevice.default(for: .video) else {
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
        
        #if os(iOS)
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        #endif
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                
        previewView._SwiftUIX_firstLayer = previewLayer
        
        self.previewLayer = previewLayer
        
        start()
    }
    
    func representableWillUpdate() {        
        if let isMirrored = _representable.configuration.isMirrored {
            previewLayer?.connection?._assignIfNotEqual(isMirrored, to: \.isVideoMirrored)
        } else {
            previewLayer?.connection?._assignIfNotEqual(true, to: \.automaticallyAdjustsVideoMirroring)
        }
    }
    
    func representableDidUpdate() {
        
    }
}

#if os(iOS) || os(visionOS)
extension CGImagePropertyOrientation {
    init(videoOrientation: AVCaptureVideoOrientation) {
        switch videoOrientation {
            case .portrait: self = .right
            case .portraitUpsideDown: self = .left
            case .landscapeRight: self = .up
            case .landscapeLeft: self = .down
            @unknown default: self = .up
        }
    }
}
#endif

extension _CaptureSessionManager: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let snapshotImageOrientation: CGImagePropertyOrientation
        #if os(iOS) || os(visionOS)
        snapshotImageOrientation = self.snapshotImageOrientation
        #else
        snapshotImageOrientation = self.snapshotImageOrientation
        #endif
        
        guard
            !imageOutputHandlers.isEmpty,
            let outputImage = AppKitOrUIKitImage(
                sampleBuffer: sampleBuffer,
                orientation: snapshotImageOrientation
            ) else
        {
            return
        }
        
        Task { @MainActor in
            imageOutputHandlers.forEach { handler in
                handler(outputImage)
            }
            
            imageOutputHandlers.removeAll()
        }
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        
    }
}

extension _CaptureSessionManager: _CameraViewProxyBase {
    @MainActor
    func capturePhoto() async throws -> AppKitOrUIKitImage {
        return await withCheckedContinuation { continuation in
            self.imageOutputHandlers.append({ image in
                continuation.resume(returning: image)
            })
        }
    }
}

#endif
