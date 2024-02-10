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

public struct DownloadTaskEntity: Codable, TableRecord, PersistableRecord, FetchableRecord, Hashable {

  public enum Status: Hashable, RawRepresentable, Codable {

    public typealias RawValue = String

    case downloading(taskIdentifier: String)
    case completed

    public init?(rawValue: String) {
      switch rawValue {
      case "-1":
        self = .completed
      default:
        self = .downloading(taskIdentifier: rawValue)
      }
    }

    public var rawValue: String {
      switch self {
      case let .downloading(taskIdentifier):
        return taskIdentifier
      case .completed:
        return "-1"
      }
    }

  }

  public var identifier: String

  public var name: String
  public var displayName: String
  public var version: String
  public var installedAsLatestVersion: Bool

  public var repository: RepositoryIdentifier
  public var status: Status

  public var isDownloading: Bool {
    if case .downloading = status {
      return true
    }
    return false
  }

  public var taskIdentifier: Int? {
    if case let .downloading(identifier) = status {
      return Int(identifier)
    }
    return nil
  }

  public static var databaseTableName: String {
    return "download-tasks"
  }

  public init(
    name: String,
    displayName: String,
    version: String,
    installedAsLatestVersion: Bool,
    repository: RepositoryIdentifier,
    status: Status
  ) {
    self.name = name
    self.displayName = displayName
    self.version = version
    self.installedAsLatestVersion = installedAsLatestVersion
    self.repository = repository
    self.status = status
    self.identifier = InstallationIdentifier.fromName(
      name,
      version: version,
      installedAsLatestVersion: installedAsLatestVersion,
      repository: repository
    )
  }

  enum CodingKeys: String, CodingKey {
    case identifier = "id"
    case name = "feedName"
    case displayName = "displayName"
    case version
    case installedAsLatestVersion
    case repository
    case status = "backingTask"
  }

}
