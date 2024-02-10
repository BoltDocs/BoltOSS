//
// Copyright (C) 2023 Bolt Contributors
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

import GRDB

public struct TarIndex: Codable, FetchableRecord, TableRecord {

  public var path: String
  public var hash: String

  enum CodingKeys: String, CodingKey {
    case path, hash
  }

  public var blockLength: Int? {
    let parts = hash.split(separator: " ")
    return parts.count == 3 ? Int(parts[2]) : nil
  }

  public var offset: UInt64? {
    let parts = hash.split(separator: " ")
    return parts.count == 3 ? UInt64(parts[1]) : nil
  }

}
