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

import Combine
import Foundation

import GRDB
import Overture

import BoltCombineExtensions
import BoltTypes
import BoltUtils

extension Bookmark: TableRecord, MutablePersistableRecord, FetchableRecord {

  public mutating func didInsert(_ inserted: InsertionSuccess) {
    rowID = inserted.rowID
  }

}

extension LibraryDatabaseImp {

  func bookmarks(forDocsetID docsetID: String) -> AnyPublisher<[Bookmark], Never> {
    ValueObservation.trackingConstantRegion { db in
      try Bookmark
        .filter(Column(Bookmark.CodingKeys.docsetID) == docsetID)
        .order([Column(Bookmark.CodingKeys.orderIndex), Column.rowID])
        .fetchAll(db)
    }
    .publisher(in: dbPool, scheduling: .immediate)
    // swiftlint:disable:next trailing_closure
    .handleEvents(receiveCompletion: { completion in
      if case let .failure(error) = completion {
        Self.logger.error("bookmarksForDocsetID: \(docsetID) receiveError: \(error.localizedDescription)")
      }
    })
    .share(replay: 1)
    .ignoreFailure()
  }

  func fetchBookmarks(forDocsetID docsetID: String) throws -> [Bookmark] {
    try dbPool.read { db in
      try Bookmark
        .filter(Column(Bookmark.CodingKeys.docsetID) == docsetID)
        .order([Column(Bookmark.CodingKeys.orderIndex), Column.rowID])
        .fetchAll(db)
    }
  }

  func containsBookmark(forPath path: String, docsetID: String) throws -> Bool {
    try dbPool.read { db in
      // swiftlint:disable:next contains_over_filter_is_empty
      try !Bookmark
        .filter(Column(Bookmark.CodingKeys.docsetID) == docsetID)
        .filter(Column(Bookmark.CodingKeys.path) == path)
        .isEmpty(db)
    }
  }

  func insertBookmark(_ bookmark: Bookmark) throws -> Bookmark {
    try dbPool.write { db in
      return try insertBookmark(bookmark, in: db)
    }
  }

  func toggleBookmark(_ bookmark: Bookmark) throws -> Bookmark? {
    try dbPool.write { db in
      if try deleteBookmark(byPath: bookmark.path, docsetID: bookmark.docsetID, in: db) {
        return nil
      } else {
        return try insertBookmark(bookmark, in: db)
      }
    }
  }

  func deleteBookmarkById(_ bookmark: Bookmark) throws {
    _ = try dbPool.write { db in
      try Bookmark.deleteOne(db, key: bookmark.rowID)
    }
  }

  func deleteBookmark(byPath path: String, docsetID: String) throws {
    _ = try dbPool.write { db in
      try deleteBookmark(byPath: path, docsetID: docsetID, in: db)
    }
  }

  private func insertBookmark(_ bookmark: Bookmark, in db: Database) throws -> Bookmark {
    let lastIndex = try Bookmark
      .filter(Column(Bookmark.CodingKeys.docsetID) == bookmark.docsetID)
      .select(max(Column(Bookmark.CodingKeys.orderIndex)), as: Int.self)
      .fetchOne(db)
    var newBookmark = update(bookmark) {
      $0.orderIndex = (lastIndex ?? -1) + 1
    }
    try newBookmark.insert(db)
    return newBookmark
  }

  private func deleteBookmark(byPath path: String, docsetID: String, in db: Database) throws -> Bool {
    try Bookmark
      .filter(Column(Bookmark.CodingKeys.docsetID) == docsetID)
      .filter(Column(Bookmark.CodingKeys.path) == path)
      .deleteAll(db) > 0
  }

}
