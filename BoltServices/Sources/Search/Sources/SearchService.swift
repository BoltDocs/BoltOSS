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

import Factory

import BoltTypes

public final class SearchServiceError: ServiceError {

  public let underlyingError: Error

  public init(underlyingError: Error) {
    self.underlyingError = underlyingError
    super.init()
  }

  override public var errorDescription: String {
    return underlyingError.localizedDescription
  }

}

@MainActor
public protocol SearchService: AnyObject {

  func searchIndex(forDocsetPath docsetPath: String, identifier: String) -> DocsetSearchIndex
  func searchIndex(forDocset docset: Docset) -> DocsetSearchIndex

  func queueToCreateSearchIndex(_: DocsetSearchIndex) async

}

public extension Container {

  var searchService: Factory<SearchService> { self {
    return MainActor.assumeIsolated {
      SearchServiceImp()
    }
  }.cached }

}
