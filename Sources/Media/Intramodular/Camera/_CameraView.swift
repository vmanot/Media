//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import SwiftUIZ

#if os(iOS) || os(macOS)
struct _CameraView: AppKitOrUIKitViewRepresentable {
    @Binding var _proxy: CameraViewProxy
    
    func makeAppKitOrUIKitView(context: Context) -> AppKitOrUIKitViewType {
        let view = AppKitOrUIKitViewType()
        
        return view
    }
    
    func updateAppKitOrUIKitView(_ view: AppKitOrUIKitViewType, context: Context) {
        _proxy.base = view.captureSessionManager
    }
}

#if os(iOS)
extension _CameraView {
    class AppKitOrUIKitViewType: AppKitOrUIKitView {
        lazy var captureSessionManager = _CaptureSessionManager(previewView: self)
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
            captureSessionManager.start()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            captureSessionManager._representableView?._SwiftUIX_firstLayer?.frame = bounds
        }
    }
}
#elseif os(macOS)
extension _CameraView {
    class AppKitOrUIKitViewType: AppKitOrUIKitView {
        lazy var captureSession = _CaptureSessionManager(previewView: self)
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            
            captureSession.start()
        }
        
        override func layout() {
            super.layout()
            
            captureSession._representableView?.frame = bounds
        }
    }
}
#endif

#endif
