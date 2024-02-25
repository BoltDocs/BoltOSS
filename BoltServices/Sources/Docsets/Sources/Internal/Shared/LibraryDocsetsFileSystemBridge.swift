//
// Copyright (C) 2024 Bolt Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import struct os.Logger

import BoltRepository
import BoltTypes
import BoltUtils

package struct LibraryDocsetsFileSystemBridge: LoggerProvider {

  static let docsetFileNameCache: NSCache<NSString, NSString> = {
    let cache = NSCache<NSString, NSString>()
    cache.countLimit = 20
    return cache
  }()

  package static func setupDocsetsDirectory() {
    let fileManager = FileManager.default
    let path = LocalFileSystem.docsetsAbsolutePath
    let url = LocalFileSystem.docsetsURL
    var requireSetup = false

    let (exists, isDirectory) = fileManager.fileExistsAndIsDirectory(atPath: path)
    if !exists {
      requireSetup = true
    } else if !isDirectory {
      try? fileManager.removeItem(atPath: path)
      requireSetup = true
    }

    if requireSetup {
      try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
    try? (url as NSURL).setResourceValue(true, forKey: .isExcludedFromBackupKey)
  }

  package static func docsetFileName(forInstallationId id: String) -> String? {
    let installationPath = LocalFileSystem.docsetsAbsolutePath.appendingPathComponent(id)
    if let path = docsetFileNameCache.object(forKey: id as NSString) {
      return path as String
    } else if let path = FileManager.default.contentsOfDirectory(atPath: installationPath, ofExtension: "docset").first {
      docsetFileNameCache.setObject(path as NSString, forKey: id as NSString)
      return path
    }
    return nil
  }

}
