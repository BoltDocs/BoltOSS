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

import Dispatch

import GRDB

import BoltDocsets
import BoltTypes
import BoltUtils

public struct DocsetSearcher {

  public static func typeList(forDocset docset: Docset) async throws -> [TypeCountPair] {
    return try await withCheckedThrowingContinuation { continuation in
      do {
        let dbPath = docset.path.appendingPathComponent("Contents/Resources/docSet.dsidx")
        let dbQueue = try DatabaseQueue(path: dbPath)
        try dbQueue.read { db in
          let result = try TypeCountPair.fetchPairs().fetchAll(db)
          continuation.resume(returning: result)
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  public static func allEntries(forDocset docset: Docset, type: EntryType?) async throws -> [Entry] {
    return try await withCheckedThrowingContinuation { continuation in
      let dbPath = docset.path.appendingPathComponent("Contents/Resources/docSet.dsidx")
      do {
        let dbQueue = try DatabaseQueue(path: dbPath)
        try dbQueue.read { db in
          let perfectRequest = try SearchIndex.fetchAll(type: type)
          let entries = try fetchEntries(forDB: db, request: perfectRequest)
          continuation.resume(returning: entries)
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  public static func entries(forDocset docset: Docset, rawQuery: String, type: EntryType?) async throws -> [Entry] {
    // always fetch perfect, prefix and suffix matches
    // perfect matches comes first, then prefix and suffix
    return try await withCheckedThrowingContinuation { continuation in
      let dbPath = docset.path.appendingPathComponent("Contents/Resources/docSet.dsidx")
      do {
        let dbQueue = try DatabaseQueue(path: dbPath)
        try dbQueue.read { db in
          var duplicateHash = Set<Int64>()

          let duplicateResolution: (SearchIndex) -> Bool = { index in
            guard let id = index.id, !duplicateHash.contains(id) else {
              return false
            }
            duplicateHash.insert(id)
            return true
          }

          let perfectRequest = try SearchIndex.fetchPerfectMatch(rawQuery: rawQuery, type: type)
          let prefixRequest = try SearchIndex.fetchPrefixMatch(rawQuery: rawQuery, type: type)
          let suffixRequest = try SearchIndex.fetchSuffixMatch(rawQuery: rawQuery, type: type)

          let perfectEntries = try fetchEntries(forDB: db, request: perfectRequest, shouldInclude: duplicateResolution)
          let prefixEntries = try fetchEntries(forDB: db, request: prefixRequest, shouldInclude: duplicateResolution)
          let suffixEntries = try fetchEntries(forDB: db, request: suffixRequest, shouldInclude: duplicateResolution)

          continuation.resume(returning: perfectEntries + prefixEntries + suffixEntries)
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  private static func fetchEntries(
    forDB db: Database,
    request: QueryInterfaceRequest<SearchIndex>,
    shouldInclude: ((SearchIndex) -> Bool)? = nil
  ) throws -> [Entry] {
    let results = try request.fetchAll(db)
    return results.compactMap { result -> Entry? in
      let included = shouldInclude?(result) ?? true
      return included ? Entry(typeName: result.type, name: result.name, path: result.path) : nil
    }
  }

}
