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

import BoltTypes
import BoltUtils

enum LibraryDocsetsManagerError: Error {

  case noInfoPlistFound
  case unacceptableFeedType

}

extension LibraryDocsetsFileSystemBridge {

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

    // try resolving icon from file
    let icon: EntryIcon

    let localIconFies = ["icon@2x.png", "icon.png", "icon.tiff"]
    let imageData = localIconFies.firstMap { file in
      let url = URL(fileURLWithPath: docsetPath).appendingPathComponent(file)
      return try? Data(contentsOf: url)
    }

    if let imageData = imageData {
      icon = .data(imageData)
    } else {
      // if no icon found locally, dealing with it separately
      switch docsetInfo.platformFamily {
      case .cheatsheet:
        icon = .bundled(name: "docset-icons/cheatsheet")
      case .userContributed:
        // we assume that all user-contributed docset always has a proper icon
        icon = .providerDefault
      case .mainOrOther:
        icon = !index.name.isEmpty ? .bundled(name: "docset-icons/\(docsetInfo.identifier)") : .providerDefault
      }
    }

    return Docset(
      index: index,
      path: docsetPath,
      docsetInfo: docsetInfo,
      icon: icon
    )
  }

}
