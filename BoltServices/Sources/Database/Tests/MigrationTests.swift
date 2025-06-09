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

import Foundation
import Testing

import GRDB

import BoltTypes

@testable import BoltDatabase

struct MigrationTests {

  @Test func migrationAddOrderIndexForInstallations() async throws {
    let dbQueue = try DatabaseQueue()

    let migrator = LibraryDatabase.createMigrator()
    try migrator.migrate(dbQueue, upTo: "Create Initial Tables")

    try await dbQueue.write { db in
      for i in 0..<5 {
        try db.execute(
          sql:
            """
            INSERT INTO "docset-installations" (uuid, name, version, installedAsLatestVersion, source)
            VALUES (?, ?, ?, ?, ?)
            """,
          arguments: [ UUID().uuidString, "DocSet \(i)", "1.0", true, "custom"]
        )
      }
    }

    try migrator.migrate(dbQueue)

    let installations = try await dbQueue.read { db in
      let request = DocsetInstallation
        .all()
        .order([Column(DocsetInstallation.CodingKeys.orderIndex)])
        .order([Column.rowID])

      return try DocsetInstallation
        .fetchAll(db, request)
    }

    #expect(installations.count == 5)
    for (idx, installation) in installations.enumerated() {
      #expect(installation.name == "DocSet \(idx)")
      #expect(installation.orderIndex == idx)
    }
  }
}
