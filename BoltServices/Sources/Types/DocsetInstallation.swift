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

public final class DocsetInstallation: LibraryRecord, Sendable, Codable, Hashable, CustomStringConvertible {

  public let uuid: UUID
  public let name: String
  public let version: String
  public let installedAsLatestVersion: Bool
  public let repository: RepositoryIdentifier

  public let uuidString: String
  public let identifier: String

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

    uuidString = uuid.uuidString
    identifier = InstallationIdentifier.fromName(
      name,
      version: version,
      installedAsLatestVersion: installedAsLatestVersion,
      repository: repository
    )
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    uuid = try container.decode(UUID.self, forKey: .uuid)
    name = try container.decode(String.self, forKey: .name)
    version = try container.decode(String.self, forKey: .version)
    installedAsLatestVersion = try container.decode(Bool.self, forKey: .installedAsLatestVersion)
    repository = try container.decode(RepositoryIdentifier.self, forKey: .repository)

    uuidString = uuid.uuidString
    identifier = InstallationIdentifier.fromName(
      name,
      version: version,
      installedAsLatestVersion: installedAsLatestVersion,
      repository: repository
    )
  }

  public static func == (lhs: DocsetInstallation, rhs: DocsetInstallation) -> Bool {
    return lhs.uuid == rhs.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

  public var description: String {
    return "DocsetInstallation(identifier: \(identifier))"
  }

}
