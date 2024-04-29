# Media

**Media** makes it stupid simple to work with media capture & playback in Swift. 

# Installation

### Swift Package Manager

1. Open your Swift project in Xcode.
2. Go to `File` -> `Add Package Dependency`.
3. In the search bar, enter [this URL](https://github.com/vmanot/Media/).
4. Choose the version you'd like to install.
5. Click `Add Package`.

# Usage

### Import the framework

```diff
+ import Media
```

### Display a camera view in SwiftUI 

```swift
import SwiftUI
import Media

struct MyCameraView: View {
    @State private var capturedImage: UIImage? = nil
    
    var body: some View {
        CameraViewReader { (cameraProxy: CameraViewProxy) in
            CameraView(camera: .back, mirrored: false)
                .safeAreaInset(edge: .bottom) {
                    captureButton(camera: cameraProxy) { image in
                        self.capturedImage = image
                    }
                }
        }
    }
    
    @ViewBuilder
    private func captureButton(camera: CameraViewProxy, onCapture: @escaping (UIImage) -> Void) -> some View {
        Button {
            Task { @MainActor in
                let image: UIImage = try! await camera.capturePhoto()
                onCapture(image)
            }
        } label: {
            Label {
                Text("Capture Photo")
            } icon: {
                Image(systemName: .cameraFill)
            }
            .font(.title2)
            .controlSize(.large)
            .padding(.small)
        }
        .buttonStyle(.borderedProminent)
    }
}
```

### Play audio from a file

```swift
import Foundation
import Media

struct MyAudioTask {
    @MainActor
    func playAudio(forFile fileURL: URL) {
        Task {
            try await AudioPlayer().play(.url(fileURL))
        }
    }
}
```

### Record Audio

```swift
    @MainActor
    func startRecording() async {
        do {
            try await recorder.prepare()
            try await recorder.record()
        } catch {
            print(error)
        }
    }

    @MainActor
    func stopRecording() async {
        do {
            try await recorder.stop()
        } catch {
            print(error)
        }
    }
```

### Convert audio file format

```swift
let wavFileURL: URL = try await MediaAssetLocation.url(url).convert(to: .wav)
```

# License

**Media** is licensed under the MIT License.
