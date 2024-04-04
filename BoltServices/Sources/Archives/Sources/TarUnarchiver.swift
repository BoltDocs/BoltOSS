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
import ObjectiveC

import Gzip
import SWCompressionTAR
import UUIDShortener

import BoltCombineExtensions
import BoltTypes
import BoltUtils

public struct TarUnarchiver: LoggerProvider {

  public static func extractGzippedTarFile(
    fromSourcePath sourcePath: String,
    toDestPath destPath: String,
    usingQueue queue: DispatchQueue = DispatchQueue.main
  ) -> AnyPublisher<PercentageProgress<String>, Error> {
    Publishers.Create { subscriber in
      let cancellable = BooleanCancellable()
      queue.asyncSafe {
        do {
          try performWithGunzippedFile(forSourceURL: URL(fileURLWithPath: sourcePath)) { tarURL in
            let fileHandle = try FileHandle(forReadingFrom: tarURL)
            defer {
              fileHandle.closeFile()
            }
            let fileSize = try fileHandle.seekToEnd()
            try fileHandle.seek(toOffset: 0)

            try autoreleasepool {
              var tarReader = TarReader(fileHandle: fileHandle)
              while let entry = try tarReader.read() {
                try cancellable.checkCancellation()
                guard let data = entry.data else {
                  continue
                }
                let info = entry.info
                let targetURL = URL(fileURLWithPath: destPath.appendingPathComponent(info.name))
                let directoryURL = targetURL.deletingLastPathComponent()
                do {
                  try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                  try data.write(to: targetURL, options: .atomic)
                  if let offset = try? fileHandle.offset() {
                    subscriber.send(.progress(Double(offset) / Double(fileSize)))
                  }
                } catch {
                  Self.logger.error("Failed to extract file to URL: \(targetURL), error: \(error.localizedDescription)")
                }
              }
            }
            subscriber.send(.completed(path: destPath))
            subscriber.send(completion: .finished)
          }
        } catch {
          if error is CombineExtensions.CancellationError {
            return
          }
          subscriber.send(completion: .failure(error))
        }
      }
      return cancellable
    }
    .eraseToAnyPublisher()
  }

  public static func rawDataFromTarFile(tarAbsoluteURL: URL, blockLength: Int, offset: UInt64) throws -> (String, Data?)? {
    do {
      let handle = try FileHandle(forReadingFrom: tarAbsoluteURL)
      defer {
        try? handle.close()
      }

      var tarixData = try Gzip.gunzipped(fromFileHandle: handle, offset: offset, outputSize: blockLength * 512, wBits: -Gzip.maxWindowBits)

      // Append 1024 byte EOF block to prevent parsing failure
      let EOFBlock = [UInt8](repeating: 0, count: 1024)
      tarixData.append(contentsOf: EOFBlock)

      let tarContainer = try TarContainer.open(container: tarixData)
      if let entry = tarContainer.first {
        return (entry.info.name, entry.data)
      }
      return nil
    } catch {
      Self.logger.error("Failed to extract tarix file at: \(tarAbsoluteURL) error: \(error.localizedDescription)")
      throw error
    }
  }

  public static func rawDataFromTarFile(
    tarAbsoluteURL: URL,
    blockLength: Int,
    offset: UInt64,
    usingQueue queue: DispatchQueue
  ) async throws -> (String, Data?)? {
    return try await withCheckedThrowingContinuation { continuation in
      queue.asyncSafe {
        do {
          let result = try Self.rawDataFromTarFile(tarAbsoluteURL: tarAbsoluteURL, blockLength: blockLength, offset: offset)
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  private static func performWithGunzippedFile(forSourceURL sourceURL: URL, perform: ((URL) throws -> Void)) throws {
    let tarURL = try autoreleasepool {
      let gzippedTarData = try Data(contentsOf: sourceURL)
      let tarData = try gzippedTarData.gunzipped()

      let tmpPath: String
      if RuntimeEnvironment.isRunningTests {
        tmpPath = NSTemporaryDirectory()
      } else {
        tmpPath = LocalFileSystem.applicationTempAbsolutePath
      }

      let tarURL = URL(fileURLWithPath: tmpPath)
        .appendingPathComponent(
          "\(sourceURL.deletingPathExtension().lastPathComponent)_\(try UUID().shortened(using: .base62))"
        )
        .appendingPathExtension("tar")
      try tarData.write(to: tarURL)
      return tarURL
    }
    defer {
      try? FileManager.default.removeItem(at: tarURL)
    }
    try perform(tarURL)
  }

}
