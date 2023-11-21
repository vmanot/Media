//
// Copyright (c) Vatsal Manot
//

@_implementationOnly import Nuke
@_implementationOnly import NukeUI
import Swallow
import SwiftUIX

/// A view that displays a GIF.
///
/// Notes:
/// - This view uses `NukeUI.LazyImage` under the hood.
public struct GIF: View {
    private let url: URL
    
    @Binding var data: GIF.Data?
    
    public init(
        url: URL,
        data: Binding<GIF.Data?> = .constant(nil)
    ) {
        self.url = url
        self._data = data
    }
    
    public var body: some View {
        ZStack {
            Color.black
            
            NukeUI.LazyImage(url: url) { (state: LazyImageState) in
                if let image = state.image {
                    image.onAppear {
                        self.data = (state.result?.leftValue?.container.data).flatMap(GIF.Data.init(rawValue:))
                    }
                } else {
                    Color.secondarySystemBackground
                }
            }
            .priority(.high)
            .aspectRatio(contentMode: .fit)
        }
    }
}