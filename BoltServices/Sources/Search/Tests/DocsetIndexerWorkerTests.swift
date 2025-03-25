//
// Copyright (C) 2025 Bolt Contributors
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

final class DocsetIndexerWorkerTests: XCTestCase {

  func testCreateSearchIndex() async throws {

    let dsIdxQueue = try DatabaseQueue()
    try await dsIdxQueue.write { db in
      try db.create(table: "searchindex") { table in
        table.autoIncrementedPrimaryKey("id")
        table.column("name", .text).notNull()
        table.column("type", .text).notNull()
        table.column("path", .text).notNull()
      }

      try db.execute(
        sql:
          """
          INSERT INTO searchindex (name, type, path) VALUES
          ('FunctionA', 'func', '/docs/functionA'),
          ('ClassB', 'class', '/docs/classB');
          """
      )
    }

    let dbQueue = try DatabaseQueue()
    for try await _ in DocsetIndexerWorker.createSearchIndex(withDatabaseQueue: dbQueue, dsIndexQueue: dsIdxQueue) { }

    let count = try await dbQueue.read { db in
      try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM searchindex")
    }

    XCTAssertEqual(count, 2)
  }

  func testCreateQueryIndex() async throws {
    let dbQueue = try DatabaseQueue()

    try await dbQueue.write { db in
      try db.create(table: "searchindex") { table in
        table.autoIncrementedPrimaryKey("id")
        table.column("name", .text).notNull()
        table.column("type", .text).notNull()
        table.column("path", .text).notNull()
      }
      try db.execute(
        sql:
          """
          INSERT INTO searchindex (id, name, type, path) VALUES
          (1, 'FunctionA', 'func', '/docs/functionA'),
          (2, 'ClassB', 'class', '/docs/classB');
          """
      )
    }

    for try await _ in DocsetIndexerWorker.createQueryIndex(withDatabaseQueue: dbQueue) { }

    let queryIndex = try await dbQueue.read { db in
      return try QueryIndex
        .filter(Column("perfect").match(try FTS3Pattern(rawPattern: "\"ClassB\"")))
        .fetchOne(db)
    }

    XCTAssertEqual(
      queryIndex,
      QueryIndex(searchId: 2, perfect: "classb", prefix: "class", suffixesString: "lassb assb ssb sb b")
    )
  }

}
