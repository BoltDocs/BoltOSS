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

import Combine
import Foundation

import Factory

import BoltDatabase
import BoltTypes
import BoltUtils

public final class FeedsServiceError: ServiceError {

  public let underlyingError: Error

  public init(underlyingError: Error) {
    self.underlyingError = underlyingError
    super.init()
  }

  override public var errorDescription: String {
    return underlyingError.localizedDescription
  }

}

public protocol FeedsService {

  func fetchAllFeeds(forRepository repositoryIdentifier: RepositoryIdentifier, forceUpdate: Bool) async throws(FeedsServiceError) -> [Feed]

  func customFeedsObservable() -> AnyPublisher<[CustomFeed], Never>

  func insertCustomFeed(_ feed: CustomFeed) throws

  func updateCustomFeed(_ feed: CustomFeed) throws

  func deleteCustomFeeds(_ feed: CustomFeed) throws

}

protocol FeedsServiceInternal: FeedsService {

  func fetchEntries(forCustomFeed feed: CustomFeed) async throws -> [FeedEntry]

}

extension FeedsService {

  func asInternal() -> FeedsServiceInternal {
    return self as! FeedsServiceInternal
  }

}

public extension Container {

  var feedsService: Factory<FeedsService> { self { FeedsServiceImp() }.cached }

}
