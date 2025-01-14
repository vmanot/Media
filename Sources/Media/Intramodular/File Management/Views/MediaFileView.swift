//
//  MediaFileView.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUIX
import AVFoundation
import _AVKit_SwiftUI
import Combine

public struct MediaFileView: View {
    let file: any MediaFile
    
    public init(file: any MediaFile) {
        self.file = file
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(file.sizeFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Media content
            if let audioFile = file as? AudioFile {
                AudioFileView(file: audioFile)
            } else if let videoFile = file as? VideoFile {
                VideoFileView(file: videoFile)
            } else if let imageFile = file as? ImageFile {
                ImageFileView(file: imageFile)
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}
