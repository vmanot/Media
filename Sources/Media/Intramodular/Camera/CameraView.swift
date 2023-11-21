//
// Copyright (c) Vatsal Manot
//

import AVFoundation
@_spi(Internal) import SwiftUIZ

public struct CameraView: View {
    @ViewStorage var _proxy = CameraViewProxy(base: nil)
    
    public var body: some View {
        _CameraView(_proxy: $_proxy.binding)
            ._provideViewProxy(_proxy)
    }
}
