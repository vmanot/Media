//
// Copyright (c) Vatsal Manot
//

@_spi(Internal) import SwiftUIZ

public struct CameraView: View {
    @ViewStorage private var _proxy = CameraViewProxy(base: nil)
    
    public init() {
        
    }
    
    public var body: some View {
        _CameraView(_proxy: $_proxy.binding)
            ._provideViewProxy(_proxy)
    }
}
