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
    func capturePhoto() async throws -> AppKitOrUIKitImage
}

public struct CameraViewProxy {
    weak var base: _CameraViewProxyBase?
    
    public func capturePhoto() async throws -> AppKitOrUIKitImage {
        try await base.unwrap().capturePhoto()
    }
}

extension CameraViewProxy: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base === rhs.base
    }
}

@_spi(Internal)
extension CameraViewProxy: _ViewProxyType {
    public init(_nilLiteral: ()) {
        
    }
}
