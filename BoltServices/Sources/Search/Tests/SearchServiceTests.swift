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

import XCTest

import GRDB

@testable import BoltSearch

final class SearchServiceTests: XCTestCase {

  func testTypeListWithAlias() async throws {
    let dbQueue = try DatabaseQueue()
    try await dbQueue.write { db in
      try Self.createSearchIndexTable(db)
      try db.execute(
        sql: """
          INSERT INTO searchindex (name, type, path) VALUES
          ('FunctionA', 'Function', '/docs/functionA'),
          ('FunctionB', 'Function', '/docs/functionB'),
          ('FunctionC', 'func',     '/docs/functionC');
          """
      )
    }

    let result = try await DocsetSearcher.typeList(forIndexDBQueue: dbQueue)
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].count, 3)
  }

  func testTypeListSortingOrder() async throws {
    let dbQueue = try DatabaseQueue()
    try await dbQueue.write { db in
      try Self.createSearchIndexTable(db)
      try db.execute(
        sql: """
          INSERT INTO searchindex (name, type, path) VALUES
          ('FunctionA', 'Function', '/docs/functionA'),
          ('ClassA',    'Class',    '/docs/classA');
          """
      )
    }

    let result = try await DocsetSearcher.typeList(forIndexDBQueue: dbQueue)
    XCTAssertEqual(result.count, 2)
    XCTAssertEqual(result[0].typeName, "Class")
    XCTAssertEqual(result[1].typeName, "Function")
  }

  private static func createSearchIndexTable(_ db: Database) throws {
    try db.create(table: "searchindex") { table in
      table.autoIncrementedPrimaryKey("id")
      table.column("name", .text).notNull()
      table.column("type", .text).notNull()
      table.column("path", .text).notNull()
    }
  }

}
