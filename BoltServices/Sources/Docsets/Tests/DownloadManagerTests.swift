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

import Factory

@testable import BoltDocsets
@testable import BoltRepository

import BoltTestingUtils
import BoltTypes
import BoltUtils

final class DownloadManagerTests: XCTestCase {

  @LazyInjected(\.downloadManager)
  private var downloadManager: DownloadManager

  @MainActor
  override func setUp() async throws {
    try await super.setUp()
    let _ = downloadManager
    await downloadManager.cancelAllTasks()
  }

  @MainActor
  override func tearDown() async throws {
    try await super.tearDown()
    await downloadManager.cancelAllTasks()
    try? FileManager.default.removeItem(atPath: LocalFileSystem.downloadsAbsolutePath)
  }

  func testStartDownload() async throws {
    let entry = testEntryForDownload

    let progressObservable = downloadManager.progress(forIdentifier: entry.id)

    let res = await downloadManager.downloadDocset(forFeedEntry: entry)
    XCTAssertTrue(res)

    // FIXME: add a prefix(until:) counterpart
    let progress = try await awaitPublisher(
      progressObservable
        .prefix(
          while: { progress in
            if let progress, case .completed = progress {
              return false
            }
            return true
          },
          behavior: .inclusive
        ),
      timeout: 15
    )

    guard let progress, case .completed = progress else {
      XCTFail("Not returning success")
      return
    }
  }

  func testCancelDownload() async throws {
    let entry = testEntryForDownload

    let res = await downloadManager.downloadDocset(forFeedEntry: entry)
    XCTAssertTrue(res)

    var currentProgress: DownloadProgress?
    currentProgress = try await progress(forIdentifier: entry.id)
    XCTAssertNotNil(currentProgress)

    await downloadManager.cancelDownload(forIdentifier: entry.id)

    currentProgress = try await progress(forIdentifier: entry.id)
    XCTAssertNil(currentProgress)
  }

  func testStartDownloadAfterCancel() async throws{
    let entry = testEntryForDownload

    var res = await downloadManager.downloadDocset(forFeedEntry: entry)
    XCTAssertTrue(res)

    await downloadManager.cancelDownload(forIdentifier: entry.id)

    var currentProgress: DownloadProgress?
    currentProgress = try await progress(forIdentifier: entry.id)
    XCTAssertNil(currentProgress)

    res = await downloadManager.downloadDocset(forFeedEntry: entry)
    XCTAssertTrue(res)

    let progressObservable = downloadManager.progress(forIdentifier: entry.id)

    // FIXME: add a prefix(until:) counterpart
    let progress = try await awaitPublisher(
      progressObservable
        .prefix(
          while: { progress in
            if let progress, case .completed = progress {
              return false
            }
            return true
          },
          behavior: .inclusive
        ),
      timeout: 15
    )

    guard let progress, case .completed = progress else {
      XCTFail("Not returning success")
      return
    }
  }

  // MARK: - Private

  private var testEntryForDownload: FeedEntry {
    return FeedEntry(
      feed: StubFeed(
        repository: .main,
        id: "Bash",
        displayName: "Bash",
        aliases: ["bash shell", "terminal"],
        shouldHideVersions: true,
        supportsArchiveIndex: false,
        icon: EntryIcon.bundled(.docsetIcon(.vim))
      ),
      version: "/8",
      isTrackedAsLatest: true,
      isDocsetBundle: false,
      docsetLocation: ResourceLocations.URL(URL(string: "https://kapeli.com/feeds/Bash.tgz")!)
    )
  }

  private func progress(forIdentifier identifier: String, timeout: TimeInterval? = nil) async throws -> DownloadProgress? {
    return try await awaitPublisher(
      downloadManager.progress(forIdentifier: identifier)
        // swiftlint:disable:next trailing_closure
        .handleEvents(receiveOutput: { _ in
          XCTAssert(Thread.isMainThread)
        })
        .prefix(1)
      , timeout: timeout ?? 10
    )
  }

}

#endif
