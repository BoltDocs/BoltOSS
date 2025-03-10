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

import BoltCombineExtensions
import BoltDatabase
import BoltTypes
import BoltUtils

struct DocsetInstaller {

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

}
