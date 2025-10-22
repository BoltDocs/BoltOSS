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

import GRDB

import BoltTestingUtils

@testable import BoltArchives

struct TarixUnarchiverTests {

  @Test func dataFromIndexedTar() async throws {
    let dbQueue = try DatabaseQueue(path: Bundle.module.path(forResource: "TestResources/Bash", ofType: "tarix")!)
    let indices = try await dbQueue.read { db -> [TarIndex] in
      let selectStatement = try db.cachedStatement(
        sql: "SELECT * FROM tarindex"
      )
      return try TarIndex.fetchAll(selectStatement)
    }
    try dbQueue.close()

    for index in indices {
      let res = try await TarixUnarchiver.dataFromIndexedTar(
        tarFilePath: Bundle.module.path(forResource: "TestResources/Bash", ofType: "tgz")!,
        tarixDBPath: Bundle.module.path(forResource: "TestResources/Bash", ofType: "tarix")!,
        atPath: index.path
      )
      try #require(res != nil)
      let (path, data) = res!
      try #require(path == index.path)

      let fileData = try Data(contentsOf: Bundle.module.resourceURL!.appendingPathComponent("TestResources").appendingPathComponent(path))
      try #require(data == fileData)
    }
  }

  @Test func extractListedFiles() async throws{
    let destPath = NSTemporaryDirectory().appendingPathComponent(UUID().uuidString)
    let publisher = TarixUnarchiver.extractListedFiles(
      forTarix: Bundle.module.path(forResource: "TestResources/Bash", ofType: "tarix")!,
      fromTarFile: Bundle.module.path(forResource: "TestResources/Bash", ofType: "tgz")!,
      toPath: destPath
    )

    let result = try await awaitPublisherForSwiftTesting(publisher)

    guard case let .completed(path) = result else {
      Issue.record("not returning success")
      return
    }

    #expect(path == destPath)

    #expect(FileManager.default.contentsEqual(atPath: path.appendingPathComponent("Bash.docset"), andPath: Bundle.module.path(forResource: "TestResources/Bash_with_tarix", ofType: "docset")!))
  }

}
