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

// MARK: - Conformances

extension _CameraView.AppKitOrUIKitViewType: _CameraViewProxyBase {
    func capturePhoto() async throws -> AppKitOrUIKitImage {
        try await cameraService.capturePhoto().wrappedValue
    }
}

// MARK: - Auxiliary

protocol _CameraViewProxyBase: AnyObject {
    func capturePhoto() async throws -> AppKitOrUIKitImage
}

public struct CameraViewProxy: Equatable {
    weak var base: _CameraViewProxyBase?
    
    func capturePhoto() async throws -> AppKitOrUIKitImage {
        try await base.unwrap().capturePhoto()
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base === rhs.base
    }
}

@_spi(Internal)
extension CameraViewProxy: _ViewProxyType {
    public init(_nilLiteral: ()) {
        
    }
}
