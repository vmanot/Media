//
// Copyright (c) Vatsal Manot
//

import FoundationX
import SwiftUIZ

public struct SVG: View {
    private let data: Data?
    
    public init(data: Data) {
        self.data = data
    }
    
    public init(
        _ name: String,
        bundle: Bundle? = nil
    ) {
        self.data = Data(
            resourceWithName: name,
            bundle: bundle
        )
    }
    
    public init(url: URL) {
        self.init(data: try! Data(contentsOf: url))
    }
    
    public var body: some View {
        if let data {
            Group {
                _DrawSVG(svg: _SVGDocument(data: data))
            }
            .id(data)
        } else {
            _UnimplementedView()
        }
    }
}

fileprivate struct _DrawSVG: View {
    @_LazyState var svg: _SVGDocument?
    
    init(svg: @autoclosure @escaping () -> _SVGDocument?) {
        self._svg = .init(wrappedValue: svg())
    }
}

extension _DrawSVG: AppKitOrUIKitViewRepresentable {
    func makeAppKitOrUIKitView(context: Context) -> AppKitOrUIKitViewType {
        AppKitOrUIKitViewType(svg)
    }
    
    func updateAppKitOrUIKitView(_ view: AppKitOrUIKitViewType, context: Context) {
        // do nothing
    }
}

#if canImport(UIKit)
extension _DrawSVG {
    public final class AppKitOrUIKitViewType: AppKitOrUIKitView {
        var svg: _SVGDocument?
        
        public init(_ svg: _SVGDocument?) {
            self.svg = svg
            
            super.init(frame: .init(origin: .zero, size: svg?.size ?? .zero))
            
            isOpaque = false
        }
        
        @available(*, unavailable)
        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override public func draw(_ rect: CGRect) {
            guard let context = UIGraphicsGetCurrentContext() else {
                return
            }
            
            svg?.draw(in: context, size: rect.size)
        }
    }
}
#elseif os(macOS)
extension _DrawSVG {
    public final class AppKitOrUIKitViewType: AppKitOrUIKitView {
        var svg: _SVGDocument?
        
        public init(_ svg: _SVGDocument?) {
            self.svg = svg
            
            super.init(frame: .zero)
        }
        
        @available(*, unavailable)
        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override public func draw(_ rect: CGRect) {
            guard let context = NSGraphicsContext.current?.cgContext else {
                return
            }
            
            svg?.draw(in: context, size: rect.size)
        }
    }
}
#endif
