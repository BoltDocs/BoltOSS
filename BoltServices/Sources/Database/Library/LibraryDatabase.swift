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
import Foundation

import GRDB

import BoltCombineExtensions
import BoltTypes
import BoltUtils

public final class LibraryDatabase: LoggerProvider {

  public static var shared = LibraryDatabase()

  let dbPool: DatabasePool

  private init() {
    do {
      var configuration = Configuration()
      #if DEBUG
      configuration.prepareDatabase { db in
        db.trace { Self.logger.trace("\($0)") }
      }
      #endif
      let path: String
      if RuntimeEnvironment.isRunningTests {
        path = NSTemporaryDirectory().appendingPathComponent("bolt-library-\(UUID().uuidString).db")
      } else {
        path = LocalFileSystem.libraryDatabaseURL.absoluteString
      }
      dbPool = try DatabasePool(
        path: path,
        configuration: configuration
      )
      try createTableIfNeeded()
    } catch {
      fatalError("Failed to init database with error: \(error.localizedDescription)")
    }
  }

  private func createTableIfNeeded() throws {
    try dbPool.write { db in
      try createInstallationTable(db)
      try createCustomFeedsTable(db)
      try createDownloadTaskTable(db)
    }
  }

  // TODO: Check if we really need `.immediate` here

  public lazy var allDocsetInstallations: AnyPublisher<[DocsetInstallation], Never> = ValueObservation
    .trackingConstantRegion(DocsetInstallation.fetchAll)
    .publisher(in: dbPool, scheduling: .immediate)
    // swiftlint:disable:next trailing_closure
    .handleEvents(receiveCompletion: { completion in
      if case let .failure(error) = completion {
        Self.logger.error("allDocsetInstallations: receiveError: \(error.localizedDescription)")
      }
    })
    .share(replay: 1)
    .ignoreFailure()

  public lazy var allCustomFeeds: AnyPublisher<[CustomFeedEntity], Never> = ValueObservation
    .trackingConstantRegion(CustomFeedEntity.fetchAll)
    .publisher(in: dbPool, scheduling: .immediate)
    // swiftlint:disable:next trailing_closure
    .handleEvents(receiveCompletion: { completion in
      if case let .failure(error) = completion {
        Self.logger.error("allCustomFeeds: receiveError: \(error.localizedDescription)")
      }
    })
    .share(replay: 1)
    .ignoreFailure()

  public lazy var allDownloadTasks: AnyPublisher<[DownloadTaskEntity], Never> = ValueObservation
    .trackingConstantRegion(DownloadTaskEntity.fetchAll)
    .publisher(in: dbPool, scheduling: .immediate)
    // swiftlint:disable:next trailing_closure
    .handleEvents(receiveCompletion: { completion in
      if case let .failure(error) = completion {
      Self.logger.error("allDownloadTasks: receiveError: \(error.localizedDescription)")
      }
    })
    .share(replay: 1)
    .ignoreFailure()

}
