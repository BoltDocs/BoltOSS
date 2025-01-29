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

#if DEBUG

import BoltUtils

public struct StubFeed: Feed {

  public var repository: RepositoryIdentifier

  public var id: String
  public var displayName: String
  public var aliases: [String]

  public var shouldHideVersions: Bool
  public var supportsArchiveIndex: Bool

  public var icon: EntryIcon

  public var isUnavailable = false
  public var unavailableMessage: String?

  public func fetchEntries() throws -> [BoltTypes.FeedEntry] {
    return []
  }

  public static var defaultIconImage: PlatformImage {
    return PlatformImage()
  }

  public init(
    repository: RepositoryIdentifier,
    id: String,
    displayName: String,
    aliases: [String],
    shouldHideVersions: Bool,
    supportsArchiveIndex: Bool,
    icon: EntryIcon,
    isUnavailable: Bool = false,
    unavailableMessage: String? = nil
  ) {
    self.repository = repository
    self.id = id
    self.displayName = displayName
    self.aliases = aliases
    self.shouldHideVersions = shouldHideVersions
    self.supportsArchiveIndex = supportsArchiveIndex
    self.icon = icon
    self.isUnavailable = isUnavailable
    self.unavailableMessage = unavailableMessage
  }

}

#endif
