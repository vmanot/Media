//
// Copyright (c) Vatsal Manot
//

import Combine
#if canImport(CoreMedia)
import CoreMedia
#endif
#if canImport(CoreVideo)
import CoreVideo
#endif
@_spi(Internal) import SwiftUIZ

#if os(iOS) || os(macOS)
protocol _CameraViewProxyBase: AnyObject {
    var _outputSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> { get }
    var _outputImageBufferPublisher: AnyPublisher<CVImageBuffer, Never> { get }
    
    @MainActor
    func capturePhoto() async throws -> _AnyImage
}
#endif

public struct CameraViewProxy: HashEquatable {
    weak var base: _CameraViewProxyBase?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(base.map(ObjectIdentifier.init))
    }
}

#if os(iOS) || os(macOS)
extension CameraViewProxy {
    public var _outputSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never>? {
        base?._outputSampleBufferPublisher
    }
    
    public var _outputImageBufferPublisher: AnyPublisher<CVImageBuffer, Never>? {
        base?._outputImageBufferPublisher
    }
    
    public func capturePhoto() async throws -> _AnyImage {
        let result = try await base.unwrap().capturePhoto()
        
        return result
    }
    
    @_disfavoredOverload
    public func capturePhoto() async throws -> AppKitOrUIKitImage {
        try await capturePhoto().appKitOrUIKitImage.unwrap()
    }
}
#endif

// MARK: - Conformances

@_spi(Internal)
extension CameraViewProxy: _ViewProxyType {
    public init(_nilLiteral: ()) {
        
    }
}
