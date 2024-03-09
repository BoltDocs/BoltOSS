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

import CombineExt
import Factory

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

  func fetchAllFeeds(forRepository repositoryIdentifier: RepositoryIdentifier, forceUpdate: Bool) async throws -> [Feed] {
    guard let repository = repositoryRegistry.repository(forIdentifier: repositoryIdentifier) else {
      assertionFailure("Unhandled repository type: \(repositoryIdentifier)")
      return []
    }

    if repository.canFetchFeeds {
      if !forceUpdate, let cachedFeeds = feedsCaches[repositoryIdentifier] {
        return cachedFeeds
      }
      let feeds = try await repository.fetchFeeds()
      if repository.shouldCacheFeeds {
        feedsCaches[repositoryIdentifier] = feeds
      }
      return feeds
    } else {
      guard repository is CustomFeedRepository else {
        assertionFailure("Unhandled repository: \(repository), identifier: \(repositoryIdentifier)")
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

  func deleteCustomFeeds(_ feed: CustomFeed) throws {
    try LibraryDatabase.shared.deleteCustomFeed(feed.customFeedEntity)
  }

  func fetchEntries(forCustomFeed feed: CustomFeed) async throws -> [FeedEntry] {
    let xml = try await networking.fetchEntries(atURL: feed.urlString)
    let entryElement = xml["entry"]

    guard let version = entryElement["version"].text else {
      return []
    }

    let accessor = entryElement["url"]

    let resolveURL = { () -> URL? in
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
      return []
    }

    let latest = FeedEntry(
      feed: feed,
      version: version,
      isTrackedAsLatest: false,
      isDocsetBundle: false,
      docsetLocation: ResourceLocations.URL(url)
    )
    return [latest]
  }

}
