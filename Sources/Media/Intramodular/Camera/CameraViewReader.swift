//
// Copyright (c) Vatsal Manot
//

@_spi(Internal) import SwiftUIX
@_spi(Internal) import SwiftUIZ

public struct CameraViewReader<Content: View>: View {
    private let content: (CameraViewProxy) -> Content
    
    public init(
        @ViewBuilder content: @escaping (CameraViewProxy) -> Content
    ) {
        self.content = content
    }
    
    public var body: some View {
        _ViewProxyReader(content: content)
    }
}
