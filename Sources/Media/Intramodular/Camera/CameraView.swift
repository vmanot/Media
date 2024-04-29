//
// Copyright (c) Vatsal Manot
//

@_spi(Internal) import SwiftUIX
@_spi(Internal) import SwiftUIZ

#if os(iOS) || os(macOS)
/// A view that displays a live camera feed.
///
/// You can interact with this view using `CameraViewReader` (similar to how you can interact with `ScrollView` using a `ScrollViewReader`).
public struct CameraView: View {
    public typealias CameraPosition = _CameraViewConfiguration.CameraPosition
    
    @Environment(\._cameraViewConfiguration) var inheritedConfiguration
    
    public var explicitConfiguration = _CameraViewConfiguration()
    
    private var resolvedConfiguration: _CameraViewConfiguration {
        inheritedConfiguration.mergingInPlace(with: explicitConfiguration)
    }
    
    @ViewStorage private var _viewProxy = CameraViewProxy(base: nil)
    
    public init() {
        
    }
    
    public init(
        camera: _CameraViewConfiguration.CameraPosition = .auto,
        mirrored: Bool? = nil
    ) {
        self.explicitConfiguration.cameraPosition = camera
        self.explicitConfiguration.isMirrored = mirrored
    }
    
    public var body: some View {
        _CameraView(configuration: resolvedConfiguration, _proxy: $_viewProxy.binding)
            ._provideViewProxy(_viewProxy)
            .id(resolvedConfiguration.cameraPosition)
    }
}

extension CameraView {
    public func processingFrameRate(
        _ frameRate: _CameraViewConfiguration.FrameRate
    ) -> Self {
        then {
            $0.explicitConfiguration.processingFrameRate = frameRate
        }
    }
    
    public func aspectRatio(
        _ aspectRatio: CGFloat? = nil, 
        contentMode: ContentMode
    ) -> Self {
        then {
            assert(aspectRatio == nil || aspectRatio == 1.0, "Modifying the aspect ratio is currently unsupported.")

            $0.explicitConfiguration.aspectRatio = aspectRatio
            $0.explicitConfiguration.contentMode = contentMode
        }
    }
}
#endif

extension EnvironmentValues {
    public var _cameraViewConfiguration: _CameraViewConfiguration {
        get {
            self[_type: _SwiftUIX_Metatype(_CameraViewConfiguration.self)] ?? .init()
        } set {
            self[_type: _SwiftUIX_Metatype(_CameraViewConfiguration.self)] = newValue
        }
    }
}
