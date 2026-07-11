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
import QuartzCore

import GRDB

import BoltTypes
import BoltUtils

struct DocsetSearcher: LoggerProvider {

  static func typeList(forIndexDBQueue dbQueue: DatabaseQueue) async throws -> [TypeCountPair] {
    let timeStamp = CACurrentMediaTime()
    let result = try await withCheckedThrowingContinuation { continuation in
      do {
        try dbQueue.read { db in
          var result = try TypeCountPair.fetchUnsortedRawPairs().fetchAll(db)
          result = result.reduce(into: [TypeCountPair]()) { partialResult, pair in
            guard let typeSingular = pair.type?.singular else {
              return
            }
            if let index = partialResult.firstIndex(where: { $0.typeName == typeSingular }) {
              partialResult[index].count += pair.count
            } else {
              partialResult.append(TypeCountPair(typeName: typeSingular, count: pair.count))
            }
          }
          .sorted {
            guard let lhsType = $0.type, let rhsType = $1.type else {
              return true
            }
            return lhsType.sortingOrder < rhsType.sortingOrder
          }
          continuation.resume(returning: result)
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
    let timeElapsed = CACurrentMediaTime() - timeStamp
    Self.logger.info("fetched \(result.count) type list entries in \(timeElapsed)s")
    return result
  }

  static func allEntries(forIndexDBQueue dbQueue: DatabaseQueue, type: EntryType?) async throws -> [Entry] {
    return try await withCheckedThrowingContinuation { continuation in
      do {
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

  static func entries(forIndexDBQueue dbQueue: DatabaseQueue, rawQuery: String, type: EntryType?) async throws -> [Entry] {
    // always fetch perfect, prefix and suffix matches
    // perfect matches comes first, then prefix and suffix
    return try await withCheckedThrowingContinuation { continuation in
      do {
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

  static func entries(forIndexDBQueue dbQueue: DatabaseQueue, basePath: String) async throws -> [Entry] {
    return try await withCheckedThrowingContinuation { continuation in
      do {
        try dbQueue.read { db in
          let request = SearchIndex.filter(
            Column("path").like("\(basePath)#%")
          )
          let entries = try fetchEntries(forDB: db, request: request)
          continuation.resume(returning: entries)
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
      return included ? Entry(typeName: result.type, name: result.name, rawPath: result.path) : nil
    }
  }

}
