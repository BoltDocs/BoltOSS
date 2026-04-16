//
// Copyright (C) 2026 Bolt Contributors
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

import Factory

import BoltTypes
import BoltUtils

@testable import BoltDocsets

final class DocsetUpdateCheckerTests: XCTestCase {

  @LazyInjected(\.docsetUpdateChecker)
  private var docsetUpdateChecker: DocsetUpdateChecker

  @LazyInjected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  private let stubbedMainRepository = StubFeedRepository()

  override func setUpWithError() throws {
    try super.setUpWithError()

    Container.shared.docsetsModuleInitializer()()
    Container.shared.searchModuleInitializer()()

    Container.shared.repositoryRegistry().registerRepository(stubbedMainRepository, forIdentifier: .main)

    try FileManager.default.createDirectory(atPath: LocalFileSystem.downloadsAbsolutePath, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try super.tearDownWithError()
    try FileManager.default.removeItem(atPath: LocalFileSystem.downloadsAbsolutePath)
  }

  func testFetchDocsetUpdates() async throws {
    try await installFixtureDocset()

    try await Task.sleep(for: .milliseconds(1000))

    stubbedMainRepository.feeds = [
      StubFeed(
        repository: .main,
        id: "Vim",
        displayName: "Vim",
        aliases: [],
        author: nil,
        shouldHideVersions: false,
        supportsArchiveIndex: false,
        icon: EntryIcon.bundled(.docsetIcon(.vim)),
        latestVersion: "10.0"
      ),
    ]

    let updates = await docsetUpdateChecker.fetchDocsetUpdates(useCachedEntries: false)

    XCTAssertEqual(updates.count, 1)
    XCTAssertEqual(updates.first?.feedEntry.feed.id, "Vim")
    XCTAssertEqual(updates.first?.feedEntry.version, "10.0")
  }

  private func installFixtureDocset() async throws {
    let fileManager = FileManager.default

    let downloadsPath = LocalFileSystem.downloadsAbsolutePath

    try fileManager.copyItem(
      atPath: Bundle.module.path(forResource: "TestResources/Vim.tgz")!,
      toPath: downloadsPath.appendingPathComponent("Vim-9.0-latest-main.tgz")
    )

    let _ = try await awaitPublisher(
      libraryDocsetsManager.installOrUpdateDocset(
        forEntry: FeedEntry(
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
          isTrackedAsLatest: true,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        usingTarix: false
      )
    )
  }

}
