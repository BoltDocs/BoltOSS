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

import Factory

import BoltRepository
import BoltTypes
import BoltUtils

public extension Container {

  var docsetUpdateChecker: Factory<DocsetUpdateChecker> { self { DocsetUpdateCheckerImp() }.cached }

}

public struct UpdatableEntry {
  public let feedEntry: FeedEntry
}

public protocol DocsetUpdateChecker {

  func fetchDocsetUpdates(useCachedEntries: Bool) async -> [UpdatableEntry]

}

final class DocsetUpdateCheckerImp: DocsetUpdateChecker, LoggerProvider {

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  @Injected(\.feedsService)
  private var feedsService: FeedsService

  // swiftlint:disable:next discouraged_optional_collection
  private var cachedEntriesRelay = Atomic<[UpdatableEntry]?>(nil)

  func fetchDocsetUpdates(useCachedEntries: Bool) async -> [UpdatableEntry] {
    if useCachedEntries {
      return cachedEntriesRelay.value ?? []
    }

    let installedRecords = libraryDocsetsManager.installedRecords

    var repoInstallationMap = [RepositoryIdentifier: [LibraryRecord]]()

    for record in installedRecords {
      guard record.installedAsLatestVersion else {
        continue
      }
      if repoInstallationMap[record.repository] == nil {
        repoInstallationMap[record.repository] = []
      }
      repoInstallationMap[record.repository]?.append(record)
    }

    var updatableEntries = [UpdatableEntry]()

    for (repositoryIdentifier, records) in repoInstallationMap {
      let feeds: [Feed]
      do {
        feeds = try await feedsService.fetchAllFeeds(forRepository: repositoryIdentifier, cacheIfPossible: true)
      } catch {
        Self.logger.error("Failed to fetch feeds for repository: \(repositoryIdentifier.rawValue)")
        continue
      }
      for record in records {
        if let feed = feeds.first(where: { $0.id == record.name }) {
          let entries: FeedEntries
          do {
            entries = try await feed.fetchEntries()
          } catch {
            Self.logger.error("Failed to fetch entries for feed: \(feed.id)")
            continue
          }
          for entry in entries.items where entry.isTrackedAsLatest {
            let latestVersion = entry.version
            if latestVersion != record.version {
              updatableEntries.append(
                UpdatableEntry(feedEntry: entry)
              )
            }
          }
        }
      }
    }

    saveLatestVersions(forUpdatableEntries: updatableEntries, toInstalledRecords: installedRecords)

    cachedEntriesRelay.value = updatableEntries

    return updatableEntries
  }

  private func saveLatestVersions(
    forUpdatableEntries updatableEntries: [UpdatableEntry],
    toInstalledRecords installedRecords: [LibraryRecord]
  ) {
    for record in installedRecords {
      guard record.installedAsLatestVersion else {
        continue
      }
      if let updatableEntry = updatableEntries.first(where: { $0.feedEntry.feed.id == record.name }) {
        do {
          try libraryDocsetsManager.updateDocsetLatestVersion(updatableEntry.feedEntry.version, record: record)
        } catch {
          Self.logger.error("Failed to update latest version for record: \(record.uuid)")
        }
      }
    }
  }

}
