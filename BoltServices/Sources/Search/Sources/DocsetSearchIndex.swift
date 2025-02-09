//
// Copyright (C) 2025 Bolt Contributors
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

import GRDB
@preconcurrency import RxCocoa
@preconcurrency import RxRelay

import BoltRxSwift
import BoltTypes
import BoltUtils

enum DocsetSearchIndexError: LocalizedError {

  case noDatabaseQueue
  case noSearchIndex
  case noQueryIndex
  case underlyingError(_: Error)

  var errorDescription: String? {
    switch self {
    case .noDatabaseQueue:
      return "DocsetSearchIndexError: failed to initialize initialize the database queue"
    case .noSearchIndex:
      return "DocsetSearchIndexError: search index table not found"
    case .noQueryIndex:
      return "DocsetSearchIndexError: query index table not found"
    case let .underlyingError(error):
      return "DocsetSearchIndexError: underlyingError: \(error.localizedDescription)"
    }
  }

}

public final class DocsetSearchIndex: Sendable, CustomStringConvertible, LoggerProvider {

  public var description: String {
    return "DocsetSearchIndex(identifier: \(identifier))"
  }

  public enum Status: Equatable {
    case uninitialized
    case indexing(progress: Double?)
    case ready
    case error(_: SearchServiceError)
  }

  let status = BehaviorRelay<Status>(value: .uninitialized)
  public let statusDriver: Driver<Status>

  let docsetPath: String
  let identifier: String

  let indexDBQueue: DatabaseQueue?

  private let indexDBPath: String

  convenience init(docset: Docset) async {
    await self.init(docsetPath: docset.path, identifier: docset.identifier)
  }

  init(docsetPath: String, identifier: String) async {
    self.docsetPath = docsetPath
    self.identifier = identifier

    statusDriver = status.asDriverOnErrorJustIgnore()

    indexDBPath = docsetPath.appendingPathComponent("Contents/Resources/docSet.dsidx")

    do {
      indexDBQueue = try DatabaseQueue(path: indexDBPath)
    } catch {
      indexDBQueue = nil
      Self.logger.error("searchIndex: \(self) failed to initialize database queue with error: \(error)")
    }

    if let error = await checkSearchIndexValid() {
      status.accept(.error(SearchServiceError(underlyingError: error)))
    } else {
      status.accept(.ready)
    }
  }

  public func fetchTypeList() async throws -> [TypeCountPair] {
    guard let dbQueue = indexDBQueue else {
      throw DocsetSearchIndexError.noDatabaseQueue
    }
    return try await DocsetSearcher.typeList(forIndexDBQueue: dbQueue)
  }

  public func fetchAllEntries(forType type: EntryType?) async throws -> [Entry] {
    guard let dbQueue = indexDBQueue else {
      throw DocsetSearchIndexError.noDatabaseQueue
    }
    return try await DocsetSearcher.allEntries(forIndexDBQueue: dbQueue, type: type)
  }

  public func fetchEntries(forQuery rawQuery: String, type: EntryType?) async throws -> [Entry] {
    guard let dbQueue = indexDBQueue else {
      throw DocsetSearchIndexError.noDatabaseQueue
    }
    return try await DocsetSearcher.entries(forIndexDBQueue: dbQueue, rawQuery: rawQuery, type: type)
  }

  private func checkSearchIndexValid() async -> DocsetSearchIndexError? {
    return await withCheckedContinuation { continuation in
      let dbPath = indexDBPath
      do {
        guard let dbQueue = indexDBQueue else {
          return continuation.resume(returning: .noDatabaseQueue)
        }
        try dbQueue.read { db in
          if !(try db.tableExists("searchindex")) {
            Self.logger.error("search index invalid, path: \(dbPath), search index table not exist")
            return continuation.resume(returning: .noSearchIndex)
          }
          if !(try db.tableExists("queryindex")) {
            Self.logger.error("search index invalid, path: \(dbPath), query index table not exist")
            return continuation.resume(returning: .noQueryIndex)
          }
          return continuation.resume(returning: nil)
        }
      } catch {
        Self.logger.error("search index invalid for path: \(dbPath), error: \(error)")
        return continuation.resume(returning: .underlyingError(error))
      }
    }
  }

}
