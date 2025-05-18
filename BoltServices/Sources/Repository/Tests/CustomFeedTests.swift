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

import BoltNetworkingTestStubs
import BoltTypes

@testable import BoltRepository

final class CustomFeedTests: NetworkingStubbedTestCase {

  override var fetchEntriesStubs: [String: String] {
    return [
      "https://test.internal/Alamofire.xml": """
      <entry>
        <version>5.6.4</version>
        <url>https://alamofire.github.io/Alamofire/docsets/Alamofire.tgz</url>
      </entry>
      """,
      "https://test.internal/multiple-urls.xml": """
      <entry>
        <version>1.0.0</version>
        <url>https://test.internal/1.tgz</url>
        <url>https://test.internal/2.tgz</url>
        <url>https://test.internal/3.tgz</url>
      </entry>
      """,
      "https://test.internal/other-versions.xml": """
      <entry>
        <version>1.0.0</version>
        <url>https://test.internal/TestFeed.tgz</url>
        <other-versions>
          <version><name>1.0.0</name></version>
          <version><name>0.1.1</name></version>
        </other-versions>
      </entry>
      """,
      "https://test.internal/other-versions-malformed-1.xml": """
      <entry>
        <version>1.0.0</version>
        <url>https://test.internal/TestFeed.tgz</url>
        <other-versions>
          <version><name>1.0.0</name></version>
        </other-versions>
        <other-versions>
          <version><name>0.1.1</name></version>
        </other-versions>
      </entry>
      """,
      "https://test.internal/other-versions-malformed-2.xml": """
      <entry>
        <version>1.0.0</version>
        <url>https://test.internal/TestFeed.tgz</url>
        <other-versions>
          <version>0.1.1</version>
        </other-versions>
      </entry>
      """,
      "https://test.internal/other-versions-malformed-3.xml": """
      <entry>
        <version>1.0.0</version>
        <url>https://test.internal/</url>
        <other-versions>
          <version><name>1.0.0</name></version>
        </other-versions>
      </entry>
      """,
    ]
  }

  func testFetchEntriesForCustomFeed() async throws {
    let feed = CustomFeed(
      entity: CustomFeedEntity(
        name: "Alamofire",
        urlString: "https://test.internal/Alamofire.xml"
      )
    )
    let feedEntries = try await feed.fetchEntries()
    XCTAssertTrue(feedEntries.shouldHideVersions)

    let items = feedEntries.items
    XCTAssertEqual(items.count, 1)

    XCTAssertEqual(items[0].feed.id, feed.id)
    XCTAssertEqual(items[0].version, "5.6.4")
    XCTAssertTrue(items[0].isTrackedAsLatest)
    XCTAssertEqual(
      items[0].docsetLocation as! URLResourceLocation,
      ResourceLocations.URL(URL(string: "https://alamofire.github.io/Alamofire/docsets/Alamofire.tgz")!) as! URLResourceLocation
    )
  }

  func testFetchEntriesForCustomFeedWithMultipleURL() async throws {
    let feed = CustomFeed(
      entity: CustomFeedEntity(
        name: "TestFeed",
        urlString: "https://test.internal/multiple-urls.xml"
      )
    )
    let feedEntries = try await feed.fetchEntries().items
    XCTAssertEqual(feedEntries.count, 1)
    XCTAssertEqual(feedEntries[0].feed.id, feed.id)
    XCTAssertEqual(feedEntries[0].version, "1.0.0")
    XCTAssertTrue(feedEntries[0].isTrackedAsLatest)
    XCTAssertEqual(
      feedEntries[0].docsetLocation as! URLResourceLocation,
      ResourceLocations.URL(URL(string: "https://test.internal/1.tgz")!) as! URLResourceLocation
    )
  }

  func testFetchEntriesForCustomFeedWithOtherVersions() async throws {
    let feed = CustomFeed(
      entity: CustomFeedEntity(
        name: "TestFeed",
        urlString: "https://test.internal/other-versions.xml"
      )
    )

    let feedEntries = try await feed.fetchEntries()
    XCTAssertFalse(feedEntries.shouldHideVersions)

    let items = feedEntries.items
    XCTAssertEqual(items.count, 3)

    XCTAssertEqual(items[0].feed.id, feed.id)
    XCTAssertEqual(items[0].version, "1.0.0")
    XCTAssertTrue(items[0].isTrackedAsLatest)
    XCTAssertEqual(
      items[0].docsetLocation as! URLResourceLocation,
      ResourceLocations.URL(URL(string: "https://test.internal/TestFeed.tgz")!) as! URLResourceLocation
    )

    XCTAssertEqual(items[1].feed.id, feed.id)
    XCTAssertEqual(items[1].version, "1.0.0")
    XCTAssertFalse(items[1].isTrackedAsLatest)
    XCTAssertEqual(
      items[1].docsetLocation as! URLResourceLocation,
      ResourceLocations.URL(URL(string: "https://test.internal/zzz/versions/TestFeed/1.0.0/TestFeed.tgz")!) as! URLResourceLocation
    )
  }

  func testFetchEntriesForCustomFeedWithOtherVersionsMalformed() async throws {
    try await {
      let feed = CustomFeed(
        entity: CustomFeedEntity(
          name: "TestFeed",
          urlString: "https://test.internal/other-versions-malformed-1.xml"
        )
      )
      let feedEntries = try await feed.fetchEntries()
      XCTAssertEqual(feedEntries.items.count, 3)
    }()
    try await {
      let feed = CustomFeed(
        entity: CustomFeedEntity(
          name: "TestFeed",
          urlString: "https://test.internal/other-versions-malformed-2.xml"
        )
      )
      let feedEntries = try await feed.fetchEntries()
      XCTAssertFalse(feedEntries.shouldHideVersions)
      XCTAssertEqual(feedEntries.items.count, 1)
    }()
    try await {
      let feed = CustomFeed(
        entity: CustomFeedEntity(
          name: "TestFeed",
          urlString: "https://test.internal/other-versions-malformed-3.xml"
        )
      )
      let feedEntries = try await feed.fetchEntries()
      XCTAssertEqual(feedEntries.items.count, 1)
    }()
  }

}
