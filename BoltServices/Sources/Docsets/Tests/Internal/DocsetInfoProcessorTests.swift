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

import Factory

@testable import BoltDocsets
import BoltTestingUtils
import BoltTypes

final class DocsetInfoProcessorTests: XCTestCase {

  override func setUp() {
    super.setUp()
    Container.shared.manager.push()
    Container.shared.docsetInfoProcessor().registerDocsetInfoProcessor(
      StubbedRepoDocsetInfoProcessor(),
      forIdentifier: .userContributed
    )
  }

  override static func tearDown() {
    super.tearDown()
    Container.shared.manager.pop()
  }

  func testProcessFallbackURL() throws {
    let docsetInfoProcessor = Container.shared.docsetInfoProcessor()

    let infoDictWithFallback: InfoDictionary = [
      "CFBundleIdentifier": "com.jazzy.rxswift",
      "CFBundleName": "RxSwift",
      "DashDocSetFallbackURL": "https://docs.rxswift.org",
      "DocSetFallbackURL": "https://other.rxswift.org",
    ]

    let docsetInfoWithFallback = docsetInfoProcessor.docsetInfo(forInfoDictionary: infoDictWithFallback)
    XCTAssertEqual(docsetInfoWithFallback.fallbackURL?.absoluteString, "https://docs.rxswift.org")

    let infoDictWithLegacyFallback: InfoDictionary = [
      "CFBundleIdentifier": "com.jazzy.rxswift",
      "CFBundleName": "RxSwift",
      "DocSetFallbackURL": "https://docs.rxswift.org",
    ]

    let docsetInfoWithLegacyFallback = docsetInfoProcessor.docsetInfo(forInfoDictionary: infoDictWithLegacyFallback)
    XCTAssertEqual(docsetInfoWithLegacyFallback.fallbackURL?.absoluteString, "https://docs.rxswift.org")
  }

  func testProcessForInstallationWithRepoProcessor() throws {
    let docsetInfoProcessor = Container.shared.docsetInfoProcessor()

    let dataBefore = try Data(contentsOf: Bundle.module.url(forResource: "TestResources/RxSwift/Info.plist")!)
    let infoDictBefore = InfoDictionary(propertyListData: dataBefore)

    let dataAfter = try Data(contentsOf: Bundle.module.url(forResource: "TestResources/RxSwift/Info_installed.plist")!)
    let infoDictExpected = InfoDictionary(propertyListData: dataAfter)

    let infoDictAfter = docsetInfoProcessor.processForInstallation(
      withInfoDictionary: try XCTUnwrap(infoDictBefore),
      forFeedEntry: FeedEntry(
        feed: StubFeed(
          repository: .userContributed,
          id: "RxSwift",
          displayName: "RxSwift",
          aliases: [],
          author: nil,
          shouldHideVersions: false,
          supportsArchiveIndex: false,
          icon: EntryIcon.providerDefault
        ),
        version: "9.0",
        isTrackedAsLatest: false,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      )
    )
    XCTAssertEqual(
      infoDictAfter as NSDictionary,
      try XCTUnwrap(infoDictExpected) as NSDictionary
    )
  }

}
