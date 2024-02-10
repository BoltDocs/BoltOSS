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

#if targetEnvironment(macCatalyst)

import Foundation
import XCTest

@testable import BoltDocsets

import BoltUtils

final class StubDelegate: BackgroundDownloaderDelegate {

  func downloaderDidUpdateSessionIDs(sessionIDs: [BoltDocsets.BackgroundDownloader.SessionTaskIdentifier]) {

  }

  func downloaderDidFinishDownload(forSessionID sessionID: BoltDocsets.BackgroundDownloader.SessionTaskIdentifier) {

  }

  func downloaderRemoveTask(forSessionID sessionID: BoltDocsets.BackgroundDownloader.SessionTaskIdentifier) {

  }

  func downloaderRemoveAllTasks() {

  }

  func downloaderGetDestinationPath(forSessionID sessionID: BoltDocsets.BackgroundDownloader.SessionTaskIdentifier) -> String? {
    return LocalFileSystem.downloadAbsolutePath.appendingPathComponent(UUID().uuidString)
  }

}

final class BackgroundDownloaderTests: XCTestCase {

  private var backgroundDownloader: BackgroundDownloader!

  override func setUp() async throws {
    try await super.setUp()
    backgroundDownloader = BackgroundDownloader(dataSource: StubDelegate())
    await backgroundDownloader.stopAllTasks()
  }

  override func tearDown() async throws {
    try await super.tearDown()
    await backgroundDownloader.stopAllTasks()
    backgroundDownloader = nil
  }

  func testStartDownload() {
    var ids: Set<BackgroundDownloader.SessionTaskIdentifier> = []
    for _ in 0..<10 {
      let sessionID = backgroundDownloader.startDownload(url: URL(string: "http://speedtest.ftp.otenet.gr/files/test100k.db")!)
      XCTAssertNotNil(sessionID)
      ids.insert(sessionID!)
    }

    let progresses = backgroundDownloader.sessionProgressValue()
    XCTAssertEqual(Set(progresses.keys), ids)
  }

  func testCancelDownload() async {
    var ids: Set<BackgroundDownloader.SessionTaskIdentifier> = []
    for _ in 0..<3 {
      let sessionID = backgroundDownloader.startDownload(url: URL(string: "https://speed.hetzner.de/1GB.bin")!)
      XCTAssertNotNil(sessionID)
      ids.insert(sessionID!)
    }

    for id in ids {
      await backgroundDownloader.cancelDownload(forSessionID: id)
    }

    let progresses = backgroundDownloader.sessionProgressValue()
    XCTAssert(Set(progresses.keys).isEmpty)
  }

  func testStopAllTasks() async {
    var ids: Set<BackgroundDownloader.SessionTaskIdentifier> = []
    for _ in 0..<3 {
      let sessionID = backgroundDownloader.startDownload(url: URL(string: "https://speed.hetzner.de/1GB.bin")!)
      XCTAssertNotNil(sessionID)
      ids.insert(sessionID!)
    }

    await backgroundDownloader.stopAllTasks()

    let progresses = self.backgroundDownloader.sessionProgressValue()
    XCTAssert(progresses.isEmpty)
  }

  func testDownloadError()  {
    var ids: Set<BackgroundDownloader.SessionTaskIdentifier> = []
    for _ in 0..<3 {
      let sessionID = backgroundDownloader.startDownload(url: URL(string: "https://something.invalid")!)
      XCTAssertNotNil(sessionID)
      ids.insert(sessionID!)
    }

    let expectation = XCTestExpectation()

    DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(18))) {
      let progresses = self.backgroundDownloader.sessionProgressValue()
      XCTAssertEqual(progresses.count, ids.count)
      for progress in progresses.values {
        guard case .failed = progress else {
          XCTFail("Unexpected progress. (should be all failed)")
          return
        }
      }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 20.0)
  }

  func testClearCache() async {
    var ids: Set<BackgroundDownloader.SessionTaskIdentifier> = []
    for _ in 0..<3 {
      let sessionID = backgroundDownloader.startDownload(url: URL(string: "https://speed.hetzner.de/1GB.bin")!)
      XCTAssertNotNil(sessionID)
      ids.insert(sessionID!)
    }

    await backgroundDownloader.clearCache()

    let progresses = self.backgroundDownloader.sessionProgressValue()
    XCTAssert(progresses.isEmpty)
  }

}

#endif
