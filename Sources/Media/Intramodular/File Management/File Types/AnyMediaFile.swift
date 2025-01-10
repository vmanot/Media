//
//  AnyMediaFile.swift
//  Media
//
//  Created by Jared Davidson on 1/9/25.
//

import SwiftUI
import CorePersistence

public struct AnyMediaFile: Identifiable {
    public let id: AnyHashable
    private let _file: any MediaFile
    
    public var file: any MediaFile { _file }
    
    public init(_ file: any MediaFile) {
        self.id = AnyHashable(_erasing: file.id)
        self._file = file
    }
}
