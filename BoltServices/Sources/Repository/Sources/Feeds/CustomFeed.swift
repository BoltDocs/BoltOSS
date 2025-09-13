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

import Foundation

import Factory

import BoltDatabase
import BoltTypes
import BoltUtils

struct CustomFeedRepository: FeedRepository {

  var identifier: RepositoryIdentifier = .custom

  var isPreset = false

  var canFetchFeeds = false

  var shouldCacheFeeds = false

  // swiftlint:disable:next unavailable_function
  func fetchFeeds() throws -> [Feed] {
    fatalError("fetchFeeds() not implemented.")
  }

}

public struct CustomFeed: Feed, Identifiable, Equatable {

  private(set) var customFeedEntity: CustomFeedEntity

  public init(entity: CustomFeedEntity) {
    customFeedEntity = entity
  }

  // MARK: - Feed

  public let repository = RepositoryIdentifier.custom

  public var id: String {
    return customFeedEntity.uuid.uuidString
  }

  public var displayName: String {
    get {
      return customFeedEntity.displayName
    } set {
      customFeedEntity.displayName = newValue
    }
  }

  public var aliases = [String]()

  public var shouldHideVersions = false
  public var supportsArchiveIndex = false

  public var icon = EntryIcon.providerDefault

  public var isUnavailable = false
  public var unavailableMessage: String?

  public func fetchEntries() async throws -> FeedEntries {
    return try await Container.shared.feedsService().asInternal().fetchEntries(forCustomFeed: self)
  }

  // MARK: - Equatable

  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.customFeedEntity == rhs.customFeedEntity
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

  // MARK: - Properties

  public var urlString: String {
    return customFeedEntity.urlString
  }

}
