//
//  FileDropView.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import UniformTypeIdentifiers
import PhotosUI
import SwiftUIX
import FoundationX

// MARK: - Configuration

public struct _FileDropViewConfiguration: Hashable, Initiable, MergeOperatable {
    public var allowMultiple: Bool = false
    public var allowedMediaTypes: [MediaFileType] = []
    
    public init() {}
    
    public mutating func mergeInPlace(with other: _FileDropViewConfiguration) {
        self.allowMultiple = other.allowMultiple
        self.allowedMediaTypes = [.audio, .image, .video]
    }
}

// MARK: - Main View

public struct FileDropView<Content: View>: View {
    @Environment(\._fileDropViewConfiguration) var inheritedConfiguration
    let configuration: _FileDropViewConfiguration
    
    @State private var dragOver = false
    @State private var processingFiles = false
    @State private var processedFiles: [AnyMediaFile] = []
    
    private let content: ([AnyMediaFile]) -> Content
    
    public init(
        configuration: _FileDropViewConfiguration = _FileDropViewConfiguration(),
        @ViewBuilder content: @escaping ([AnyMediaFile]) -> Content
    ) {
        self.configuration = configuration
        self.content = content
    }
    
    public var body: some View {
        VStack {
            if processedFiles.isEmpty {
                EmptyFileDropView(
                    isActive: dragOver,
                    isProcessing: processingFiles,
                    onFilesSelected: handleSelectedFiles,
                    configuration: configuration
                )
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .padding(.horizontal)
            }
            
            content(processedFiles)
        }
        .overlay {
            if dragOver {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .animation(.default, value: dragOver)
            }
        }
        .dropDestination(for: URL.self) { urls, location in
            Task {
                await handleSelectedFiles(urls)
            }
            return true
        } isTargeted: { targeted in
            dragOver = targeted
        }
    }
    
    private func handleSelectedFiles(_ urls: [URL]) async {
        processingFiles = true
        defer { processingFiles = false }

        var newFiles: [AnyMediaFile] = []

        for url in urls {
            do {
                let data = try Data(contentsOf: url, options: [.alwaysMapped])
                
                // Detect file type based on magic numbers
                if isVideoFile(data: data) {
                    let videoFile = try await VideoFile(url: url)
                    newFiles.append(.init(videoFile))
                } else if isAudioFile(data: data) {
                    let audioFile = try await AudioFile(url: url)
                    newFiles.append(.init(audioFile))
                } else if isImageFile(data: data) {
                    let imageFile = try await ImageFile(url: url)
                    newFiles.append(.init(imageFile))
                } else {
                    print("Unsupported file type: \(url.lastPathComponent)")
                }
            } catch {
                print("Error processing file \(url.lastPathComponent): \(error)")
            }
        }

        // Update UI on main thread
        await MainActor.run {
            if !configuration.allowMultiple {
                processedFiles = newFiles
            } else {
                processedFiles.append(contentsOf: newFiles)
            }
        }
    }
    
    #warning("This should be using MediaAssetType, however I (@archetapp) cannot use that for images, so I'm using this for the time being.")

    private func isVideoFile(data: Data) -> Bool {
        // MP4
        if matchesMagicNumbers(data, [0x66, 0x74, 0x79, 0x70], offset: 4) { return true }
        // MOV
        if matchesMagicNumbers(data, [0x6D, 0x6F, 0x6F, 0x76], offset: 4) { return true }
        // AVI
        if matchesMagicNumbers(data, [0x52, 0x49, 0x46, 0x46]) && matchesMagicNumbers(data, [0x41, 0x56, 0x49], offset: 8) { return true }
        // MKV
        if matchesMagicNumbers(data, [0x1A, 0x45, 0xDF, 0xA3]) { return true }
        // WebM
        if matchesMagicNumbers(data, [0x1A, 0x45, 0xDF, 0xA3]) { return true } // Shared with MKV
        return false
    }

    private func isAudioFile(data: Data) -> Bool {
        // MP3
        if matchesMagicNumbers(data, [0x49, 0x44, 0x33]) { return true }
        // WAV
        if matchesMagicNumbers(data, [0x52, 0x49, 0x46, 0x46]) && matchesMagicNumbers(data, [0x57, 0x41, 0x56, 0x45], offset: 8) { return true }
        // FLAC
        if matchesMagicNumbers(data, [0x66, 0x4C, 0x61, 0x43]) { return true }
        // AAC
        if matchesMagicNumbers(data, [0xFF, 0xF1]) || matchesMagicNumbers(data, [0xFF, 0xF9]) { return true }
        // OGG
        if matchesMagicNumbers(data, [0x4F, 0x67, 0x67, 0x53]) { return true }
        return false
    }

    private func isImageFile(data: Data) -> Bool {
        // JPEG
        if matchesMagicNumbers(data, [0xFF, 0xD8, 0xFF]) { return true }
        // PNG
        if matchesMagicNumbers(data, [0x89, 0x50, 0x4E, 0x47]) { return true }
        // GIF
        if matchesMagicNumbers(data, [0x47, 0x49, 0x46]) { return true }
        // BMP
        if matchesMagicNumbers(data, [0x42, 0x4D]) { return true }
        // TIFF (Little Endian)
        if matchesMagicNumbers(data, [0x49, 0x49, 0x2A, 0x00]) { return true }
        // TIFF (Big Endian)
        if matchesMagicNumbers(data, [0x4D, 0x4D, 0x00, 0x2A]) { return true }
        return false
    }


    private func matchesMagicNumbers(_ data: Data, _ numbers: [UInt8?], offset: Int = 0) -> Bool {
        guard data.count >= numbers.count else { return false }

        return zip(numbers.indices, numbers).allSatisfy { index, number in
            guard let number = number else { return true }
            guard (index + offset) < data.count else { return false }
            return data[index + offset] == number
        }
    }

}

// MARK: - Supporting Views

public struct EmptyFileDropView: View {
    let isActive: Bool
    let isProcessing: Bool
    let onFilesSelected: ([URL]) async -> Void
    let configuration: _FileDropViewConfiguration
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemGray6)
            
            VStack(spacing: 16) {
                Circle()
                    .stroke(Color.systemGray3, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 50, height: 50)
                    .overlay {
#if os(iOS)
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.accentColor)
#else
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.accentColor)
#endif
                    }
                
                if isProcessing {
                    Text("Processing...")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 4) {
#if os(iOS)
                        Text("Choose media files")
                            .font(.headline)
#else
                        Text("Drag and drop media files")
                            .font(.headline)
#endif
                        
                        Text("Supports images, audio, and video up to 50MB")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            
#if os(iOS)
            MediaPickerButton(
                isProcessing: isProcessing,
                onFilesSelected: onFilesSelected,
                configuration: configuration
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#endif
        }
    }
}

#if os(iOS)
struct MediaPickerButton: View {
    let isProcessing: Bool
    let onFilesSelected: ([URL]) async -> Void
    let configuration: _FileDropViewConfiguration
    
    @State private var isShowingFileImporter = false
    @State private var isShowingActionSheet = false
    @State private var isShowingPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    var body: some View {
        Button {
            isShowingActionSheet = true
        } label: {
            Color.clear
                .contentShape(Rectangle())
        }
        .confirmationDialog("Choose Media", isPresented: $isShowingActionSheet) {
            Button("Choose from Files") {
                isShowingFileImporter = true
            }
            
            Button("Photos & Videos") {
                isShowingPhotoPicker = true
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.audio, .movie, .video, .image],
            allowsMultipleSelection: configuration.allowMultiple
        ) { result in
            Task {
                if case .success(let urls) = result {
                    await onFilesSelected(urls)
                }
            }
        }
        .photosPicker(
            isPresented: $isShowingPhotoPicker,
            selection: $selectedPhotoItems
        )
        .onChange(of: selectedPhotoItems) { items in
            Task {
                await handlePhotoSelection(items)
            }
        }
    }
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) async {
        var selectedURLs: [URL] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let temporaryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(UUID().uuidString) {
                try? data.write(to: temporaryURL)
                selectedURLs.append(temporaryURL)
            }
        }
        
        await onFilesSelected(selectedURLs)
        
        // Cleanup temporary files
        for url in selectedURLs {
            try? FileManager.default.removeItem(at: url)
        }
        
        selectedPhotoItems.removeAll()
    }
}
#endif

// MARK: - Environment

extension EnvironmentValues {
    var _fileDropViewConfiguration: _FileDropViewConfiguration {
        get {
            self[_FileDropViewConfigurationKey.self]
        } set {
            self[_FileDropViewConfigurationKey.self] = newValue
        }
    }
}

private struct _FileDropViewConfigurationKey: EnvironmentKey {
    static let defaultValue = _FileDropViewConfiguration()
}
