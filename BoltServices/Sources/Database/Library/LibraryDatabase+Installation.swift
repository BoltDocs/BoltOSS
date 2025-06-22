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

public extension LibraryDatabase {

  func insertDocsetInstallation(_ docsetInstallation: DocsetInstallation) throws {
    try dbPool.write { db in
      try docsetInstallation.insert(db)
    }
  }

  func deleteDocsetInstallation(withUUID uuid: UUID) throws {
    let  _ = try dbPool.write { db in
      try DocsetInstallation.deleteOne(db, key: uuid)
    }
  }

}
