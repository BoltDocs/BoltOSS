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
    let indexFileURL = Bundle.module.url(forResource: "TestResources/Bash.tarix.txt")!
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

  @Test func invalidHeaderTrailerFormat() throws {
    let infoPlistEntry = try infoPlistIndexEntry()
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)
    #expect(throws: Never.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: infoPlistEntry.offset,
        outputSize: infoPlistEntry.blockLength * 512,
        wBits: -Gzip.maxWindowBits
      )
    }
    #expect(throws: GzipError.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: infoPlistEntry.offset,
        outputSize: infoPlistEntry.blockLength * 512
      )
    }
    try fileHandle.close()
  }

  @Test func invalidOffset() throws {
    let infoPlistEntry = try infoPlistIndexEntry()
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)
    #expect(throws: Never.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: infoPlistEntry.offset,
        outputSize: infoPlistEntry.blockLength * 512,
        wBits: -Gzip.maxWindowBits
      )
    }
    #expect(throws: GzipError.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: infoPlistEntry.offset + 1,
        outputSize: infoPlistEntry.blockLength * 512,
        wBits: -Gzip.maxWindowBits
      )
    }
    try fileHandle.close()
  }

  @Test func invalidDataSize() throws {
    let infoPlistEntry = try infoPlistIndexEntry()
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)

    let blockStart = infoPlistEntry.blockStart
    let blockLength = infoPlistEntry.blockLength

    #expect(throws: Never.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: infoPlistEntry.offset,
        outputSize: (blockLength - 1) * 512,
        wBits: -Gzip.maxWindowBits
      )
    }

    let data = try Gzip.gunzipped(
      fromFileHandle: fileHandle,
      offset: infoPlistEntry.offset,
      outputSize: (blockLength + 1) * 512,
      wBits: -Gzip.maxWindowBits
    )

    #expect(data.count == (blockLength + 1) * 512)

    let gunzippedData = TestResources.gunzippedTarData

    let validSegment = data.subdata(in: 0..<(blockLength * 512))
    let emptySegment = data.subdata(in: (blockLength * 512)..<data.count)
    let gunzippedSegment = gunzippedData.subdata(in: (blockStart * 512)..<(((blockStart + blockLength) * 512)))

    if gunzippedSegment != validSegment {
      Issue.record("Mismatched data segment")
    }

    if emptySegment.contains(where: { $0 != 0 }) {
      Issue.record("Non-zero bytes in result data segment")
    }

    try fileHandle.close()
  }

  @Test func invalidBufferSize() throws {
    let infoPlistEntry = try infoPlistIndexEntry()
    let fileHandle = try FileHandle(forReadingFrom: TestResources.tgzURL)
    #expect(throws: Never.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: infoPlistEntry.offset,
        outputSize: infoPlistEntry.blockLength * 512,
        wBits: -Gzip.maxWindowBits
      )
    }
    #expect(throws: GzipError.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: infoPlistEntry.offset,
        outputSize: infoPlistEntry.blockLength * 512,
        wBits: -Gzip.maxWindowBits,
        bufferSize: 0
      )
    }
    #expect(throws: Never.self) {
      try Gzip.gunzipped(
        fromFileHandle: fileHandle,
        offset: infoPlistEntry.offset,
        outputSize: infoPlistEntry.blockLength * 512,
        wBits: -Gzip.maxWindowBits,
        bufferSize: -512
      )
    }
    try fileHandle.close()
  }

  private func infoPlistIndexEntry() throws -> (blockStart: Int, offset: UInt64, blockLength: Int) {
    let indexFileURL = Bundle.module.url(forResource: "TestResources/Bash.tarix.txt")!
    let indexFileContent = try String(contentsOf: indexFileURL, encoding: .utf8)
    let indexLines = indexFileContent.components(separatedBy: "\n")

    let line = try #require(indexLines.first { $0.starts(with: "\"Bash.docset/Contents/Info.plist\",\"") })

    let matches = line.regexMatch(#""Bash.docset/Contents/Info.plist","(\d+) (\d+) (\d+)""#)

    try #require(matches.count == 1 && matches[0].count == 4)

    let blockStart = try #require(Int(matches[0][1]))
    let offset = try #require(UInt64(matches[0][2]))
    let blockLength = try #require(Int(matches[0][3]))

    return (blockStart, offset, blockLength)
  }

}
