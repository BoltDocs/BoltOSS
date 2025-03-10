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

import Factory
import GRDB
import Overture

import BoltCombineExtensions
import BoltDatabase
import BoltTypes
import BoltUtils

struct DocsetInstaller: LoggerProvider {

  static let shared = Self()

  func installDocset(
    forEntry entry: FeedEntry,
    usingTarix: Bool
  ) -> AnyPublisher<InstallationProgress, Error> {
    let uuid = UUID()
    let path = LocalFileSystem.docsetsAbsolutePath.appendingPathComponent(uuid.uuidString)
    return Publishers.Create<InstallationProgress, Error> { subscriber -> Cancellable in
      DocsetUnarchiver.unarchiveDownloadedDocset(toPath: path, forFeedEntry: entry, usingTarix: usingTarix, removeSourceFiles: true)
        // swiftlint:disable:next trailing_closure
        .handleEvents(receiveOutput: { progress in
          if case let .progress(progress) = progress {
            subscriber.send(.extracting(progress: progress))
          }
        })
        .compactMap { progress -> String? in
          if case let .completed(path) = progress {
            return path
          }
          return nil
        }
        .tryMap { docsetPath in
          do {
            try Self.removeWALFiles(forDocsetPath: docsetPath)
          } catch {
            Self.logger.error("DocsetInstaller: removeWALFiles failed with error: \(error)")
          }
          try LibraryDocsetsFileSystemBridge.writeMetadata(
            ofEntry: entry,
            toDocsetPath: docsetPath
          )
          let docsetInstallation = DocsetInstallation(
            uuid: uuid,
            name: entry.feed.id,
            version: entry.version,
            installedAsLatestVersion: entry.isTrackedAsLatest,
            repository: entry.feed.repository
          )
          try LibraryDatabase.shared.insertDocsetInstallation(docsetInstallation)
        }
        .sink(receiveCompletion: { completion in
          switch completion {
          case .finished:
            subscriber.send(completion: .finished)
          case let .failure(error):
            subscriber.send(completion: .failure(error))
          }
        }, receiveValue: { _ in })
    }
    .eraseToAnyPublisher()
  }

  private static func removeWALFiles(forDocsetPath docsetPath: String) throws {
    let resourcesPath = docsetPath.appendingPathComponent("Contents/Resources")

    let indexDBPath = resourcesPath.appendingPathComponent("docSet.dsidx")
    let walPath = resourcesPath.appendingPathComponent("docSet.dsidx-wal")
    let shmPath = resourcesPath.appendingPathComponent("docSet.dsidx-shm")

    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: walPath) || fileManager.fileExists(atPath: shmPath) else {
      return
    }

    // swiftlint:disable:next redundant_void_return
    try { () -> Void in
      let configuration = update(Configuration()) {
        $0.journalMode = .wal
      }
      let _ = try DatabaseQueue(
        path: indexDBPath,
        configuration: configuration
      )
    }()

    try fileManager.removeItem(atPath: walPath)
    try fileManager.removeItem(atPath: shmPath)
  }

}
