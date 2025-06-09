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

public extension LibraryDatabase {

  func fetchAllDownloadTasks() throws -> [DownloadTaskEntity] {
    return try dbPool.read { db in
      return try DownloadTaskEntity.fetchAll(db)
    }
  }

  func insertDownloadTask(_ task: DownloadTaskEntity) throws {
    try dbPool.write { db in
      if var existingTask = try? DownloadTaskEntity.fetchOne(db, key: [
        DownloadTaskEntity.CodingKeys.identifier.rawValue: task.identifier,
      ]) {
        existingTask.status = task.status
        try existingTask.update(db)
      } else {
        try task.save(db)
      }
    }
  }

  func updateDownloadMarkComplete(forBackingTaskID id: String) throws {
    try dbPool.write { db in
      let existingTasks = try DownloadTaskEntity
        .filter(Column(DownloadTaskEntity.CodingKeys.status.rawValue) == id)
        .fetchAll(db)

      assert(existingTasks.count <= 1)

      if var existingTask = existingTasks.first {
        existingTask.status = .completed
        try existingTask.update(db)
      }
    }
  }

  func deleteDownloadTask(forIdentifier id: String) throws {
    let _ = try dbPool.write { db in
      try DownloadTaskEntity
        .filter(key: id)
        .deleteAll(db)
    }
  }

  func deleteDownloadTask(forBackingTaskID id: String) throws {
    let _ = try dbPool.write { db in
      try DownloadTaskEntity
        .filter(Column(DownloadTaskEntity.CodingKeys.status.rawValue) == id)
        .deleteAll(db)
    }
  }

  func deleteIncompleteDownloadTask(keepBackingTaskIDs ids: [String]) throws {
    let _ = try dbPool.write { db in
      let filter = [
        !ids.contains(Column(DownloadTaskEntity.CodingKeys.status.rawValue)),
        Column(DownloadTaskEntity.CodingKeys.status.rawValue) != "-1",
      ]
      .joined(operator: .and)

      try DownloadTaskEntity
        .filter(filter)
        .deleteAll(db)
    }
  }

  func deleteAllOngoingTasks() throws {
    let _ = try dbPool.write { db in
      try DownloadTaskEntity
        .filter(Column(DownloadTaskEntity.CodingKeys.status.rawValue) != "-1")
        .deleteAll(db)
    }
  }

}
