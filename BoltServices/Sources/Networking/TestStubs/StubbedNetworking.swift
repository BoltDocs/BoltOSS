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

import BoltNetworking
import BoltTypes

import Alamofire
import SwiftyJSON
import SwiftyXMLParser

public class StubbedNetworking: Networking {

  public init() { }

  public func fetchEntries(atURL url: URLConvertible) async throws -> XML.Accessor {
    assert((try? url.asURL().absoluteString) == "https://alamofire.github.io/Alamofire/docsets/Alamofire.xml")
    return XML.parse(try Data(contentsOf: Bundle.module.url(forResource: "Alamofire", withExtension: "xml", subdirectory: "TestResources")!))
  }

  // swiftlint:disable:next unavailable_function
  public func downloadFile(atLocation: ResourceLocation, toPath downloadPath: String) async throws -> URL {
    fatalError("downloadFile(atLocation:toPath:) not implemented")
  }

  // swiftlint:disable:next unavailable_function
  public func getFileSize(atLocation: ResourceLocation) async throws -> Int64? {
    fatalError("getFileSize(atLocation:) not implemented")
  }

}
