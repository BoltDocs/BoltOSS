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
import Testing

import Gzip

import BoltUtils

@testable import BoltArchives

struct GZipExtensionTests {

  @Test func gunzippedFromFileHandle() throws {
    let indexFileURL = Bundle.module.url(forResource: "TestResources/Bash.tgz.tarix.txt")!
    let indexFileContent = try String(contentsOf: indexFileURL, encoding: .utf8)
    let indexLines = indexFileContent.components(separatedBy: "\n")

    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)

    let gunzippedData = TestResources.gunzippedTarData

    for line in indexLines {
      let matches = line.regexMatch(#""(.*?)","(\d+) (\d+) (\d+)""#)
      guard matches.count == 1, matches[0].count == 5 else {
        Issue.record("Incorrect tar index txt data")
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
        Issue.record("Mismatched data at: blockStart: \(blockStart), offset: \(offset) blockLength: \(blockLength)")
      }
    }
    try fileHandle.close()
  }

  @Test func invalidFileHandle() throws {
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)
    #expect(throws: GzipError.self) {
      try Gzip.gunzipped(fromFileHandle: fileHandle, offset: 29892, outputSize: 14 * 512)
    }
    try fileHandle.close()
  }

  @Test func invalidOffset() throws {
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)
    #expect(throws: GzipError.self) {
      try Gzip.gunzipped(fromFileHandle: fileHandle, offset: 600000, outputSize: 2 * 512, wBits: -Gzip.maxWindowBits)
    }
    try fileHandle.close()
  }

  @Test func invalidDataSize() throws {
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)

    let data = try Gzip.gunzipped(fromFileHandle: fileHandle, offset: 617018, outputSize: 3 * 512, wBits: -Gzip.maxWindowBits)

    #expect(data.count == 3 * 512)

    let gunzippedData = TestResources.gunzippedTarData

    let validSegment = data.subdata(in: 0..<(2 * 512))
    let emptySegment = data.subdata(in: (2 * 512)..<data.count)
    let gunzippedSegment = gunzippedData.subdata(in: (3203 * 512)..<(((3203 + 2) * 512)))

    if gunzippedSegment != validSegment {
      Issue.record("Mismatched data segment")
    }

    if emptySegment.contains(where: { $0 != 0 }) {
      Issue.record("Non-zero bytes in result data segment")
    }

    try fileHandle.close()
  }

  @Test func invalidBufferSize() throws {
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)
    #expect(throws: GzipError.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: 600000,
        outputSize: 2 * 512,
        wBits: -Gzip.maxWindowBits,
        bufferSize: 0
      )
    }
    #expect(throws: GzipError.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: 600000,
        outputSize: 2 * 512,
        wBits: -Gzip.maxWindowBits,
        bufferSize: -512
      )
    }
    try fileHandle.close()
  }

}
