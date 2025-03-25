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

import Dispatch
import Factory
import GRDB
import Overture

import BoltUtils

final actor DocsetIndexer: LoggerProvider {

  private var indexerQueue = [DocsetSearchIndex]()

  private let dispatchQueue = DispatchQueue(
    label: "app.BoltDocs.Bolt.DocsetIndexer",
    qos: .userInitiated,
    attributes: [.concurrent]
  )

  private var maxConcurrentTasks: Int

  private let semaphore: DispatchSemaphore

  init(maxConcurrentTasks: Int) {
    self.maxConcurrentTasks = maxConcurrentTasks
    semaphore = DispatchSemaphore(value: maxConcurrentTasks)
  }

  func addSearchIndexToQueue(_ index: DocsetSearchIndex) {
    indexerQueue.append(index)
    Self.logger.info("added searchIndex: \(index) to indexer queue, queue size: \(self.indexerQueue.count)")
    indexNextDocset()
  }

  private func indexNextDocset() {
    dispatchQueue.async { [weak self] in
      guard let self = self else {
        return
      }
      semaphore.wait()
      Task {
        guard let index = await self.popFirstIndex() else {
          self.semaphore.signal()
          return
        }

        guard Self.canCreateSearchIndex(for: index) else {
          Self.logger.error("ignoring searchIndex: \(index): already initialized")
          self.semaphore.signal()
          await self.indexNextDocset()
          return
        }

        await Self.performIndex(forSearchIndex: index)
        self.semaphore.signal()
        await self.indexNextDocset()
      }
    }
  }

  private func popFirstIndex() -> DocsetSearchIndex? {
    guard !indexerQueue.isEmpty else {
      return nil
    }
    return indexerQueue.remove(at: 0)
  }

  private static func canCreateSearchIndex(for index: DocsetSearchIndex) -> Bool {
    switch index.status.value {
    case .uninitialized:
      return true
    case .error:
      return true
    default:
      return false
    }
  }

  private static func performIndex(forSearchIndex index: DocsetSearchIndex) async {
    Self.logger.info("start indexing for searchIndex: \(index)")
    guard let databaseQueue = index.indexDBQueue else {
      Self.logger.error("nil databaseQueue for searchIndex: \(index)")
      return
    }
    do {
      index.status.accept(.indexing(progress: nil))

      try await databaseQueue.erase()

      try await databaseQueue.write { db in
        try IndexDatabase.createIndexInfoTable(db: db)
      }

      try await {
        let dsIdxPath = index.docsetPath.appendingPathComponent("Contents/Resources/docSet.dsidx")
        let dsIdxQueue = try DatabaseQueue(path: dsIdxPath)

        for try await progress in DocsetIndexerWorker.createSearchIndex(
          withDatabaseQueue: databaseQueue,
          dsIndexQueue: dsIdxQueue
        ) {
          Self.logger.debug("indexing - createSearchIndex: \(index), progress: \(progress)")
          index.status.accept(.indexing(progress: 0.2 * progress))
        }
        for try await progress in DocsetIndexerWorker.createQueryIndex(withDatabaseQueue: databaseQueue) {
          Self.logger.debug("indexing - createQueryIndex: \(index), progress: \(progress)")
          index.status.accept(.indexing(progress: 0.2 + 0.8 * progress))
        }
      }()

      try await databaseQueue.write { db in
        try IndexMetadata(version: DocsetSearchIndex.Versions.current).save(db)
      }

      Self.logger.info("indexing finished: \(index)")

      index.status.accept(.ready)
    } catch {
      Self.logger.error("indexing failed: \(index), error: \(error)")
      index.status.accept(.error(SearchServiceError(underlyingError: error)))
    }
  }

}
