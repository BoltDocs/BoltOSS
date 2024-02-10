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

import BoltTypes

import Alamofire
import Factory
import SwiftyXMLParser

struct NetworkingImpl: Networking {

  @Injected(\.resourceLocationResolvers)
  private var resourceLocationResolvers: ResourceLocationResolvers

  init() { }

  private let session: Session = {
    let sessionConfiguration = URLSessionConfiguration.default
    sessionConfiguration.urlCredentialStorage = nil
    return Session(configuration: sessionConfiguration)
  }()

  func fetchEntries(atURL url: URLConvertible) async throws -> XML.Accessor {
    let dataTask = session.request(url, method: .get)
      .validate()
      .serializingData()

    let dataResponse = await dataTask.response

    switch dataResponse.result {
    case let .success(data):
      let xml = XML.parse(data)
      if let error = xml.error {
        throw NetworkingError.responseParsingError(underlyingError: error)
      }
      return xml
    case let .failure(error):
      throw NetworkingError.externalError(error)
    }
  }

  func downloadFile(atLocation location: ResourceLocation, toPath downloadPath: String) async throws -> URL {
    guard let downloadURL = resourceLocationResolvers.url(forResourceLocation: location) else {
      throw NetworkingError.locationResolutionError(resourceLocation: location)
    }

    // swiftlint:disable:next trailing_closure
    let responseResult = await session.download(downloadURL, to: { _, _ in
      return (
        URL(fileURLWithPath: downloadPath),
        [.createIntermediateDirectories, .removePreviousFile]
      )
    })
    .validate()
    .serializingDownloadedFileURL()
    .response
    .result

    switch responseResult {
    case let .success(diskURL):
      return diskURL
    case let .failure(error):
      throw NetworkingError.externalError(error)
    }
  }

  func getFileSize(atLocation location: ResourceLocation) async throws -> Int64? {
    guard let downloadURL = resourceLocationResolvers.url(forResourceLocation: location) else {
      throw NetworkingError.locationResolutionError(resourceLocation: location)
    }

    let response = await session.request(downloadURL, method: .head)
      .validate()
      .serializingData()
      .response

    if let error = response.error {
      throw NetworkingError.externalError(error)
    }

    if let contentLength = response.response?.expectedContentLength {
      return contentLength > 0 ? contentLength : nil
    }

    return nil
  }

}
