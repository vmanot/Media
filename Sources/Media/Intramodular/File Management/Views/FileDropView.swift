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
    private let onDrop: (([AnyMediaFile]) -> ())?

    public init(
        configuration: _FileDropViewConfiguration = _FileDropViewConfiguration(),
        _ onDrop: (([AnyMediaFile]) -> ())? = nil,
        @ViewBuilder content: @escaping ([AnyMediaFile]) -> Content
    ) {
        self.configuration = configuration
        self.onDrop = onDrop
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
                if isVideoFile(url: url) {
                    let videoFile = try await VideoFile(url: url)
                    newFiles.append(.init(videoFile))
                } else if isAudioFile(url: url) {
                    let audioFile = try await AudioFile(url: url)
                    newFiles.append(.init(audioFile))
                } else if isImageFile(url: url) {
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
            onDrop?(processedFiles)
        }
    }
    
    
    #warning("This should be using MediaAssetType, however I (@archetapp) cannot use that for images, so I'm using this for the time being.")

    private func isAudioFile(url: URL) -> Bool {
        let audioExtensions = ["mp3", "wav", "flac", "aac", "ogg", "m4a"]
        return audioExtensions.contains(url.pathExtension.lowercased())
    }

    private func isVideoFile(url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }

    private func isImageFile(url: URL) -> Bool {
        let imageExtensions = ["jpeg", "jpg", "png", "gif", "bmp", "tiff"]
        return imageExtensions.contains(url.pathExtension.lowercased())
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
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filename = "photo-\(UUID().uuidString).jpeg"
                let permanentURL = documentsDirectory.appendingPathComponent(filename)
                
                do {
                    try data.write(to: permanentURL)
                    await onFilesSelected([permanentURL])
                } catch {
                    print("Failed to write photo data: \(error)")
                }
            }
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
