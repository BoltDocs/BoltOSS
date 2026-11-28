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

    let migrator = LibraryDatabaseImp.createMigrator()
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
        .order([Column(DocsetInstallation.CodingKeys.orderIndex), Column.rowID])

      return try DocsetInstallation
        .fetchAll(db, request)
    }

    #expect(installations.count == 5)
    for (idx, installation) in installations.enumerated() {
      #expect(installation.name == "DocSet \(idx)")
      #expect(installation.orderIndex == idx)
    }
  }

  @Test func migrationStoreUUIDsAsUppercaseStrings() async throws {
    let dbQueue = try DatabaseQueue()

    let migrator = LibraryDatabaseImp.createMigrator()
    try migrator.migrate(dbQueue, upTo: "Create Bookmarks Table")

    let blobUUID = UUID()

    try await dbQueue.write { db in
      try db.execute(
        sql:
          """
          INSERT INTO "docset-installations" (uuid, name, version, installedAsLatestVersion, source)
          VALUES (?, ?, ?, ?, ?)
          """,
        arguments: [blobUUID, "Blob DocSet", "1.0", true, "custom"]
      )
      try db.execute(
        sql:
          """
          INSERT INTO "custom-feeds" (uuid, name, url)
          VALUES (?, ?, ?)
          """,
        arguments: [blobUUID, "Custom Feed", "https://example.com/feed.atom"]
      )
    }

    try await dbQueue.read { db in
      let types = try String.fetchAll(
        db,
        sql: "SELECT typeof(uuid) FROM \"docset-installations\""
      )
      #expect(types == ["blob"])
    }

    try migrator.migrate(dbQueue)

    try await dbQueue.read { db in
      let installationUUIDs = try String.fetchAll(
        db,
        sql: "SELECT uuid FROM \"docset-installations\""
      )
      #expect(installationUUIDs == [blobUUID.uuidString])

      let installationTypes = try String.fetchAll(
        db,
        sql: "SELECT typeof(uuid) FROM \"docset-installations\""
      )
      #expect(installationTypes == ["text"])

      let installation = try DocsetInstallation.fetchOne(db, key: blobUUID)
      #expect(installation?.name == "Blob DocSet")

      let feed = try CustomFeedEntity.fetchOne(db, key: blobUUID)
      #expect(feed?.displayName == "Custom Feed")

      let feedType = try String.fetchOne(db, sql: "SELECT typeof(uuid) FROM \"custom-feeds\"")
      #expect(feedType == "text")
    }
  }

  @Test func migrationAddDisplayNameForInstallations() async throws {
    let dbQueue = try DatabaseQueue()

    let migrator = LibraryDatabaseImp.createMigrator()
    try migrator.migrate(dbQueue, upTo: "Store UUIDs as Uppercase Strings")

    let names = ["Bash", "Apache_HTTP_Server", "Custom DocSet"]

    try await dbQueue.write { db in
      for (idx, name) in names.enumerated() {
        try db.execute(
          sql:
            """
            INSERT INTO "docset-installations" (uuid, name, version, installedAsLatestVersion, source, orderIndex)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
          arguments: [UUID().uuidString, name, "1.0", true, "main", idx]
        )
      }
    }

    try migrator.migrate(dbQueue)

    let installations = try await dbQueue.read { db in
      let request = DocsetInstallation
        .all()
        .order([Column(DocsetInstallation.CodingKeys.orderIndex), Column.rowID])

      return try DocsetInstallation
        .fetchAll(db, request)
    }

    #expect(installations.count == names.count)
    for (idx, installation) in installations.enumerated() {
      #expect(installation.name == names[idx])
      #expect(installation.displayName == names[idx])
    }

    let inserted = DocsetInstallation(
      name: "Apache_HTTP_Server",
      displayName: "Apache HTTP Server",
      version: DocsetVersion(rawValue: "2.4"),
      installedAsLatestVersion: false,
      repository: .main,
      orderIndex: names.count
    )

    try await dbQueue.write { db in
      try inserted.insert(db)
    }

    let fetched = try await dbQueue.read { db in
      try DocsetInstallation.fetchOne(db, key: inserted.uuid)
    }

    #expect(fetched?.name == "Apache_HTTP_Server")
    #expect(fetched?.displayName == "Apache HTTP Server")
  }

}
