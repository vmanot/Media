//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS)

#if os(macOS)
import AppKit
#endif
import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import Merge
import Swallow
@_spi(Internal) import SwiftUIX

@MainActor
public class _CaptureSessionManager: NSObject {
    public struct State: ExpressibleByNilLiteral {
        var lastTimestamp = CMTime()
        
        public init(nilLiteral: ()) {
            
        }
    }
    
    var state: State = nil
    var _representable: _CameraView
    weak var _representableView: AppKitOrUIKitView?
        
    private let _avCaptureSession = AVCaptureSession()
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private lazy var capturePhotoOutput = AVCapturePhotoOutput()
    
    private let authorization = AVCaptureDevice.Authorization.shared
    
    private lazy var dataOutputQueue = DispatchQueue(
        label: UUID().uuidString,
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    @MainActor
    private var imageOutputHandlers: [(AppKitOrUIKitImage) -> Void] = []
    private var snapshotImageOrientation = CGImagePropertyOrientation.upMirrored
    
    private var _outputSampleBufferSubject = Publishers._MakeConnectable<PassthroughSubject<CMSampleBuffer, Never>>()
    private var _outputImageBufferSubject = Publishers._MakeConnectable<PassthroughSubject<CVImageBuffer, Never>>()
    
    public lazy var _outputSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> = _outputSampleBufferSubject.autoconnect().eraseToAnyPublisher()
    public lazy var _outputImageBufferPublisher: AnyPublisher<CVImageBuffer, Never> = _outputImageBufferSubject.autoconnect().eraseToAnyPublisher()
    
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
    
    public func start() {
        state = nil
                
        let captureSession = self._avCaptureSession
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    public func stop() {
        _avCaptureSession.stopRunning()
        
        state = nil
    }
}

extension _CaptureSessionManager {
    func representableWillUpdate(context: some _AppKitOrUIKitViewRepresentableContext) {
        if let previewLayer {
            if let isMirrored = _representable.configuration.isMirrored {
                previewLayer.connection?._assignIfNotEqual(false, to: \.automaticallyAdjustsVideoMirroring)
                previewLayer.connection?._assignIfNotEqual(isMirrored, to: \.isVideoMirrored)
            } else {
                previewLayer.connection?._assignIfNotEqual(true, to: \.automaticallyAdjustsVideoMirroring)
            }
            
            assert(_representable.configuration.aspectRatio == nil || _representable.configuration.aspectRatio == 1.0)
            
            let videoGravity = AVLayerVideoGravity(
                aspectRatio: _representable.configuration.aspectRatio,
                contentMode: _representable.configuration.contentMode
            )
            
            previewLayer._assignIfNotEqual(videoGravity, to: \.videoGravity)
        }
    }
    
    func representableDidUpdate(context: some _AppKitOrUIKitViewRepresentableContext) {
        
    }
    
    private func configureCaptureSession() {
        _configureAVCaptureSession()
        _setUpAVCaptureVideoPreviewLayer()
        
        start()
    }
    
    private func _configureAVCaptureSession() {
        _avCaptureSession.withConfigurationScope {
            guard let captureDevice: AVCaptureDevice = _makeAVCaptureDevice() else {
                runtimeIssue("Failed to create an `AVCaptureDevice`.")
                
                return
            }

            do {
                let cameraInput = try AVCaptureDeviceInput(device: captureDevice)
                
                _avCaptureSession.addInput(cameraInput)
            } catch {
                assertionFailure()
                
                return
            }
                        
            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA
            ] as [String: Any]
            
#if os(iOS)
            videoOutput.connection(with: .video)?.videoOrientation = .portrait
#endif
            
            _avCaptureSession.addOutput(videoOutput)
        }
    }
    
    private func _makeAVCaptureDevice() -> AVCaptureDevice? {
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: AVCaptureDevice.Position(
                _from: _representable.configuration.cameraPosition
            )
        ) ?? AVCaptureDevice.default(for: .video) else {
#if targetEnvironment(simulator)
            runtimeIssue("This cannot be tested on an iOS simulator.")
#endif
            
            return nil
        }
        
        return device
    }
    
    private func _setUpAVCaptureVideoPreviewLayer() {
        guard let previewView = _representableView else {
            assertionFailure()
            
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: _avCaptureSession)
        
        previewView._SwiftUIX_firstLayer = previewLayer
        
        self.previewLayer = previewLayer
    }
}

extension _CaptureSessionManager: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        _flushImageOutputHandlers(forOutput: sampleBuffer)
        _withThrottledProcessingFrameRate(forOutput: sampleBuffer) { (timestamp: CMTime) in
            _outputSampleBufferSubject.send(sampleBuffer)
            
            if _outputImageBufferSubject.isConnected {
                if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                    _outputImageBufferSubject.send(imageBuffer)
                }
            }
        }
    }
    
    public func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        
    }
    
    private func _flushImageOutputHandlers(
        forOutput sampleBuffer: CMSampleBuffer
    ) {
        guard !imageOutputHandlers.isEmpty else {
            return
        }
        
        let snapshotImageOrientation: CGImagePropertyOrientation
#if os(iOS) || os(visionOS)
        snapshotImageOrientation = self.snapshotImageOrientation
#else
        snapshotImageOrientation = self.snapshotImageOrientation
#endif
        
        guard let outputImage = AppKitOrUIKitImage(
            sampleBuffer: sampleBuffer,
            orientation: snapshotImageOrientation
        ) else {
            runtimeIssue("Failed to output image.")
            
            return
        }
        
        Task(priority: .userInitiated) { @MainActor in
            imageOutputHandlers.forEach { handler in
                handler(outputImage)
            }
            
            imageOutputHandlers.removeAll()
        }
    }
    
    private func _withThrottledProcessingFrameRate(
        forOutput sampleBuffer: CMSampleBuffer,
        _ operation: (CMTime) -> Void
    ) {
        let timestamp: CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if let processingFrameRate = _representable.configuration.processingFrameRate {
            let deltaTime = timestamp - state.lastTimestamp
            if deltaTime >= CMTimeMake(value: 1, timescale: Int32(processingFrameRate.doubleValue)) {
                state.lastTimestamp = timestamp
                
                operation(timestamp)
            }
        } else {
            operation(timestamp)
        }
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

// MARK: - Internal

extension AVLayerVideoGravity {
    fileprivate init(
        aspectRatio: CGFloat?,
        contentMode: SwiftUI.ContentMode?
    ) {
        switch (contentMode ?? .fit) {
            case .fit:
                self = .resizeAspect
            case .fill:
                if aspectRatio != nil {
                    self = .resizeAspectFill
                } else {
                    self = .resize
                }
        }
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

#endif

