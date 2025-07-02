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

import SwiftyJSON

import BoltTypesAssets
import BoltUtils

public struct EntryType: Equatable, LoggerProvider {

  public let singular: String
  public let plural: String
  public let aliases: [String]
  public let colorResource: BoltColorResource
  public let imageName: String
  public let sortingOrder: Int

  public var keys: [String] {
    return aliases + [singular]
  }

  public init(singular: String, plural: String, sortingOrder: Int, aliases: [String], imageName: String? = nil, colorResource: BoltColorResource) {
    self.singular = singular
    self.plural = plural
    self.sortingOrder = sortingOrder
    self.aliases = aliases
    self.imageName = imageName ?? singular
    self.colorResource = colorResource
  }

  public static let unknown: EntryType = {
    return Self(
      singular: "Unknown",
      plural: "Unknown",
      sortingOrder: 0,
      aliases: [],
      imageName: "type-icons/Unknown",
      colorResource: BoltColorResource(named: "type-colors/dark-black", in: BLTTypes.assetsBundle)
    )
  }()

  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.singular == rhs.singular
  }

}

public extension EntryType {

  static func type(forNameOrAlias name: String) -> EntryType? {
    if let type = typeDict[name] {
      return type
    } else {
      for (_, type) in typeDict where type.aliases.contains(name) {
        return type
      }
    }
    return nil
  }

}

extension EntryType: EntryIconProvider {

  public var icon: EntryIcon {
    return .bundled(.name("type-icons/\(imageName)"))
  }

  public static var defaultIconImage = EntryIcon.bundled(.name("type-icons/Unknown")).platformImage!

}

extension EntryType {

  static func log_warnForInvalidJSON(key: String) {
    Self.logger.warning("Unable to init `\(String(describing: self))` from JSON, deserialization of key: `\(key)` failed.")
  }

}
