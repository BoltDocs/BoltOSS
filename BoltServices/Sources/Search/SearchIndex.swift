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

package struct SearchIndex: Codable, FetchableRecord, PersistableRecord {

  package static var databaseTableName: String {
    return "searchindex"
  }

  package var id: Int64?
  package var name: String
  package var type: String
  package var path: String

  static let queryIndex = belongsTo(QueryIndex.self, using: ForeignKey(["id"], to: ["search_id"]))

  package init(id: Int64?, name: String, type: String, path: String) {
    self.id = id
    self.name = name
    self.type = type
    self.path = path
  }

  package var generatedQueryIndex: QueryIndex? {
    guard let id = id else {
      return nil
    }
    return QueryIndex(searchId: id, perfect: name.makeQueryPerfect(), prefix: name.makeQueryPrefix(), suffixesString: name.makeQuerySuffixesString())
  }

}

// FIXME: errors should not be directly thrown here
package extension SearchIndex {

  static func fetchAll(type: EntryType?) throws -> QueryInterfaceRequest<SearchIndex> {
    var request = Self.all()

    if let type = type {
      request = request.filter(type.keys.contains(Column("type")))
    }

    return request
  }

  static func fetchPerfectMatch(rawQuery: String, type: EntryType?) throws -> QueryInterfaceRequest<SearchIndex> {
    let query = rawQuery.makeQueryPerfect()

    var request = Self.joining(required: Self.queryIndex
      .filter(Column("perfect").match(try FTS3Pattern(rawPattern: "\"\(query)\""))))

    if let type = type {
      request = request.filter(type.keys.contains(Column("type")))
    }

    return request.limit(50)
  }

  static func fetchPrefixMatch(rawQuery: String, type: EntryType?) throws -> QueryInterfaceRequest<SearchIndex> {
    let query = rawQuery.makeQueryPerfect()

    var request = Self.all()

    if !query.isEmpty {
      request = request.joining(
        required: Self.queryIndex
          .filter(
            Column("prefix")
              .match(try FTS3Pattern(rawPattern: "\"\(query)*\""))
          )
      )
    }

    if let type = type {
      request = request.filter(type.keys.contains(Column("type")))
    }

    return request.limit(50)
  }

  static func fetchSuffixMatch(rawQuery: String, type: EntryType?) throws -> QueryInterfaceRequest<SearchIndex> {
    let query = rawQuery.makeQueryPerfect()

    var request = Self.all()

    if !query.isEmpty {
      request = request.joining(
        required: Self.queryIndex
          .filter(
            Column("suffixes")
              .match(try FTS3Pattern(rawPattern: "\"\(query)\""))
          )
      )
    }

    if let type = type {
      request = request.filter(type.keys.contains(Column("type")))
    }

    return request.limit(50)
  }

  static func fetchMiddleMatch(rawQuery: String, type: EntryType?) throws -> QueryInterfaceRequest<SearchIndex> {
    let query = rawQuery.makeQueryPerfect()

    var request = Self.all()

    if !query.isEmpty {
      request = request.joining(
        required: Self.queryIndex
          .filter(
            Column("suffixes")
              .match(try FTS3Pattern(rawPattern: "\"\(query)*\""))
          )
      )
    }

    if let type = type {
      request = request.filter(type.keys.contains(Column("type")))
    }

    return request.limit(50)
  }

}
