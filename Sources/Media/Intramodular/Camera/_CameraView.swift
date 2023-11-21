//
// Copyright (c) Vatsal Manot
//

import AVFoundation
@_spi(Internal) import SwiftUIZ

struct _CameraView: AppKitOrUIKitViewRepresentable {
    typealias AppKitOrUIKitViewType = CameraPreviewView
    
    @Binding var _proxy: CameraViewProxy
    
    func makeAppKitOrUIKitView(context: Context) -> AppKitOrUIKitViewType {
        let view = CameraPreviewView()
        
        return view
    }
    
    func updateAppKitOrUIKitView(_ view: AppKitOrUIKitViewType, context: Context) {
        _proxy.base = view
    }
}

class CameraPreviewView: NSView {
    lazy var cameraService = CameraService(previewView: self)
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        setupCameraSession()
    }
    
    private func setupCameraSession() {
        cameraService.start()
    }
        
    override func layout() {
        super.layout()
        
        cameraService.previewView?.frame = bounds
    }
}

#if os(macOS)
extension NSImage {
    public convenience init?(cgImage: CGImage) {
        let size = NSSize(
            width: cgImage.width,
            height: cgImage.height
        )
        self.init(cgImage: cgImage, size: size)
    }
}
#endif
