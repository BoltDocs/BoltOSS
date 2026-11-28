//
// Copyright (C) 2025 Bolt Contributors
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

import XCTest

import BoltDocsetsTestResources
import BoltTestingUtils
import BoltTypes
import BoltUtils

import Factory

@testable import BoltDocsets

@MainActor
final class DocsetInstallerTests: XCTestCase {

  override func setUp() {
    super.setUp()
    Container.shared.manager.push()
    try? FileManager.default.createDirectory(at: LocalFileSystem.downloadsURL, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(at: LocalFileSystem.docsetsURL, withIntermediateDirectories: true)
  }

  override func tearDown() {
    super.tearDown()
    Container.shared.manager.pop()
  }

  func testInstallDocset_removesWALFiles() async throws {
    let fileManager = FileManager.default

    let downloadsPath = LocalFileSystem.downloadsAbsolutePath

    try fileManager.copyItem(
      atPath: Bundle.boltDocsetsTests.path(forResource: "TestResources/Flask.tgz")!,
      toPath: downloadsPath.appendingPathComponent("Flask-3.1.0-main.tgz")
    )

    let docsetsPathContentsBefore = Set(
      try fileManager.contentsOfDirectory(
        atPath: LocalFileSystem.docsetsAbsolutePath
      )
    )

    let _ = try await awaitPublisher(
      Container.shared.docsetInstaller().installDocset(
        forEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "Flask",
            displayName: "Flask",
            aliases: [],
            author: nil,
            shouldHideVersions: false,
            supportsArchiveIndex: false,
            icon: EntryIcon.bundled(.docsetIcon(.flask))
          ),
          version: "3.1.0",
          isTrackedAsLatest: false,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        usingTarix: false
      )
    )

    let docsetsPathContentsAfter = Set(
      try fileManager.contentsOfDirectory(
        atPath: LocalFileSystem.docsetsAbsolutePath
      )
    )

    let newDocsetPath = docsetsPathContentsAfter.subtracting(docsetsPathContentsBefore)

    XCTAssertEqual(newDocsetPath.count, 1)

    let resourcesPath = LocalFileSystem.docsetsAbsolutePath
      .appendingPathComponent(newDocsetPath.first!)
      .appendingPathComponent("Flask.docset/Contents/Resources")

    XCTAssert(fileManager.fileExists(atPath: resourcesPath.appendingPathComponent("docSet.dsidx"), isDirectory: nil))
    XCTAssert(!fileManager.fileExists(atPath: resourcesPath.appendingPathComponent("docSet.dsidx-wal"), isDirectory: nil))
    XCTAssert(!fileManager.fileExists(atPath: resourcesPath.appendingPathComponent("docSet.dsidx-shm"), isDirectory: nil))
  }

  func testInstallDocset_persistsDisplayName() async throws {
    let fileManager = FileManager.default

    let uuid = UUID()
    let docsetsPath = LocalFileSystem.docsetsAbsolutePath.appendingPathComponent(uuid.uuidString)
    let destPath = docsetsPath.appendingPathComponent("Vim.docset")

    try fileManager.createDirectory(atPath: docsetsPath, withIntermediateDirectories: true)
    defer {
      try? fileManager.removeItem(atPath: docsetsPath)
    }

    let sourceDocsetPath = try XCTUnwrap(
      Bundle.boltDocsetsTests.path(forResource: "TestResources/Vim.docset")
    )

    try fileManager.copyItem(atPath: sourceDocsetPath, toPath: destPath)

    let feedEntry = FeedEntry(
      feed: StubFeed(
        repository: .main,
        id: "Vim_Custom",
        displayName: "Vim Custom Display Name",
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
    )

    try Container.shared.docsetInstaller().installDocset(
      forEntry: feedEntry,
      docsetPath: destPath,
      uuid: uuid
    )

    try fileManager.removeItem(atPath: docsetsPath)

    let libraryDocsetsManager = Container.shared.libraryDocsetsManager()
    let brokenResult = try await awaitPublisher(
      libraryDocsetsManager.installedDocsetsPublisher
        .compactMap { results in
          results.first { $0.record.uuid == uuid }
        }
        .first()
    )

    if case let .broken(installation) = brokenResult {
      XCTAssertEqual(installation.name, "Vim_Custom")
      XCTAssertEqual(installation.displayName, "Vim Custom Display Name")
      XCTAssertEqual(brokenResult.record.displayName, "Vim Custom Display Name")
    } else {
      XCTFail("Expected result to be .broken, got \(brokenResult)")
    }
  }

  func testDocsetInstallation_displayNameDefaultsToName() {
    let installation = DocsetInstallation(
      name: "Apache_HTTP_Server",
      version: DocsetVersion(rawValue: "2.4"),
      installedAsLatestVersion: false,
      repository: .main
    )
    XCTAssertEqual(installation.displayName, "Apache_HTTP_Server")
  }

}
