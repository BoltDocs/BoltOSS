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

import Combine
import Foundation

import GRDB

import BoltCombineExtensions
import BoltUtils

public enum DocsetUnarchiverError: Error {

  case tarixNotFound
  case docsetNotFound
  case tarIndexNoMatchFound
  case tarIndexBadFormat

}

public struct TarixUnarchiver: LoggerProvider {

  public static func dataFromIndexedTar(
    tarFilePath tarPath: String,
    tarixDBPath tarixPath: String,
    atPath path: String,
    usingQueue queue: DispatchQueue = DispatchQueue.main
  ) async throws -> (String, Data?)? {
    let dbQueue = try DatabaseQueue(path: tarixPath)
    let (blockLength, offset) = try await dbQueue.read { db -> (Int, UInt64) in
      let selectStatement = try db.cachedStatement(
        sql: "SELECT * FROM tarindex WHERE PATH = ?"
      )
      guard let index = try TarIndex.fetchOne(selectStatement, arguments: [path]) else {
        throw DocsetUnarchiverError.tarIndexNoMatchFound
      }
      guard let blockLength = index.blockLength, let offset = index.offset else {
        throw DocsetUnarchiverError.tarIndexBadFormat
      }
      return (blockLength, offset)
    }
    return try await TarUnarchiver.rawDataFromTarFile(
      tarAbsoluteURL: URL(fileURLWithPath: tarPath),
      blockLength: blockLength,
      offset: offset,
      usingQueue: queue
    )
  }

  public static func extractListedFiles(
    forTarix tarixPath: String,
    fromTarFile tarPath: String,
    toPath destPath: String,
    usingQueue queue: DispatchQueue = DispatchQueue.main
  ) -> AnyPublisher<PercentageProgress<String>, Error> {
    let extractFilesForIndices: ([TarIndex]) -> AnyPublisher<PercentageProgress<String>, Error> = { indices in
      return Publishers.Create<PercentageProgress<String>, Error> { subscriber in
        let cancellable = BooleanCancellable()
        queue.asyncSafe {
          do {
            var counter = 0
            for index in indices {
              try cancellable.checkCancellation()
              guard let blockLength = index.blockLength, let offset = index.offset else {
                continue
              }
              do {
                if
                  let (filename, data) = try TarUnarchiver.rawDataFromTarFile(
                    tarAbsoluteURL: URL(fileURLWithPath: tarPath),
                    blockLength: blockLength,
                    offset: offset
                  ),
                  let data = data
                {
                  let destURL = URL(fileURLWithPath: destPath).appendingPathComponent(filename)
                  let directoryURL = destURL.deletingLastPathComponent()
                  try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                  try data.write(to: destURL, options: .atomic)
                  Self.logger.info("Extracted file at: \(destURL)")
                }
              } catch {
                Self.logger.error("Failed to extract file for path: \(index.path)")
              }
              counter += 1
              subscriber.send(PercentageProgress.progress(Double(counter) / Double(indices.count)))
            }
            subscriber.send(completion: .finished)
          } catch {
            assert(error is CombineExtensions.CancellationError)
          }
        }
        return cancellable
      }
      .eraseToAnyPublisher()
    }

    return Deferred { Future<[TarIndex], Error> { promise in
      queue.asyncSafe {
        do {
          let dbQueue = try DatabaseQueue(path: tarixPath)
          try dbQueue.read { db in
            let selectStatement = try db.cachedStatement(
              sql: "SELECT * FROM toextract"
            )
            let tarIndex = try TarIndex.fetchAll(selectStatement)
            promise(.success(tarIndex))
          }
        } catch {
          promise(.failure(error))
        }
        // swiftlint:disable:next closure_end_indentation
      } }
    }
    .flatMap { extractFilesForIndices($0) }
    .append(PercentageProgress.completed(path: destPath))
    .eraseToAnyPublisher()
  }

}
