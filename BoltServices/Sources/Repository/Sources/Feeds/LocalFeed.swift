//
// Copyright (C) 2026 Bolt Contributors
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

import Foundation

import Factory

import BoltDatabase
import BoltTypes
import BoltUtils

struct LocalFeedRepository: FeedRepository {

  var identifier: RepositoryIdentifier = .local

  var isPreset = false

  var canFetchFeeds = false

  var shouldCacheFeeds = false

  // swiftlint:disable:next unavailable_function
  func fetchFeeds() throws -> [Feed] {
    fatalError("fetchFeeds() not implemented.")
  }

}

public struct LocalFeed: Feed, Identifiable, Equatable {

  public init(id: String, displayName: String) {
    self.id = id
    self.displayName = displayName
  }

  // MARK: - Feed

  public let repository = RepositoryIdentifier.local

  public var id: String

  public var displayName: String

  public var aliases = [String]()

  public var shouldHideVersions = false
  public var supportsArchiveIndex = false

  public var icon = EntryIcon.providerDefault

  public var isUnavailable = false
  public var unavailableMessage: UnavailableMessage?

  public func fetchEntries() throws -> FeedEntries {
    return FeedEntries()
  }

  // MARK: - Equatable

  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.id == rhs.id
  }

  // MARK: - EntryIconProvider

  public static var defaultIconImage: IdentifiableImage = {
    let symbolName = "books.vertical"
    #if os(iOS)
    return IdentifiableImage(
      image: PlatformImage(
        systemName: symbolName,
        withConfiguration: PlatformImage.SymbolConfiguration(
          pointSize: 16
        )
      )!,
      id: symbolName
    )
    #else
    return IdentifiableImage(
      image: PlatformImage(
        systemSymbolName: symbolName,
        accessibilityDescription: nil
      )!
      .withSymbolConfiguration(
        PlatformImage.SymbolConfiguration(
          pointSize: 16,
          weight: .regular
        )
      )!,
      id: symbolName
    )
    #endif
  }()

}
