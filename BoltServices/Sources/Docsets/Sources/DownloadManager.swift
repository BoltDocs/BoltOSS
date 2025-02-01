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

import BoltDatabase
import BoltNetworking
import BoltRepository
import BoltTypes
import BoltUtils

public enum DownloadProgress {
  case pending
  case downloading(receivedBytes: Int64, expectedBytes: Int64)
  case completed
  case failed(_: Error)
}

public protocol DownloadManager {

  func setBackgroundDownloadCompletionHandler(_: (() -> Void)?)

  func downloadTarix(forFeedEntry entry: FeedEntry) async throws

  func getDocsetByteSize(forFeedEntry entry: FeedEntry) async throws -> Int64?

  @discardableResult
  func downloadDocset(forFeedEntry entry: FeedEntry, force: Bool) async -> Bool

  func cancelDownload(forIdentifier id: String) async

  func cancelAllTasks() async

  func clearCache() async

  func allTasks() -> AnyPublisher<[DownloadTaskEntity], Never>

  func progress(forIdentifier identifier: String) -> AnyPublisher<DownloadProgress?, Never>

  func feedEntry(forDownloadTaskEntity downloadTaskEntity: DownloadTaskEntity) async throws -> FeedEntry?

}

public extension DownloadManager {

  @discardableResult
  func downloadDocset(forFeedEntry entry: FeedEntry, force: Bool = false) async -> Bool {
    return await downloadDocset(forFeedEntry: entry, force: force)
  }

}

public extension Container {

  var downloadManager: Factory<DownloadManager> { self { DownloadManagerImp() }.cached }

}

final class DownloadManagerImp: DownloadManager, LoggerProvider {

  @Injected(\.feedsService)
  private var feedsService: FeedsService

  typealias IdentifierMap = [String: BackgroundDownloader.SessionTaskIdentifier]

  private var taskIdentifierMap = Atomic<IdentifierMap>([:])

  private var taskEntities = CurrentValueSubject<[DownloadTaskEntity], Never>([])

  private var cancellables = Set<AnyCancellable>()

  func setBackgroundDownloadCompletionHandler(_ handler: (() -> Void)?) {
    backgroundDownloader.backgroundDownloadCompletionHandler = handler
  }

  @Injected(\.networking)
  private var networking: Networking

  @Injected(\.resourceLocationResolvers)
  private var resourceLocationResolvers: ResourceLocationResolvers

  private lazy var backgroundDownloader: BackgroundDownloader = {
    return BackgroundDownloader(dataSource: self)
  }()

  init() {
    LibraryDatabase.shared.allDownloadTasks
      .assign(to: \.value, on: taskEntities)
      .store(in: &cancellables)

    if let tasks: [DownloadTaskEntity] = try? LibraryDatabase.shared.fetchAllDownloadTasks() {
      taskIdentifierMap.value = Dictionary(
        uniqueKeysWithValues: tasks
          .filter { $0.isDownloading }
          .map { ($0.identifier, $0.taskIdentifier!) }
      )
    } else {
      Self.logger.error("Failed to fetch all download tasks.")
    }

    let _ = backgroundDownloader
  }

  // MARK: - Interfaces

  func downloadTarix(forFeedEntry entry: FeedEntry) async throws {
    let path = entry.downloadAbsolutePath(withExtension: "tgz.tarix")
    if !FileManager.default.fileExists(atPath: path) {
      try await networking.downloadFile(atLocation: entry.tarixLocation, toPath: path)
    }
  }

  func getDocsetByteSize(forFeedEntry entry: FeedEntry) async throws -> Int64? {
    return try await networking.getFileSize(atLocation: entry.docsetLocation)
  }

  @discardableResult
  func downloadDocset(forFeedEntry entry: FeedEntry, force: Bool = false) async -> Bool {
    let location = entry.docsetLocation
    guard let downloadURL = resourceLocationResolvers.url(forResourceLocation: location) else {
      return false
    }

    let id = entry.id

    if taskIdentifierMap.value[id] != nil {
      if force {
        await cancelDownload(forIdentifier: id)
      } else {
        return false
      }
    }

    guard let sessionIdentifier = backgroundDownloader.startDownload(url: downloadURL) else {
      return false
    }

    // FIXME: 写成功再下载

    // async-await
    do {
      try LibraryDatabase.shared.insertDownloadTask(
        DownloadTaskEntity(
          name: entry.feed.id,
          displayName: entry.feed.displayName,
          version: entry.version,
          installedAsLatestVersion: entry.isTrackedAsLatest,
          repository: entry.feed.repository,
          status: .downloading(taskIdentifier: String(sessionIdentifier))
        )
      )
      taskIdentifierMap.synced {
        $0[id] = sessionIdentifier
      }
    } catch {
      Self.logger.error("Failed to write download task to database with error: \(error.localizedDescription).")
    }

    return true
  }

  func cancelDownload(forIdentifier id: String) async {
    if let sessionID = taskIdentifierMap.value[id] {
      await backgroundDownloader.cancelDownload(forSessionID: sessionID)
    } else {
      removeTask(forIdentifier: id)
    }
  }

  func cancelAllTasks() async {
    await backgroundDownloader.stopAllTasks()
  }

  func clearCache() async {
    await backgroundDownloader.clearCache()
  }

  func allTasks() -> AnyPublisher<[DownloadTaskEntity], Never> {
    return taskEntities.eraseToAnyPublisher()
  }

  func progress(forIdentifier identifier: String) -> AnyPublisher<DownloadProgress?, Never> {
    return taskEntities.flatMapLatest { [weak self] entities -> AnyPublisher<DownloadProgress?, Never> in
      guard let self = self, let sessionID = self.taskIdentifierMap.value[identifier] else {
        return Just<DownloadProgress?>(nil)
          .eraseToAnyPublisher()
      }
      return self.backgroundDownloader.progress(forSessionID: sessionID)
        .map { progress -> DownloadProgress? in
          switch progress {
          case .pending:
            return .pending
          case let .downloading(receivedBytes, expectedBytes):
            return .downloading(receivedBytes: receivedBytes, expectedBytes: expectedBytes)
          case let .failed(error):
            return .failed(error)
          case .none:
            if entities.contains(where: { $0.identifier == identifier }) {
              return .completed
            }
          }
          return nil
        }
        .eraseToAnyPublisher()
    }
    .share(replay: 1)
    .receive(on: DispatchQueue.main)
    .eraseToAnyPublisher()
  }

  func feedEntry(forDownloadTaskEntity downloadTaskEntity: DownloadTaskEntity) async throws -> FeedEntry? {
    let allFeeds = try await feedsService.fetchAllFeeds(
      forRepository: downloadTaskEntity.repository,
      forceUpdate: false
    )
    for feed in allFeeds where feed.id == downloadTaskEntity.name {
      let entries = try await feed.fetchEntries()
      for entry in entries where entry.id == downloadTaskEntity.identifier {
        return entry as FeedEntry
      }
    }
    return nil
  }

  // MARK: - Private

  private func removeTask(forIdentifier id: String) {
    do {
      try LibraryDatabase.shared.deleteDownloadTask(forIdentifier: id)
      taskIdentifierMap.synced { identifierMap in
        identifierMap.removeValue(forKey: id)
      }
    } catch {
      Self.logger.error("Failed to delete orphan tasks, error: \(error.localizedDescription).")
    }
  }

}

extension DownloadManagerImp: BackgroundDownloaderProgressDelegate {

  func downloaderDidUpdateSessionIDs(sessionIDs: [BackgroundDownloader.SessionTaskIdentifier]) {
    do {
      try LibraryDatabase.shared.deleteIncompleteDownloadTask(keepBackingTaskIDs: sessionIDs.map { String($0) })
      taskIdentifierMap.synced { identifierMap in
        identifierMap = identifierMap.filter { sessionIDs.contains($0.value) }
      }
    } catch {
      Self.logger.error("Failed to delete orphan tasks, error: \(error.localizedDescription).")
    }
  }

  func downloaderDidFinishDownload(forSessionID sessionID: BackgroundDownloader.SessionTaskIdentifier) {
    do {
      try LibraryDatabase.shared.updateDownloadMarkComplete(forBackingTaskID: String(sessionID))
      taskIdentifierMap.synced { identifierMap in
        identifierMap = identifierMap.filter { $0.value != sessionID }
      }
    } catch {
      Self.logger.error("Failed to update download task identifier, error: \(error.localizedDescription).")
    }
  }

  func downloaderRemoveTask(forSessionID sessionID: BackgroundDownloader.SessionTaskIdentifier) {
    do {
      try LibraryDatabase.shared.deleteDownloadTask(forBackingTaskID: String(sessionID))
      taskIdentifierMap.synced { identifierMap in
        identifierMap = identifierMap.filter { $0.value != sessionID }
      }
    } catch {
      Self.logger.error("Failed to delete task for sessionID: \(sessionID), error: \(error.localizedDescription).")
    }
  }

  func downloaderRemoveAllTasks() {
    do {
      try LibraryDatabase.shared.deleteAllOngoingTasks()
      taskIdentifierMap.value = [:]
    } catch {
      Self.logger.error("Failed to delete all ongoing tasks, error: \(error.localizedDescription).")
    }
  }

  func downloaderGetDestinationPath(forSessionID sessionID: BoltDocsets.BackgroundDownloader.SessionTaskIdentifier) -> String? {
    guard let taskIdentifier = taskIdentifierMap.value.first(where: { $0.value == sessionID })?.key else {
      return nil
    }
    return FeedEntry.downloadAbsolutePath(forId: taskIdentifier, withExtension: "tgz")
  }

}
