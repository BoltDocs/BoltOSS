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

enum LibraryDocsetsManagerError: Error {

  case noInfoPlistFound
  case unacceptableFeedType

}

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

  static func docset(withLibraryIndex index: DocsetInstallation) -> Docset? {
    guard let docsetFileName = docsetFileName(forInstallationId: index.id) else {
      Self.logger.warning("No docset found under installation: \(index)")
      return nil
    }

    let docsetPath = LocalFileSystem.docsetsAbsolutePath
      .appendingPathComponent(index.id)
      .appendingPathComponent(docsetFileName)

    let infoPlistPath = docsetPath.appendingPathComponent("Contents").appendingPathComponent("Info.plist")

    return docset(
      fromDocsetPath: docsetPath,
      index: index,
      infoDictionaryPath: infoPlistPath
    )
  }

  // override the Info.plist values of the docset with infomations from the feed entry
  static func writeMetadata(ofEntry entry: FeedEntry, toDocsetPath path: String) throws {
    let infoPlistPath = path.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
    guard let infoPlistDict = NSDictionary(contentsOfFile: infoPlistPath) as? [String: Any] else {
      Self.logger.warning("No Info.plist found at `\(infoPlistPath)` for feed: `\(entry.feed.id)`.")
      throw LibraryDocsetsManagerError.noInfoPlistFound
    }

    let migratedInfoDict = DocsetInfoProcessor.migrateInfoDictionaryForWritten(infoPlistDict, forFeedEntry: entry)

    try (migratedInfoDict as NSDictionary).write(to: URL(fileURLWithPath: infoPlistPath))
  }

  private static func docset(
    fromDocsetPath docsetPath: String,
    index: DocsetInstallation,
    infoDictionaryPath: String
  ) -> Docset? {
    guard let infoDict = NSDictionary(contentsOfFile: infoDictionaryPath) as? InfoDictionary else {
      Self.logger.warning("Docset Info.plist not found for path: \(docsetPath)")
      return nil
    }

    let docsetInfo = DocsetInfoProcessor.docsetInfo(forInfoDictionary: infoDict)

    let docsetIcon = docsetIcon(
      fromDocsetPath: docsetPath,
      index: index,
      docsetInfo: docsetInfo
    )

    return Docset(
      index: index,
      path: docsetPath,
      docsetInfo: docsetInfo,
      icon: docsetIcon
    )
  }

  private static func docsetIcon(
    fromDocsetPath docsetPath: String,
    index: DocsetInstallation,
    docsetInfo: DocsetInfo
  ) -> EntryIcon {
    let localIconFies = ["icon@2x.png", "icon.png", "icon.tiff"]
    let imageData = localIconFies.firstMap { file in
      let url = URL(fileURLWithPath: docsetPath)
        .appendingPathComponent(file)
      return try? Data(contentsOf: url)
    }
    if let imageData = imageData {
      return .data(imageData)
    } else if let docsetIcon = DocsetIcons(rawValue: docsetInfo.platformFamily.name) {
      return .bundled(.docsetIcon(docsetIcon))
    } else if let docsetIcon = DocsetIcons(rawValue: index.name) {
      return .bundled(.docsetIcon(docsetIcon))
    } else {
      return .providerDefault
    }
  }

}

#if DEBUG

extension LibraryDocsetsFileSystemBridge {

  static func _docsetIcon(
    fromDocsetPath docsetPath: String,
    index: DocsetInstallation,
    docsetInfo: DocsetInfo
  ) -> EntryIcon {
    return docsetIcon(
      fromDocsetPath: docsetPath,
      index: index,
      docsetInfo: docsetInfo
    )
  }

}

#endif
