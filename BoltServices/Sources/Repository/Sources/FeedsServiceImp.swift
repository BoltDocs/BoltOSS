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
import IssueReporting
import SwiftyXMLParser

import BoltCombineExtensions
import BoltDatabase
import BoltNetworking
import BoltTypes
import BoltUtils

final class FeedsServiceImp: FeedsServiceInternal {

  @Injected(\.networking)
  private var networking: Networking

  @Injected(\.repositoryRegistry)
  private var repositoryRegistry: RepositoryRegistry

  private var feedsCaches = [RepositoryIdentifier: [Feed]]()

  private var customFeedsRelay = CurrentValueSubject<[CustomFeed], Never>([])

  private var cancellableBag = Set<AnyCancellable>()

  init() {
    // - SeeAlso: https://github.com/groue/GRDB.swift/pull/1248
    LibraryDatabase.shared.allCustomFeeds
      .map { return $0.map { CustomFeed(entity: $0) } }
      .assign(to: \.value, on: customFeedsRelay)
      .store(in: &cancellableBag)
  }

  func fetchAllFeeds(forRepository repositoryIdentifier: RepositoryIdentifier, cacheIfPossible: Bool) async throws(FeedsServiceError) -> [Feed] {
    guard let repository = repositoryRegistry.repository(forIdentifier: repositoryIdentifier) else {
      reportIssue("Unhandled repository type: \(repositoryIdentifier)")
      return []
    }

    if repository.canFetchFeeds {
      if cacheIfPossible, let cachedFeeds = feedsCaches[repositoryIdentifier] {
        return cachedFeeds
      }
      do {
        let feeds = try await repository.fetchFeeds()
        if repository.shouldCacheFeeds {
          feedsCaches[repositoryIdentifier] = feeds
        }
        return feeds
      } catch {
        throw FeedsServiceError(underlyingError: error)
      }
    } else {
      guard repository is CustomFeedRepository else {
        reportIssue("Unhandled repository: \(repository), identifier: \(repositoryIdentifier)")
        return []
      }
      return customFeedsRelay.value
    }
  }

  func customFeedsObservable() -> AnyPublisher<[CustomFeed], Never> {
    return customFeedsRelay.eraseToAnyPublisher()
  }

  func insertCustomFeed(_ feed: CustomFeed) throws {
    try LibraryDatabase.shared.insertCustomFeed(feed.customFeedEntity)
  }

  func updateCustomFeed(_ feed: CustomFeed) throws {
    try LibraryDatabase.shared.updateCustomFeed(feed.customFeedEntity)
  }

  func deleteCustomFeeds(_ feed: CustomFeed) throws {
    try LibraryDatabase.shared.deleteCustomFeed(feed.customFeedEntity)
  }

  func fetchEntries(forCustomFeed feed: CustomFeed) async throws -> FeedEntries {
    let xml = try await networking.fetchEntries(atURL: feed.urlString)
    let entryElement = xml["entry"]

    guard let version = entryElement["version"].text else {
      return FeedEntries()
    }

    let resolveURL = { () -> URL? in
      let accessor = entryElement["url"]
      switch accessor {
      case let .singleElement(element):
        if let urlString = element.text, let url = URL(string: urlString) {
          return url
        }
      case let .sequence(elements):
        return elements.firstMap {
          if let urlString = $0.text, let url = URL(string: urlString) {
            return url
          }
          return nil
        }
      case .failure:
        return nil
      }
      return nil
    }

    guard let url = resolveURL() else {
      return FeedEntries()
    }

    // swiftlint:disable:next discouraged_optional_collection
    let resolveOtherVersions = { () -> [String]? in
      let otherVersions = entryElement["other-versions"]
      // swiftlint:disable:next discouraged_optional_collection
      let buildVersions = { (elements: [XML.Element]) -> [String]? in
        var versions = [String]()
        for element in elements {
          for childElement in element.childElements where childElement.name == "version" {
            for childElement in childElement.childElements where childElement.name == "name" {
              if let text = childElement.text {
                versions.append(text)
              }
            }
          }
        }
        return versions
      }

      switch otherVersions {
      case let .singleElement(element):
        return buildVersions([element])
      case let .sequence(elements):
        return buildVersions(elements)
      case .failure:
        return nil
      }
    }

    let versions = resolveOtherVersions()

    // swiftlint:disable:next discouraged_optional_collection
    let versionsEntry: [FeedEntry]? = versions?.compactMap { version -> FeedEntry? in
      let lastPathComponent = url.lastPathComponent

      guard !lastPathComponent.isEmpty, lastPathComponent != "/" else {
        return nil
      }

      let versionedURL = url.deletingLastPathComponent().appending(
        components: "versions",
        lastPathComponent.deletingPathExtension,
        version,
        lastPathComponent
      )

      return FeedEntry(
        feed: feed,
        version: version,
        isTrackedAsLatest: false,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.URL(versionedURL)
      )
    }

    let latestEntry = FeedEntry(
      feed: feed,
      version: version,
      isTrackedAsLatest: true,
      isDocsetBundle: false,
      docsetLocation: ResourceLocations.URL(url)
    )

    return FeedEntries(
      items: [latestEntry] + (versionsEntry ?? []),
      shouldHideVersions: versionsEntry == nil
    )
  }

}
