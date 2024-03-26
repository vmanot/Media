//
// Copyright (c) Vatsal Manot
//

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

// MARK: - Auxiliary

protocol _CameraViewProxyBase: AnyObject {
    @MainActor
    func capturePhoto() async throws -> AppKitOrUIKitImage
}

public struct CameraViewProxy: HashEquatable {
    weak var base: _CameraViewProxyBase?
    
    public func capturePhoto() async throws -> AppKitOrUIKitImage {
        try await base.unwrap().capturePhoto()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(base.map(ObjectIdentifier.init))
    }
}

@_spi(Internal)
extension CameraViewProxy: _ViewProxyType {
    public init(_nilLiteral: ()) {
        
    }
}
