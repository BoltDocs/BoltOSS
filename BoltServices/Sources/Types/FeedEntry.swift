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

import BoltUtils

public struct FeedEntry: Identifiable {

  // MARK: - Properties

  public let feed: Feed

  public let version: String
  public let isTrackedAsLatest: Bool
  public let isDocsetBundle: Bool

  public let docsetLocation: ResourceLocation

  public init(
    feed: Feed,
    version: String,
    isTrackedAsLatest: Bool,
    isDocsetBundle: Bool,
    docsetLocation: ResourceLocation
  ) {
    self.feed = feed
    self.version = version
    self.isTrackedAsLatest = isTrackedAsLatest
    self.isDocsetBundle = isDocsetBundle
    self.docsetLocation = docsetLocation
  }

  public var tarixLocation: any ResourceLocation {
    return docsetLocation.appendingPathExtension("tarix")
  }

  public var id: String {
    return InstallationIdentifier.fromName(
      feed.id,
      version: version,
      installedAsLatestVersion: isTrackedAsLatest,
      repository: feed.repository
    )
  }

}
