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

import Gzip

import BoltUtils

@testable import BoltArchives

final class GZipExtensionTests: XCTestCase {

  func testGunzippedFromFileHandle() throws {
    let indexFileURL = Bundle.module.url(forResource: "TestResources/Bash.tgz.tarix.txt")!
    let indexFileContent = try String(contentsOf: indexFileURL, encoding: .utf8)
    let indexLines = indexFileContent.components(separatedBy: "\n")

    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)

    let gunzippedData = TestResources.gunzippedTarData

    for line in indexLines {
      let matches = line.regexMatch(#""(.*?)","(\d+) (\d+) (\d+)""#)
      guard matches.count == 1, matches[0].count == 5 else {
        XCTFail("Incorrect tar index txt data")
        return
      }
      let blockStart = Int(matches[0][2])!
      let offset = UInt64(matches[0][3])!
      let blockLength = Int(matches[0][4])!

      let gUnzippedSegment = try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: offset,
        outputSize: blockLength * 512,
        wBits: -Gzip.maxWindowBits
      )
      let subData = gunzippedData.subdata(in: (blockStart * 512)..<(((blockStart + blockLength) * 512)))
      if gUnzippedSegment != subData {
        XCTFail("Mismatched data at: blockStart: \(blockStart), offset: \(offset) blockLength: \(blockLength)")
      }
    }
    try fileHandle.close()
  }

  func testInvalidFileHandle() throws {
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)
    try fileHandle.close()
    XCTAssertThrowsError(try Gzip.gunzipped(fromFileHandle: fileHandle, offset: 29892, outputSize: 14 * 512))
  }

  func testInvalidOffset() throws {
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)
    XCTAssertThrowsError(try Gzip.gunzipped(fromFileHandle: fileHandle, offset: 600000, outputSize: 2 * 512, wBits: -Gzip.maxWindowBits))
    try fileHandle.close()
  }

  func testInvalidDataSize() throws {
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)

    let data = try Gzip.gunzipped(fromFileHandle: fileHandle, offset: 617018, outputSize: 3 * 512, wBits: -Gzip.maxWindowBits)

    XCTAssertEqual(data.count, 3 * 512)

    let gunzippedData = TestResources.gunzippedTarData

    let validSegment = data.subdata(in: 0..<(2 * 512))
    let emptySegment = data.subdata(in: (2 * 512)..<data.count)
    let gunzippedSegment = gunzippedData.subdata(in: (3203 * 512)..<(((3203 + 2) * 512)))

    if gunzippedSegment != validSegment {
      XCTFail("Mismatched data segment")
    }

    if emptySegment.contains(where: { $0 != 0 }) {
      XCTFail("Non-zero bytes in result data segment")
    }

    try fileHandle.close()
  }

  func testInvalidBufferSize() throws {
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)
    XCTAssertThrowsError(
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: 600000,
        outputSize: 2 * 512,
        wBits: -Gzip.maxWindowBits,
        bufferSize: 0
      )
    )
    XCTAssertThrowsError(
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: 600000,
        outputSize: 2 * 512,
        wBits: -Gzip.maxWindowBits,
        bufferSize: -512
      )
    )
    try fileHandle.close()
  }

}
