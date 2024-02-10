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

import BoltTypes

import Alamofire
import Factory
import SwiftyXMLParser

enum NetworkingError: LocalizedError {

  case locationResolutionError(resourceLocation: ResourceLocation)
  case responseParsingError(underlyingError: Error?)
  case externalError(_: Error)

  var errorDescription: String? {
    switch self {
    case let .locationResolutionError(resourceLocation):
      return "NetworkingError: failed to resolve url for location: \(resourceLocation)"
    case let .responseParsingError(underlyingError):
      return "NetworkingError: bad response data: \(String(describing: underlyingError?.localizedDescription))"
    case let .externalError(error):
      return "NetworkingError: underlyingError: \(error.localizedDescription)"
    }
  }

}

public protocol Networking {

  func fetchEntries(atURL: URLConvertible) async throws -> XML.Accessor

  @discardableResult
  func downloadFile(atLocation: ResourceLocation, toPath downloadPath: String) async throws -> URL

  func getFileSize(atLocation: ResourceLocation) async throws -> Int64?

}

public extension Container {

  var networking: Factory<Networking> { self { NetworkingImpl() }.cached }

}
