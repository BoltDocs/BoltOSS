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

public struct Bookmark: Codable, Hashable {

  public var rowID: Int64?
  public var title: String
  public var path: String
  public var docsetID: String
  public var addedAt: Date
  public var orderIndex: Int

  public enum CodingKeys: String, CodingKey {
    case rowID
    case title
    case path
    case docsetID
    case addedAt
    case orderIndex
  }

  public static var databaseTableName: String {
    "bookmarks"
  }

  public init(title: String, path: String, docsetID: String, addedAt: Date = Date(), orderIndex: Int = 0) {
    self.title = title
    self.path = path
    self.docsetID = docsetID
    self.addedAt = addedAt
    self.orderIndex = orderIndex
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    if lhs.rowID != nil || rhs.rowID != nil {
      return lhs.rowID == rhs.rowID
    }
    return lhs.title == rhs.title &&
      lhs.path == rhs.path &&
      lhs.docsetID == rhs.docsetID &&
      lhs.addedAt == rhs.addedAt &&
      lhs.orderIndex == rhs.orderIndex
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rowID)
    if rowID == nil {
      hasher.combine(title)
      hasher.combine(path)
      hasher.combine(docsetID)
      hasher.combine(addedAt)
      hasher.combine(orderIndex)
    }
  }

}
