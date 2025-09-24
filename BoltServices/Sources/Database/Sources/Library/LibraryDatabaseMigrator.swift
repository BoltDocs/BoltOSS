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

import GRDB

extension LibraryDatabase {

  class func createMigrator() -> DatabaseMigrator {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("Create Initial Tables") { db in
      let createInstallationTable = {
        try db.create(table: "docset-installations", ifNotExists: true) { table in
          table.column("uuid", .text).primaryKey()
          table.column("name", .text).notNull()
          table.column("version", .text).notNull()
          table.column("installedAsLatestVersion", .boolean).notNull()
          table.column("source", .text).notNull()
        }
      }

      let createCustomFeedsTable = {
        try db.create(table: "custom-feeds", ifNotExists: true) { table in
          table.column("uuid", .text).primaryKey()
          table.column("name", .text).notNull()
          table.column("url", .text).notNull()
        }
      }

      let createDownloadTaskTable = {
        try db.create(table: "download-tasks", ifNotExists: true) { table in
          table.column("id", .text).notNull()
          table.column("feedName", .text).notNull()
          table.column("displayName", .text).notNull()
          table.column("version", .text).notNull()
          table.column("installedAsLatestVersion", .boolean).notNull()
          table.column("repository", .text).notNull()
          table.column("backingTask", .text).notNull()
          table.primaryKey(["id"])
        }
        try db.create(
          index: "byIdentifier",
          on: "download-tasks",
          columns: ["feedName", "version", "installedAsLatestVersion", "repository"],
          unique: true,
          ifNotExists: true
        )
      }

      try createInstallationTable()
      try createCustomFeedsTable()
      try createDownloadTaskTable()
    }

    migrator.registerMigration("Add Order Index for Installations Table") { db in
      try db.alter(table: "docset-installations") { t in
        t.add(column: "orderIndex", .integer).notNull().defaults(to: 0)
      }
      try db.execute(
        sql:
          """
          WITH ranked AS (
            SELECT rowid AS id, ((ROW_NUMBER() OVER (ORDER BY rowid)) - 1) AS rank FROM "docset-installations"
          )
          UPDATE "docset-installations"
          SET orderIndex = (SELECT rank FROM ranked WHERE ranked.id = rowid)
          """
      )
    }

    migrator.registerMigration("Add Latest Version Column for Installations Table") { db in
      try db.alter(table: "docset-installations") { t in
        t.add(column: "latestVersion", .text)
      }
    }

    return migrator
  }

}
