//
// Copyright (c) Vatsal Manot
//

import AVFoundation
import SwiftUIZ

#if os(iOS) || os(macOS)
struct _CameraView: AppKitOrUIKitViewRepresentable {
    let configuration: _CameraViewConfiguration
    
    @Binding var _proxy: CameraViewProxy
    
    func makeAppKitOrUIKitView(context: Context) -> AppKitOrUIKitViewType {
        let view = AppKitOrUIKitViewType()
        
        return view
    }
    
    func updateAppKitOrUIKitView(
        _ view: AppKitOrUIKitViewType,
        context: Context
    ) {
        if view.captureSessionManager == nil {
            view.captureSessionManager = _CaptureSessionManager(representable: self, representableView: view)
        } else {
            view.captureSessionManager._representable = self 
        }
        
        _proxy.base = view.captureSessionManager
        
        view.captureSessionManager.representableWillUpdate(context: context)
        view.captureSessionManager.representableDidUpdate(context: context)
    }
}

#if os(iOS)
extension _CameraView {
    class AppKitOrUIKitViewType: AppKitOrUIKitView {
        var captureSessionManager: _CaptureSessionManager!
        
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
        var captureSessionManager: _CaptureSessionManager!
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            
            captureSessionManager.start()
        }
        
        override func layout() {
            super.layout()
            
            captureSessionManager._representableView?.frame = bounds
        }
    }
}
#endif

#endif
