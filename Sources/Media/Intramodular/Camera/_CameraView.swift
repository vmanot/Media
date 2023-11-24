//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import SwiftUIZ

#if os(macOS)
struct _CameraView: AppKitOrUIKitViewRepresentable {
    @Binding var _proxy: CameraViewProxy
    
    func makeAppKitOrUIKitView(context: Context) -> AppKitOrUIKitViewType {
        let view = AppKitOrUIKitViewType()
        
        return view
    }
    
    func updateAppKitOrUIKitView(_ view: AppKitOrUIKitViewType, context: Context) {
        _proxy.base = view
    }
    
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
