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

import Combine
import Dispatch
import ObjectiveC

import GRDB

import BoltCombineExtensions
import BoltTypes
import BoltUtils

struct DocsetIndexer: LoggerProvider {

  struct Progress {

    let progress: Double
    let completed: Bool

    init(progress: Double, completed: Bool = false) {
      self.progress = progress
      self.completed = completed
    }

  }

  struct ZIndex: Codable, FetchableRecord {

    var name: String?
    var type: String?
    var path: String?
    var anchor: String?

    var searchIndex: SearchIndex? {
      guard
        let name = name,
        let type = type,
        let path = path
      else {
        return nil
      }
      let newPath: String
      if let anchor = anchor {
        newPath = "\(path)#\(anchor)"
      } else {
        newPath = path
      }
      return SearchIndex(id: nil, name: name, type: type, path: newPath)
    }

  }

  private static var indexerQueue = DispatchQueue(
    label: "app.BoltDocs.Bolt.DocsetIndexer",
    qos: .userInitiated,
    attributes: .concurrent
  )

  static func createSearchIndex(forAbsoluteDocsetPath path: String) -> AnyPublisher<Progress, Error> {
    return Publishers.Create<Progress, Error> { subscriber in
      let cancellable = BooleanCancellable()

      let dbPath = path.appendingPathComponent("Contents/Resources/docSet.dsidx")
      indexerQueue.asyncSafe {
        do {
          let dbQueue = try DatabaseQueue(path: dbPath)
          try dbQueue.write { db in
            guard !(try db.tableExists("searchindex")) else {
              return
            }

            Self.logger.info("No searchindex table found, treating as zDash format.")

            try db.create(table: "searchindex", ifNotExists: true) { table in
              table.autoIncrementedPrimaryKey("id")
              table.column("name", .integer)
              table.column("type", .text)
              table.column("path", .text)
            }

            let zCount = try Int.fetchOne(
              db,
              sql:
                """
                SELECT COUNT(*)
                FROM ztoken
                """
            )!

            let zIndices = try ZIndex.fetchCursor(
              db,
              sql:
                """
                SELECT ztokenname AS name,
                  ztypename AS type,
                  zpath AS path,
                  zanchor AS anchor
                FROM ztoken
                INNER JOIN ztokenmetainformation
                  ON ztoken.zmetainformation = ztokenmetainformation.z_pk
                INNER JOIN zfilepath
                  ON ztokenmetainformation.zfile = zfilepath.z_pk
                INNER JOIN ztokentype
                  ON ztoken.ztokentype = ztokentype.z_pk
                """
            )

            var currentCount = 0
            while let zIndex = try zIndices.next() {
              try cancellable.checkCancellation()
              if let searchIndex = zIndex.searchIndex {
                do {
                  try searchIndex.insert(db)
                  currentCount += 1
                  subscriber.send(Progress(progress: Double(currentCount) / Double(zCount)))
                } catch {
                  Self.logger.warning("Unable to insert index: \(String(describing: searchIndex))")
                }
              }
            }
          }
        } catch {
          if error is CombineExtensions.CancellationError {
            return
          }
          subscriber.send(completion: .failure(error))
        }
        subscriber.send(Progress(progress: 1.0, completed: true))
        subscriber.send(completion: .finished)
      }
      return cancellable
    }
    .eraseToAnyPublisher()
  }

  static func createQueryIndex(forAbsoluteDocsetPath path: String) -> AnyPublisher<Progress, Error> {
    return Publishers.Create<Progress, Error> { subscriber in
      let cancellable = BooleanCancellable()

      let dbPath = path.appendingPathComponent("Contents/Resources/docSet.dsidx")
      indexerQueue.asyncSafe {
        do {
          let dbQueue = try DatabaseQueue(path: dbPath)
          try dbQueue.write { db in
            if try db.tableExists("queryindex") {
              try db.drop(table: "queryindex")
            }

            try db.create(virtualTable: "queryindex", using: FTS4()) { table in
              table.column("search_id")
              table.column("perfect")
              table.column("prefix")
              table.column("suffixes")
              table.tokenizer = FTS3TokenizerDescriptor.unicode61(diacritics: .remove, tokenCharacters: ["`"])
            }

            let searchCount = try SearchIndex.fetchCount(db)

            let searchIndices = try SearchIndex.fetchCursor(db)

            var currentCount = 0
            while let searchIndex = try searchIndices.next() {
              try cancellable.checkCancellation()
              if let queryIndex = searchIndex.generatedQueryIndex {
                do {
                  try queryIndex.insert(db)
                  currentCount += 1

                  // TODO: more granular progress reporting
                  if currentCount.isMultiple(of: 100) {
                    subscriber.send(Progress(progress: Double(currentCount) / Double(searchCount)))
                  }
                } catch {
                  Self.logger.warning("Unable to insert query index: \(String(describing: queryIndex))")
                }
              }
            }
          }
        } catch {
          if error is CombineExtensions.CancellationError {
            return
          }
          subscriber.send(completion: .failure(error))
        }
        subscriber.send(Progress(progress: 1.0, completed: true))
        subscriber.send(completion: .finished)
      }
      return cancellable
    }
    .eraseToAnyPublisher()
  }

}
