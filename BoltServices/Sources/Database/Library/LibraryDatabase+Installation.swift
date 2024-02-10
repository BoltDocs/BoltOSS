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

extension LibraryDatabase {

  func createInstallationTable(_ db: Database) throws {
    try db.create(table: "docset-installations", ifNotExists: true) { table in
      table.column("uuid", .text).primaryKey()
      table.column("name", .text).notNull()
      table.column("version", .text).notNull()
      table.column("installedAsLatestVersion", .boolean).notNull()
      table.column("source", .text).notNull()
    }
  }

  public func insertDocsetInstallation(_ docsetInstallation: DocsetInstallation) throws {
    try dbPool.write { db in
      try docsetInstallation.insert(db)
    }
  }

  public func deleteDocsetInstallation(_ docsetInstallation: DocsetInstallation) throws {
    let  _ = try dbPool.write { db in
      try docsetInstallation.delete(db)
    }
  }

}
