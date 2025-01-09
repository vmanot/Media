//
//  FileDropView.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUIX
import UniformTypeIdentifiers

public struct _FileDropViewConfiguration: Hashable, Initiable, MergeOperatable {
    public var allowMultiple: Bool = true
    
    public init() {}
    
    public mutating func mergeInPlace(with other: _FileDropViewConfiguration) {
        self.allowMultiple = other.allowMultiple
    }
}

public struct FileDropView<Content: View>: View {
    @Environment(\._fileDropViewConfiguration) var inheritedConfiguration
    let configuration: _FileDropViewConfiguration
    
    @State private var dragOver = false
    @State private var processingFiles = false
    @State private var processedFiles: [any MediaFile] = []
    
    private let content: ([any MediaFile]) -> Content
    
    public init(
        configuration: _FileDropViewConfiguration = _FileDropViewConfiguration(),
        @ViewBuilder content: @escaping ([any MediaFile]) -> Content
    ) {
        self.configuration = configuration
        self.content = content
    }
    
    public var body: some View {
        _FileDropView(
            configuration: configuration,
            dragOver: $dragOver,
            processingFiles: $processingFiles,
            processedFiles: $processedFiles,
            content: content
        )
    }
}

struct _FileDropView<Content: View>: AppKitOrUIKitViewRepresentable {
    let configuration: _FileDropViewConfiguration
    @Binding var dragOver: Bool
    @Binding var processingFiles: Bool
    @Binding var processedFiles: [any MediaFile]
    let content: ([any MediaFile]) -> Content
    
    func makeAppKitOrUIKitView(context: Context) -> AppKitOrUIKitViewType {
        AppKitOrUIKitViewType(
            configuration: configuration,
            dragOver: $dragOver,
            processingFiles: $processingFiles,
            processedFiles: $processedFiles
        )
    }
    
    func updateAppKitOrUIKitView(_ view: AppKitOrUIKitViewType, context: Context) {
        view.configuration = configuration
    }
}

#if os(iOS)
extension _FileDropView {
    class AppKitOrUIKitViewType: UIView, UIDropInteractionDelegate {
        var configuration: _FileDropViewConfiguration
        
        @Binding var dragOver: Bool
        @Binding var processingFiles: Bool
        @Binding var processedFiles: [any MediaFile]
        
        init(
            configuration: _FileDropViewConfiguration,
            dragOver: Binding<Bool>,
            processingFiles: Binding<Bool>,
            processedFiles: Binding<[any MediaFile]>
        ) {
            self.configuration = configuration
            self._dragOver = dragOver
            self._processingFiles = processingFiles
            self._processedFiles = processedFiles
            
            super.init(frame: .zero)
            
            let dropInteraction = UIDropInteraction(delegate: self)
            addInteraction(dropInteraction)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
            dragOver = true
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
            dragOver = false
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
            Task {
                await handleDroppedFiles(from: session)
            }
        }
        
        private func handleDroppedFiles(from session: UIDropSession) async {
            processingFiles = true
            defer { processingFiles = false }
            
            var newFiles: [any MediaFile] = []
            
            for item in session.items {
                guard let urlData = try? await item.itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? Data,
                      let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                    continue
                }
                
                if let audioFile = try? await AudioFile(url: url) {
                    newFiles.append(audioFile)
                } else if let videoFile = try? await VideoFile(url: url) {
                    newFiles.append(videoFile)
                }
            }
            
            await MainActor.run {
                processedFiles.append(contentsOf: newFiles)
            }
        }
    }
}
#else
extension _FileDropView {
    class AppKitOrUIKitViewType: NSView {
        var configuration: _FileDropViewConfiguration
        
        @Binding var dragOver: Bool
        @Binding var processingFiles: Bool
        @Binding var processedFiles: [any MediaFile]
        
        init(
            configuration: _FileDropViewConfiguration,
            dragOver: Binding<Bool>,
            processingFiles: Binding<Bool>,
            processedFiles: Binding<[any MediaFile]>
        ) {
            self.configuration = configuration
            self._dragOver = dragOver
            self._processingFiles = processingFiles
            self._processedFiles = processedFiles
            
            super.init(frame: .zero)
            
            registerForDraggedTypes([.fileURL])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            dragOver = true
            return .copy
        }
        
        override func draggingExited(_ sender: NSDraggingInfo?) {
            dragOver = false
        }
        
        override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            Task {
                await handleDroppedFiles(from: sender)
            }
            return true
        }
        
        private func handleDroppedFiles(from draggingInfo: NSDraggingInfo) async {
            guard let pasteboard = draggingInfo.draggingPasteboard.propertyList(forType: .fileURL) as? [String] else {
                return
            }
            
            processingFiles = true
            defer { processingFiles = false }
            
            var newFiles: [any MediaFile] = []
            
            for path in pasteboard {
                let url = URL(fileURLWithPath: path)
                
                if let audioFile = try? await AudioFile(url: url) {
                    newFiles.append(audioFile)
                } else if let videoFile = try? await VideoFile(url: url) {
                    newFiles.append(videoFile)
                }
            }
            
            await MainActor.run {
                processedFiles.append(contentsOf: newFiles)
            }
        }
    }
}
#endif

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
