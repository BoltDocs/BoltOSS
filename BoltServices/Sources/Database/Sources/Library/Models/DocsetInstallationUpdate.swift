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

import GRDB

import BoltTypes

// swiftlint:disable discouraged_optional_boolean
public struct DocsetInstallationUpdate: TableRecord {

  public var uuid: UUID
  public var name: String?
  public var version: String?
  public var installedAsLatestVersion: Bool?
  public var repository: RepositoryIdentifier?

  public init(
    uuid: UUID,
    name: String? = nil,
    version: String? = nil,
    installedAsLatestVersion: Bool? = nil,
    repository: RepositoryIdentifier? = nil
  ) {
    self.uuid = uuid
    self.name = name
    self.version = version
    self.installedAsLatestVersion = installedAsLatestVersion
    self.repository = repository
  }

  public static var databaseTableName: String {
    return DocsetInstallation.databaseTableName
  }

  public func update(in db: Database) throws {
    var assignments = [ColumnAssignment]()

    if let name = name {
      assignments.append(
        Column(DocsetInstallation.CodingKeys.name)
          .set(to: name)
      )
    }

    if let version = version {
      assignments.append(
        Column(DocsetInstallation.CodingKeys.version)
          .set(to: version)
      )
    }

    if let installedAsLatestVersion = installedAsLatestVersion {
      assignments.append(
        Column(DocsetInstallation.CodingKeys.installedAsLatestVersion)
          .set(to: installedAsLatestVersion)
      )
    }

    if let repository = repository {
      assignments.append(
        Column(DocsetInstallation.CodingKeys.repository)
          .set(to: repository.rawValue)
      )
    }

    guard !assignments.isEmpty else {
      return
    }

    try Self
      .filter(key: uuid)
      .updateAll(db, assignments)
  }

}
// swiftlint:enable discouraged_optional_boolean
