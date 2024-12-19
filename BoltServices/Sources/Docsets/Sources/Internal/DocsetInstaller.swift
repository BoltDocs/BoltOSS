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
      DocsetUnarchiver.unarchiveDownloadedDocset(toPath: path, forFeedEntry: entry, usingTarix: usingTarix)
        // swiftlint:disable:next trailing_closure
        .handleEvents(receiveOutput: { progress in
          if case let .progress(progress) = progress {
            subscriber.send(.extracting(progress: progress))
          }
        })
        .filter { $0.isCompleted } //.take(1)
        .map { progress -> String in
          switch progress {
          case .completed(let path):
            return path
          default:
            fatalError("Should be completed")
          }
        }
        // override metadata
        .flatMap { docsetPath -> AnyPublisher<Void, Error> in
          Deferred { Future<Void, Error> { promise in
            do {
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
            } catch {
              promise(.failure(error))
            }
            promise(.success(()))
            // swiftlint:disable:next closure_end_indentation
          } }
          .eraseToAnyPublisher()
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

// .flatMap { docsetPath in
//   // create search index
//   return DocsetIndexer.createSearchIndex(forAbsoluteDocsetPath: docsetPath)
//     .handleEvents(receiveOutput: { progress in
//       subscriber.send(.indexing(progress: 0.2 * progress.progress))
//     })
//     .filter { $0.completed }
//     // create full-text query index
//     .flatMap { _ in
//       return DocsetIndexer.createQueryIndex(forAbsoluteDocsetPath: docsetPath)
//     }
//     .handleEvents(receiveOutput: { progress in
//       subscriber.send(.indexing(progress: 0.2 + 0.8 * progress.progress))
//     })
//     .filter { $0.completed }
// }
