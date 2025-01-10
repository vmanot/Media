//
//  ImageFileCell.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI

public struct ImageFileCell: View {
    let file: ImageFile
    
    public init(file: ImageFile) {
        self.file = file
    }
    
    public var body: some View {
        VStack {
            AsyncImage(url: file.url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxHeight: 300)
            
            if let width = file.metadata["width"]?.value as? Double,
               let height = file.metadata["height"]?.value as? Double {
                HStack {
                    Label("\(Int(width))×\(Int(height))", systemImage: "rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Label(file.format.rawValue.uppercased(), systemImage: "photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
