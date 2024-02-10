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

import Foundation

import GRDB

import BoltTypes

public struct TypeCountPair: Codable, FetchableRecord {

  public var type: EntryType? {
    return EntryType.type(forNameOrAlias: typeName)
  }

  public let typeName: String
  public let count: Int

  public enum CodingKeys: String, CodingKey {
    case typeName = "type"
    case count
  }

}

public extension TypeCountPair {

  static func fetchPairs() -> SQLRequest<TypeCountPair> {
    let whenLiterals = EntryType.typeDict.flatMap { _, type -> [SQL] in
      var res = [SQL]()
      res.append(SQL("WHEN \(type.singular) THEN \(type.sortingOrder)"))
      res.append(contentsOf: type.aliases.map { alias in
        return SQL("WHEN \(alias) THEN \(type.sortingOrder)")
      })
      return res
    }
    .joined(separator: " ")
    // swiftlint:disable indentation_width
    let queryLiteral: SQL = """
                            SELECT type,
                                   COUNT(type) AS 'count',
                                   CASE type
                                   \(literal: whenLiterals)
                                   END AS type_index
                            FROM searchindex
                            GROUP BY type_index
                            ORDER BY type_index;
                            """
    // swiftlint:enable indentation_width
    return SQLRequest<TypeCountPair>(literal: queryLiteral)
  }

}
