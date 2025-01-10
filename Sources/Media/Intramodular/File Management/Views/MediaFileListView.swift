//
//  MediaFileListView.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI

public struct MediaFileListView: View {
    private let files: [AnyMediaFile]
    
    public init(files: [AnyMediaFile]) {
        self.files = files
    }
    
    public var body: some View {
        ForEach(files) { anyFile in
            MediaFileView(file: anyFile.file)
        }
    }
}

extension FileDropView where Content == MediaFileListView {
    public init() {
        self.init() { files in
            MediaFileListView(files: files)
        }
    }
}
