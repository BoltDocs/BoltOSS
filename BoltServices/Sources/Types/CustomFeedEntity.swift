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

public struct CustomFeedEntity: Codable, Hashable {

  public var displayName: String
  public var urlString: String

  public let uuid: UUID

  public init(name: String, urlString: String) {
    self.uuid = UUID()
    self.displayName = name
    self.urlString = urlString
  }

  public enum CodingKeys: String, CodingKey {
    case uuid = "uuid"
    case displayName = "name"
    case urlString = "url"
  }

  public static var databaseTableName: String {
    return "custom-feeds"
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.uuid == rhs.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

}
