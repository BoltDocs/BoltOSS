//
// Copyright (C) 2026 Bolt Contributors
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

import BoltAppleDocumentation
import BoltDocsets
import BoltTypes
import BoltUtils

import GRDB

final class AppleAPIDocumentationLoader {

  enum Error: LocalizedError {

    case indexEntryNotFound(_ requestKey: String)
    case cacheEntryNotFound(_ uuid: String)

    var errorDescription: String? {
      switch self {
      case let .indexEntryNotFound(requestKey):
        return "Index entry not found for requestKey: \(requestKey)"
      case let .cacheEntryNotFound(uuid):
        return "Cache entry not found for uuid: \(uuid)"
      }
    }

  }

  static func loadAppleDocumentationContent(
    scheme: AppleDocURLScheme,
    language: SourceLanguage
  ) async throws -> Data? {
    let docsetUUID = scheme.docsetUUID
    var path = scheme.path

    guard path.starts(with: "/data/"), path.pathExtension == "json" else {
      return nil
    }

    path = path.replacingPrefix("/data/", with: "/").deletingPathExtension

    let docsetPath = LocalFileSystem.docsetsAbsolutePath
      .appendingPathComponent(docsetUUID)
      .appendingPathComponent(scheme.docsetFileName)

    let resourcesPath = docsetPath.appendingPathComponent("Contents/Resources")

    let indexDBQueue = try DatabaseQueue(path: resourcesPath.appendingPathComponent("docSet.dsidx"))

    let requestKey = "\(language.languagePrefix)\(path)"

    let indexRow = try await indexDBQueue.read { db in
      try IndexDBCacheEntity
        .filter(Column("request_key") == "\(requestKey)")
        .fetchOne(db)
    }

    guard let indexRow = indexRow else {
      throw Error.indexEntryNotFound(requestKey)
    }

    let hashedPath = indexRow.requestKeyAlias

    let documentsPath = resourcesPath.appendingPathComponent("Documents")

    let cacheDBQueue = try DatabaseQueue(path: documentsPath.appendingPathComponent("cache.db"))

    let (cacheRef, cacheData) = try await cacheDBQueue.read { db -> (CacheDBRefEntity?, CacheDBDataEntity?) in
      guard let ref = try CacheDBRefEntity
        .filter(Column("uuid") == hashedPath)
        .fetchOne(db)
      else {
        return (nil, nil)
      }
      let dataEntity = try CacheDBDataEntity
        .filter(Column("row_id") == ref.dataId)
        .fetchOne(db)
      return (ref, dataEntity)
    }

    guard let cacheRef = cacheRef, let cacheData = cacheData else {
      throw Error.cacheEntryNotFound(hashedPath)
    }

    if let data = cacheData.data {
      return try AppleDocFileSystem.documentationData(
        forData: data,
        offset: cacheRef.offset,
        length: cacheRef.length,
        isCompressed: cacheData.isCompressed
      )
    } else {
      return try AppleDocFileSystem.documentationData(
        forRootPath: documentsPath,
        fileID: cacheRef.dataId,
        offset: cacheRef.offset,
        length: cacheRef.length,
        isCompressed: cacheData.isCompressed
      )
    }
  }

}
