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

extension LibraryDatabase {

  func createCustomFeedsTable(_ db: Database) throws {
    try db.create(table: "custom-feeds", ifNotExists: true) { table in
      table.column("uuid", .text).primaryKey()
      table.column("name", .text).notNull()
      table.column("url", .text).notNull()
    }
  }

  public func insertCustomFeed(_ feed: CustomFeedEntity) throws {
    try dbPool.write { db in
      try feed.insert(db)
    }
  }

  public func updateCustomFeed(_ feed: CustomFeedEntity) throws {
    try dbPool.write { db in
      try feed.update(db)
    }
  }

  public func deleteCustomFeed(_ feed: CustomFeedEntity) throws {
    let _ = try dbPool.write { db in
      try feed.delete(db)
    }
  }

}
