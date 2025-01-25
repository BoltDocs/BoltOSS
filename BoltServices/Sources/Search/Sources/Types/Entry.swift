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

import GRDB

import BoltTypes

public struct Entry: Codable, TableRecord {

  public let typeName: String
  public let name: String
  public let path: String

  public enum CodingKeys: String, CodingKey {
    case typeName = "type"
    case name = "name"
    case path = "path"
  }

  public var type: EntryType? {
    return EntryType.type(forNameOrAlias: typeName)
  }

  public init(typeName: String, name: String, path: String) {
    self.typeName = typeName
    self.name = name
    self.path = path
  }

}
