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

import XCTest

import BoltTypes

@testable import BoltNetworking

final class NetworkingTests: XCTestCase {

  private var networking: Networking!

  override func setUp() {
    super.setUp()
    networking = NetworkingImpl()
  }

  override func tearDown() {
    super.tearDown()
    networking = nil
  }

  func testDownloadTarixAtDashHostedLocation() async throws {
    let resultURL = try await networking.downloadFile(
      atLocation: ResourceLocations.URL(URL(string: "https://kapeli.com/feeds/Bash.tgz")!),
      toPath: NSTemporaryDirectory().appendingPathComponent("Bash.tgz")
    )
    XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path, isDirectory: nil))
  }

  func testDownloadTarixAtURLLocation() async throws {
    let resultURL = try await networking.downloadFile(
      atLocation: ResourceLocations.URL(URL(string: "https://alamofire.github.io/Alamofire/docsets/Alamofire.tgz")!),
      toPath: NSTemporaryDirectory().appendingPathComponent("Alamofire.tgz")
    )
    XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path, isDirectory: nil))
  }

  func testGetFileSizeAtDashHostedLocation() async throws {
    let byteSize = try await networking.getFileSize(
      atLocation: ResourceLocations.URL(URL(string: "https://kapeli.com/feeds/zzz/versions/NodeJS/14.14.0/NodeJS.tgz")!)
    )
    XCTAssert(try XCTUnwrap(byteSize) > 0)
  }

  func testGetFileSizeAtURLLocation() async throws {
    let byteSize = try await networking.getFileSize(
      atLocation: ResourceLocations.URL(URL(string: "https://alamofire.github.io/Alamofire/docsets/Alamofire.tgz")!)
    )
    XCTAssert(try XCTUnwrap(byteSize) > 0)
  }

}
