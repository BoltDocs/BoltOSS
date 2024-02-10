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

public final class DocsetInstallation: LibraryRecord, Codable, Hashable, CustomStringConvertible {

  public var uuid: UUID
  public var name: String
  public var version: String
  public var installedAsLatestVersion: Bool
  public var repository: RepositoryIdentifier

  enum CodingKeys: String, CodingKey {
    case uuid
    case name
    case version
    case installedAsLatestVersion
    case repository = "source"
  }

  public static var databaseTableName: String {
    return "docset-installations"
  }

  public init(uuid: UUID = UUID(), name: String, version: String, installedAsLatestVersion: Bool, repository: RepositoryIdentifier) {
    self.uuid = uuid
    self.name = name
    self.version = version
    self.installedAsLatestVersion = installedAsLatestVersion
    self.repository = repository
  }

  public var id: String {
    return uuid.uuidString
  }

  public static func == (lhs: DocsetInstallation, rhs: DocsetInstallation) -> Bool {
    return lhs.uuid == rhs.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

  public var description: String {
    return InstallationIdentifier.fromName(
      name,
      version: version,
      installedAsLatestVersion: installedAsLatestVersion,
      repository: repository
    )
  }

}
