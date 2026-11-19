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
import Testing

import BoltDocsets

struct DocsetFileURLSchemeTests {

  private let docsetUUID = "01234567-89ab-cdef-0123-456789abcdef"

  private static let pathCases: [(path: String, expectedPath: String)] = [
    ("", ""),
    ("/", "/"),
    ("index.html", "/index.html"),
    ("/index.html", "/index.html"),
    ("guide/index.html", "/guide/index.html"),
  ]

  @Test(arguments: pathCases)
  // swiftlint:disable:next attributes
  func urlWithPath(path: String, expectedPath: String) throws {
    let url = try #require(DocsetFileURLScheme(docsetUUID: docsetUUID, path: path).url)
    #expect(url.absoluteString == "bolt-doc-file://\(docsetUUID)\(expectedPath)")
    #expect(url.scheme == "bolt-doc-file")
    #expect(url.host == docsetUUID)
    #expect(url.fragment == nil)
  }

  @Test func urlWithFragment() throws {
    let url = try #require(DocsetFileURLScheme(docsetUUID: docsetUUID, path: "index.html#section").url)
    #expect(url.absoluteString == "bolt-doc-file://\(docsetUUID)/index.html#section")
    #expect(url.path == "/index.html")
    #expect(url.fragment == "section")
  }

  @Test func urlWithEmptyFragment() throws {
    let url = try #require(DocsetFileURLScheme(docsetUUID: docsetUUID, path: "index.html#").url)
    let fragment = try #require(url.fragment)
    #expect(url.absoluteString == "bolt-doc-file://\(docsetUUID)/index.html#")
    #expect(url.path == "/index.html")
    #expect(fragment.isEmpty)
  }

  @Test func urlWithFragmentOnly() throws {
    let url = try #require(DocsetFileURLScheme(docsetUUID: docsetUUID, path: "#section").url)
    #expect(url.absoluteString == "bolt-doc-file://\(docsetUUID)/#section")
    #expect(url.host == docsetUUID)
    #expect(url.fragment == "section")
  }

  @Test func urlWithReservedCharactersInFragment() throws {
    let url = try #require(DocsetFileURLScheme(docsetUUID: docsetUUID, path: "index.html#//apple_ref/c/func/example").url)
    #expect(url.path == "/index.html")
    #expect(url.fragment == "//apple_ref/c/func/example")
  }

  @Test func urlPreservesPercentEncoding() throws {
    let url = try #require(DocsetFileURLScheme(docsetUUID: docsetUUID, path: "guide%20name.html#section%20one").url)
    #expect(url.absoluteString == "bolt-doc-file://\(docsetUUID)/guide%20name.html#section%20one")
    #expect(url.path == "/guide name.html")
    #expect(url.fragment(percentEncoded: true) == "section%20one")
    #expect(url.fragment(percentEncoded: false) == "section one")
  }

}
