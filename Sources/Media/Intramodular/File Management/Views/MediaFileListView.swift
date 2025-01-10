//
//  MediaFileListView.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI

public struct MediaFileListView: View {
    private let files: [AnyMediaFile]
    
    public init<C: Collection>(_ anyMediaFiles: C) where C.Element == AnyMediaFile {
        self.files = Array(anyMediaFiles)
    }
    
    public init<C: Collection>(files: C) where C.Element: MediaFile {
        self.files = files.map(AnyMediaFile.init)
    }
    
    public var body: some View {
        List(files) { anyFile in
            MediaFileView(file: anyFile.file)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

extension FileDropView where Content == MediaFileListView {
    public init() {
        self.init() { files in
            MediaFileListView(files)
        }
    }
}
