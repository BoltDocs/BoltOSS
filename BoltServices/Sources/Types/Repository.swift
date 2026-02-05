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

import Factory

public struct RepositoryIdentifier: Sendable, Codable, RawRepresentable, Hashable {

  private enum Repository: String {
    case main
    case cheatsheet
    case userContributed = "user_contributed"
    case custom
    case local
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.rawValue = try container.decode(String.self)
  }

  public typealias RawValue = String

  public init?(rawValue: String) {
    guard Repository(rawValue: rawValue) != nil else {
      return nil
    }
    self.rawValue = rawValue
  }

  public private(set) var rawValue: String

  public static var main: Self { return Self(rawValue: Repository.main.rawValue)! }
  public static var cheatsheet: Self { return Self(rawValue: Repository.cheatsheet.rawValue)! }
  public static var userContributed: Self { return Self(rawValue: Repository.userContributed.rawValue)! }
  public static var custom: Self { return Self(rawValue: Repository.custom.rawValue)! }
  public static var local: Self { return Self(rawValue: Repository.local.rawValue)! }

}

public protocol FeedRepository {

  var identifier: RepositoryIdentifier { get }
  var isPreset: Bool { get }

  var canFetchFeeds: Bool { get }
  var shouldCacheFeeds: Bool { get }

  func fetchFeeds() async throws -> [Feed]

}

public protocol RepositoryRegistry {

  func registerRepository(_ repository: FeedRepository, forIdentifier identifier: RepositoryIdentifier)
  func repository(forIdentifier: RepositoryIdentifier) -> FeedRepository?

}

public final class RepositoryRegistryImp: RepositoryRegistry {

  private var repositories = [RepositoryIdentifier: FeedRepository]()

  public func registerRepository(_ repository: FeedRepository, forIdentifier identifier: RepositoryIdentifier) {
    repositories[identifier] = repository
  }

  public func repository(forIdentifier identifier: RepositoryIdentifier) -> FeedRepository? {
    return repositories[identifier]
  }

}

public extension Container {

  var repositoryRegistry: Factory<RepositoryRegistry> {
    self {
      return RepositoryRegistryImp()
    }
    .cached
  }

}
