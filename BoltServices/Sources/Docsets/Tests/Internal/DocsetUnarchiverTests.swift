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
import XCTest

@testable import BoltDocsets

import BoltRepository
import BoltTestingUtils
import BoltTypes
import BoltUtils

final class TarUnarchiverTests: XCTestCase {

  func testUnarchiveDownloadedDocsetWithoutTarix() async throws {
    let destPath = NSTemporaryDirectory().appendingPathComponent(UUID().uuidString)

    let resultProgress = try await awaitPublisher(
      DocsetUnarchiver.unarchiveDownloadedDocsetWithoutTarix(
        downloadedTarPath: Bundle.module.path(forResource: "TestResources/Vim", ofType: "tgz")!,
        toPath: destPath,
        forFeedEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "Vim",
            displayName: "Vim",
            aliases: [],
            author: nil,
            shouldHideVersions: false,
            supportsArchiveIndex: false,
            icon: EntryIcon.bundled(.docsetIcon(.vim))
          ),
          version: "9.0",
          isTrackedAsLatest: false,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        removeSourceFiles: false
      ),
      timeout: 10
    )

    guard case .completed = resultProgress else {
      XCTFail("Not returning complete")
      return
    }

    XCTAssert(
      FileManager.default.contentsEqual(
        atPath: destPath.appendingPathComponent("Vim.docset"),
        andPath: Bundle.module.path(forResource: "TestResources/Vim.docset")!
      )
    )
  }

  func testUnarchiveDownloadedDocsetWithTarix() async throws {
    let destPath = NSTemporaryDirectory().appendingPathComponent(UUID().uuidString)

    let resultProgress = try await awaitPublisher(
      DocsetUnarchiver.unarchiveDownloadedDocsetUsingTarix(
        downloadedTarPath: Bundle.module.path(forResource: "TestResources/Vim.tgz")!,
        downloadedTarixPath: Bundle.module.path(forResource: "TestResources/Vim.tgz.tarix")!,
        toPath: destPath,
        forFeedEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "Vim",
            displayName: "Vim",
            aliases: [],
            author: nil,
            shouldHideVersions: false,
            supportsArchiveIndex: true,
            icon: EntryIcon.bundled(.docsetIcon(.vim))
          ),
          version: "9.0",
          isTrackedAsLatest: false,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        removeSourceFiles: false
      ),
      timeout: 10
    )

    guard case .completed = resultProgress else {
      XCTFail("Not returning complete")
      return
    }

    XCTAssert(
      FileManager.default.contentsEqual(
        atPath: destPath.appendingPathComponent("Vim.docset"),
        andPath: Bundle.module.path(forResource: "TestResources/Vim_tarix.docset")!
      )
    )
  }

  func testUnarchiveDownloadedDocsetWithMultipleExtensions() async throws {
    let destPath = NSTemporaryDirectory().appendingPathComponent(UUID().uuidString)

    let resultProgress = try await awaitPublisher(
      DocsetUnarchiver.unarchiveDownloadedDocsetWithoutTarix(
        downloadedTarPath: Bundle.module.path(forResource: "TestResources/MultipleExtensions", ofType: "tgz")!,
        toPath: destPath,
        forFeedEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "MultipleExtensions",
            displayName: "MultipleExtensions",
            aliases: [],
            author: nil,
            shouldHideVersions: false,
            supportsArchiveIndex: false,
            icon: EntryIcon.bundled(.docsetIcon(.vim))
          ),
          version: "1.0",
          isTrackedAsLatest: false,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        removeSourceFiles: false
      ),
      timeout: 10
    )

    guard case .completed = resultProgress else {
      XCTFail("Not returning complete")
      return
    }

    XCTAssert(
      FileManager.default.contentsEqual(
        atPath: destPath.appendingPathComponent("MultipleExtensions.abc.docset"),
        andPath: Bundle.module.path(forResource: "TestResources/MultipleExtensions.abc.docset")!
      )
    )
  }

}
