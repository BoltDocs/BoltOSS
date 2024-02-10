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

import BoltTestingUtils

@testable import BoltArchives

final class TarUnarchiverTests: XCTestCase {

  func testExtractGzippedTarFile() async throws {
    let sourcePath = Bundle.module.path(forResource: "TestResources/Bash.tgz")!
    let destPath = NSTemporaryDirectory().appendingPathComponent(UUID().uuidString)
    let result = try await awaitPublisher(
      TarUnarchiver.extractGzippedTarFile(fromSourcePath: sourcePath, toDestPath: destPath),
      timeout: 10
    )
    guard case let .completed(path) = result else {
      XCTFail("unarchiver ends with non-error result")
      return
    }
    XCTAssert(
      FileManager.default.contentsEqual(
        atPath: path.appendingPathComponent("Bash.docset"),
        andPath: Bundle.module.path(forResource: "TestResources/Bash.docset")!
      )
    )
  }

  func testDataFromGippedIndexedTarFile() throws {
    let tgzURL = Bundle.module.url(forResource: "TestResources/Bash.tgz")!

    let indexFileURL = Bundle.module.url(forResource: "TestResources/Bash.tgz.tarix.txt")!
    let indexFileContent = try String(contentsOf: indexFileURL, encoding: .utf8)
    let indexLines = indexFileContent.components(separatedBy: "\n")

    for line in indexLines {
      let matches = line.regexMatch(#""(.*?)","(\d+) (\d+) (\d+)""#)
      guard matches.count == 1, matches[0].count == 5 else {
        XCTFail("Incorrect tar index txt data")
        return
      }

      // let blockStart = Int(matches[0][2])!
      let offset = UInt64(matches[0][3])!
      let blockLength = Int(matches[0][4])!

      let gunzippedSegment = try TarUnarchiver.rawDataFromTarFile(tarAbsoluteURL: tgzURL, blockLength: blockLength, offset: offset)
      guard let (path, data) = gunzippedSegment else {
        XCTFail("Failed to extract tar data segment")
        return
      }

      let localData = try Data(contentsOf: Bundle.module.url(forResource: "TestResources/" + path)!)
      XCTAssertEqual(data, localData)
    }
  }

}
