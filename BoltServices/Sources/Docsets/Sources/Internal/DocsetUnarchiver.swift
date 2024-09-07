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
import struct os.Logger

import GRDB

import BoltArchives
import BoltCombineExtensions
import BoltTypes
import BoltUtils

struct DocsetUnarchiver: LoggerProvider {

  private static var unarchiverQueue = DispatchQueue(
    label: "app.BoltDocs.Bolt.DocsetUnarchiver",
    qos: .userInitiated,
    attributes: .concurrent
  )

  static func unarchiveDownloadedDocset(
    toPath path: String,
    forFeedEntry entry: FeedEntry,
    usingTarix: Bool
  ) -> AnyPublisher<PercentageProgress<String>, Error> {
    if usingTarix {
      let downloadedTarPath = entry.downloadAbsolutePath(withExtension: "tgz")
      let downloadedTarixPath = entry.downloadAbsolutePath(withExtension: "tgz.tarix")
      return unarchiveDownloadedDocsetUsingTarix(
        downloadedTarPath: downloadedTarPath,
        downloadedTarixPath: downloadedTarixPath,
        toPath: path,
        forFeedEntry: entry
      )
    } else {
      let downloadedTarPath = entry.downloadAbsolutePath(withExtension: "tgz")
      return unarchiveDownloadedDocsetWithoutTarix(
        downloadedTarPath: downloadedTarPath,
        toPath: path,
        forFeedEntry: entry
      )
    }
  }

  static func unarchiveDownloadedDocsetWithoutTarix(
    downloadedTarPath: String,
    toPath destPath: String,
    forFeedEntry entry: FeedEntry
  ) -> AnyPublisher<PercentageProgress<String>, Error> {
    // installing a docset WITHOUT tarix
    //   i. check the .tgz file exists
    //  ii. extract the tgz file
    // iii. move the .docset directory to the dest location

    let fileManager = FileManager.default

    Self.logger.info(
      """
      Unarchive docset without tarix, with \
      tarPath: \(downloadedTarPath), \
      destPath: \(destPath)
      """
    )

    if fileManager.fileExists(atPath: destPath) {
      try? fileManager.removeItem(atPath: destPath)
    }

    return Publishers.Create<PercentageProgress<String>, Error> { subscriber -> Cancellable in
      return TarUnarchiver.extractGzippedTarFile(fromSourcePath: downloadedTarPath, toDestPath: destPath, usingQueue: unarchiverQueue)
        // swiftlint:disable:next trailing_closure
        .handleEvents(receiveOutput: { progress in
          if case let .progress(progress) = progress {
            subscriber.send(.progress(progress))
          }
        })
        .filter { $0.isCompleted }
        .tryMap { _ -> String in
          // search for the extracted docset file
          guard
            let extractedDocsetFilename = fileManager.contentsOfDirectory(
              atPath: destPath,
              ofExtension: "docset"
          ).first else {
            throw DocsetUnarchiverError.docsetNotFound
          }
          return destPath.appendingPathComponent(extractedDocsetFilename)
        }
        .tryMap { docsetPath in
          let resourcesPath = docsetPath.appendingPathComponent("Contents/Resources")
          if !fileManager.fileExists(atPath: resourcesPath) {
            try fileManager.createDirectory(atPath: resourcesPath, withIntermediateDirectories: true)
          }
          return docsetPath
        }
        .sink(receiveCompletion: { completion in
          if case let .failure(error) = completion {
            subscriber.send(completion: .failure(error))
          }
        }, receiveValue: { docsetPath in
          subscriber.send(PercentageProgress.completed(path: docsetPath))
          subscriber.send(completion: .finished)
        })
    }
    .eraseToAnyPublisher()
  }

  static func unarchiveDownloadedDocsetUsingTarix(
    downloadedTarPath: String,
    downloadedTarixPath: String,
    toPath destPath: String,
    forFeedEntry entry: FeedEntry
  ) -> AnyPublisher<PercentageProgress<String>, Error> {
    // installing a docset WITH tarix
    //   i. check the .tgz and .tgz.tarix file exists
    //  ii. extract the tarix as tgz format, obtain the .tgz.tarix.db file
    // iii. read both toExtract and tarIndex tables from the db
    //  iv. read rows of tarIndex according files listed in toExtract
    //   v. extract these files to the dest location, should got a docset directory
    //  vi. move the tarix to tgz to into the dest docset directory accordingly

    let fileManager = FileManager.default

    Self.logger.info(
      """
      Unarchive docset with \
      tarPath: \(downloadedTarPath), \
      tarixPath: \(downloadedTarixPath), \
      destPath: \(destPath)
      """
    )

    let tarixDBPath = destPath.appendingPathComponent("tarixIndex.db")

    if fileManager.fileExists(atPath: destPath) {
      try? fileManager.removeItem(atPath: destPath)
    }

    return Publishers.Create<PercentageProgress<String>, Error> { subscriber -> Cancellable in
      TarUnarchiver.extractGzippedTarFile(
        fromSourcePath: downloadedTarixPath,
        toDestPath: destPath,
        usingQueue: unarchiverQueue
      )
      // swiftlint:disable:next trailing_closure
      .handleEvents(receiveOutput: { progress in
        if case let .progress(progress) = progress {
          subscriber.send(.progress(0.2 * progress))
        }
      })
      .filter { $0.isCompleted }
      .tryMap { progress in
        // search for the extracted tarix file
        guard let extractedTarixFilename = fileManager.contentsOfDirectory(atPath: destPath, ofExtension: "tgz.tarix").first else {
          throw DocsetUnarchiverError.tarixNotFound
        }
        try fileManager.moveItem(
          atPath: destPath.appendingPathComponent(extractedTarixFilename),
          toPath: tarixDBPath
        )
        return progress
      }
      .flatMap { _ -> AnyPublisher<PercentageProgress<String>, Error> in
        return TarixUnarchiver.extractListedFiles(
          forTarix: tarixDBPath,
          fromTarFile: downloadedTarPath,
          toPath: destPath,
          usingQueue: unarchiverQueue
        )
      }
      // swiftlint:disable:next trailing_closure
      .handleEvents(receiveOutput: { progress in
        if case let .progress(progress) = progress {
          subscriber.send(.progress(0.2 + 0.8 * progress))
        }
      })
      .filter { $0.isCompleted }
      .tryMap { _ -> String in
        // search for the extracted docset file
        guard
          let extractedDocsetFilename = fileManager.contentsOfDirectory(
            atPath: destPath,
            ofExtension: "docset"
        ).first else {
          throw DocsetUnarchiverError.docsetNotFound
        }
        return destPath.appendingPathComponent(extractedDocsetFilename)
      }
      .tryMap { docsetPath in
        let resourcesPath = docsetPath.appendingPathComponent("Contents/Resources")
        if !fileManager.fileExists(atPath: resourcesPath) {
          try fileManager.createDirectory(atPath: resourcesPath, withIntermediateDirectories: true)
        }

        // move tarix and tar to the right location
        try fileManager.moveItem(
          atPath: downloadedTarPath,
          toPath: resourcesPath.appendingPathComponent("tarix.tgz")
        )
        try fileManager.moveItem(
          atPath: tarixDBPath,
          toPath: resourcesPath.appendingPathComponent("tarixIndex.db")
        )
        return docsetPath
      }
      .sink(receiveCompletion: { completion in
        if case let .failure(error) = completion {
          subscriber.send(completion: .failure(error))
        }
      }, receiveValue: { docsetPath in
        subscriber.send(PercentageProgress.completed(path: docsetPath))
        subscriber.send(completion: .finished)
      })
    }
    .eraseToAnyPublisher()
  }

}
