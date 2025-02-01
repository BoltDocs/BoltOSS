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

import BoltTestingUtils
import BoltTypes
import BoltUtils

import Factory

@testable import BoltDocsets

final class LibraryDocsetsManagerTests: XCTestCase {

  @LazyInjected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  override func setUpWithError() throws {
    try super.setUpWithError()

    Container.shared.docsetsModuleInitializer()()
    Container.shared.searchModuleInitializer()()

    try FileManager.default.createDirectory(atPath: LocalFileSystem.downloadsAbsolutePath, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try super.tearDownWithError()
    try FileManager.default.removeItem(atPath: LocalFileSystem.downloadsAbsolutePath)
  }

  func testInstallDocsetWithoutTarix() async throws {
    let fileManager = FileManager.default

    let downloadsPath = LocalFileSystem.downloadsAbsolutePath

    try fileManager.copyItem(
      atPath: Bundle.module.path(forResource: "TestResources/Vim.tgz")!,
      toPath: downloadsPath.appendingPathComponent("Vim-9.0-main.tgz")
    )

    let _ = try await awaitPublisher(
      libraryDocsetsManager.installDocset(
        forEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "Vim",
            displayName: "Vim",
            aliases: [],
            shouldHideVersions: false,
            supportsArchiveIndex: false,
            icon: EntryIcon.bundled(.docsetIcon(.vim))
          ),
          version: "9.0",
          isTrackedAsLatest: false,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        isInstalledAsLatest: false,
        usingTarix: false
      )
    )

    XCTAssert(fileManager.fileExists(atPath: downloadsPath))
    XCTAssertEqual(try fileManager.contentsOfDirectory(atPath: downloadsPath), [])
  }

  func testInstallDocsetWithTarix() async throws {
    let fileManager = FileManager.default

    let downloadsPath = LocalFileSystem.downloadsAbsolutePath

    try fileManager.copyItem(
      atPath: Bundle.module.path(forResource: "TestResources/Vim.tgz")!,
      toPath: downloadsPath.appendingPathComponent("Vim-9.0-main.tgz")
    )

    try fileManager.copyItem(
      atPath: Bundle.module.path(forResource: "TestResources/Vim.tgz.tarix")!,
      toPath: downloadsPath.appendingPathComponent("Vim-9.0-main.tgz.tarix")
    )

    let _ = try await awaitPublisher(
      libraryDocsetsManager.installDocset(
        forEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "Vim",
            displayName: "Vim",
            aliases: [],
            shouldHideVersions: false,
            supportsArchiveIndex: false,
            icon: EntryIcon.bundled(.docsetIcon(.vim))
          ),
          version: "9.0",
          isTrackedAsLatest: false,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        isInstalledAsLatest: false,
        usingTarix: true
      )
    )

    XCTAssert(fileManager.fileExists(atPath: downloadsPath))
    XCTAssertEqual(try fileManager.contentsOfDirectory(atPath: downloadsPath), [])
  }

}
