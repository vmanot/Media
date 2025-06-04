import UniformTypeIdentifiers
import PhotosUI
import SwiftUIX
import FoundationX

// MARK: - Configuration

public struct FileDropViewConfiguration: Hashable {
    public var allowMultiple: Bool
    public var allowedMediaTypes: Set<_MediaAssetFileType>
    
    public init(
        allowMultiple: Bool = true,
        allowedMediaTypes: Set<_MediaAssetFileType> = [
            .mp3,
            .m4a,
            .wav,
            .ogg,
            .flac,
            .aac,
            // Audio
            .png,
            .jpeg,
            .gif,
            .heic,
            .webp,
            // Images
            .mp4,
            .m4v,
            .mov,
            .avi,
            .mpeg
        ]          // Video
    ) {
        self.allowMultiple = allowMultiple
        self.allowedMediaTypes = allowedMediaTypes
    }
}

// MARK: - Main View

public struct FileDropView<Content: View>: View {
    private let configuration: FileDropViewConfiguration
    private let content: ([AnyMediaFile]) -> Content
    private let onDrop: (([AnyMediaFile]) -> Void)?
    
    @State private var isDragActive = false
    @State private var isProcessing = false
    @State private var processedFiles: [AnyMediaFile] = []
    
    public init(
        configuration: FileDropViewConfiguration = FileDropViewConfiguration(),
        onDrop: (([AnyMediaFile]) -> Void)? = nil,
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
                    isDragActive: isDragActive,
                    isProcessing: isProcessing,
                    onFilesSelected: handleSelectedFiles,
                    configuration: configuration
                )
                .padding(.horizontal)
            }
            
            content(processedFiles)
        }
        .overlay {
            if isDragActive {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .animation(.default, value: isDragActive)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            Task {
                await handleSelectedFiles(urls)
            }
            return true
        } isTargeted: { targeted in
            isDragActive = targeted
        }
    }
    
    private func handleSelectedFiles(_ urls: [URL]) async {
        isProcessing = true
        defer { isProcessing = false }
        
        var newFiles: [AnyMediaFile] = []
        
        for url in urls {
            do {
                guard let mediaType = try await detectMediaType(from: url) else { continue }
                
                if !configuration.allowedMediaTypes.isEmpty &&
                    !configuration.allowedMediaTypes.contains(mediaType) {
                    continue
                }
                
                let mediaFile = try await createMediaFile(url: url, type: mediaType)
                newFiles.append(mediaFile)
            } catch {
                print("Error processing file \(url.lastPathComponent): \(error)")
            }
        }
        
        await MainActor.run {
            if !configuration.allowMultiple {
                processedFiles = newFiles
            } else {
                processedFiles.append(contentsOf: newFiles)
            }
            onDrop?(processedFiles)
        }
    }
    
    private func detectMediaType(from url: URL) async throws -> _MediaAssetFileType? {
        guard let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return nil
        }
        
        // First try to detect from file data for more accurate type detection
        if let data = try? Data(contentsOf: url, options: .alwaysMapped),
           let type = _MediaAssetFileType(data) {
            return type
        }
        
        // Fallback to UTType-based detection
        return _MediaAssetFileType(rawValue: contentType.identifier)
    }
    
    private func createMediaFile(url: URL, type: _MediaAssetFileType) async throws -> AnyMediaFile {
        if type.isVideo {
            return .init(try await VideoFile(url: url))
        } else if type.isAudio {
            return .init(try await AudioFile(url: url))
        } else if type.isImage {
            return .init(try await ImageFile(url: url))
        } else {
            throw MediaFileError.unsupportedFileType
        }
    }
}

// MARK: - Empty State View

public struct EmptyFileDropView: View {
    let isDragActive: Bool
    let isProcessing: Bool
    let onFilesSelected: ([URL]) async -> Void
    let configuration: FileDropViewConfiguration
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemGray6)
            
            VStack(spacing: 16) {
                CircleIcon()
                
                if isProcessing {
                    Text("Processing...")
                        .foregroundStyle(.secondary)
                } else {
#if os(iOS)
                    Text("Choose media files")
                        .font(.headline)
#else
                    Text("Drag and drop media files")
                        .font(.headline)
#endif
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

private struct CircleIcon: View {
    var body: some View {
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
    }
}

// MARK: - iOS Media Picker

#if os(iOS)
private struct MediaPickerButton: View {
    let isProcessing: Bool
    let onFilesSelected: ([URL]) async -> Void
    let configuration: FileDropViewConfiguration
    
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
        .disabled(isProcessing)
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
            allowedContentTypes: Array(configuration.allowedMediaTypes).compactMap(\.utType),
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
            selection: $selectedPhotoItems,
            maxSelectionCount: configuration.allowMultiple ? nil : 1,
            matching: .images
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

// MARK: - Supporting Types

private enum MediaFileError: Error {
    case unsupportedFileType
}
