//
// Copyright (c) Vatsal Manot
//

@_spi(Internal) import SwiftUIZ

#if os(iOS) || os(macOS)
/// A view that displays a live camera feed.
///
/// You can interact with this view using `CameraViewReader` (similar to how you can interact with `ScrollView` using a `ScrollViewReader`).
public struct CameraView: View {
    @ViewStorage private var _proxy = CameraViewProxy(base: nil)
    
    public init() {
        
    }
    
    public var body: some View {
        _CameraView(_proxy: $_proxy.binding)
            ._provideViewProxy(_proxy)
    }
}
#endif
