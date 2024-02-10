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

import CombineExt

import BoltUtils

protocol BackgroundDownloaderProgressDelegate: AnyObject {

  func downloaderDidUpdateSessionIDs(sessionIDs: [BackgroundDownloader.SessionTaskIdentifier])

  func downloaderDidFinishDownload(forSessionID sessionID: BackgroundDownloader.SessionTaskIdentifier)

  func downloaderRemoveTask(forSessionID sessionID: BackgroundDownloader.SessionTaskIdentifier)

  func downloaderRemoveAllTasks()

  func downloaderGetDestinationPath(forSessionID sessionID: BoltDocsets.BackgroundDownloader.SessionTaskIdentifier) -> String?

}

typealias BackgroundDownloaderDelegate = BackgroundDownloaderProgressDelegate

extension CurrentValueRelay {

  func update(_ block: (Output) -> Output) {
    var value = self.value
    value = block(value)
    accept(value)
  }

}

class BackgroundDownloader: NSObject, LoggerProvider {

  enum Errors: LocalizedError {

    case undeterminedDestinationPath(sessionID: SessionTaskIdentifier)

    var errorDescription: String? {
      switch self {
      case let .undeterminedDestinationPath(sessionID):
        return "Could not determine destination path for session task identifier: \(sessionID)"
      }
    }

  }

  typealias SessionTaskIdentifier = Int

  enum Progress {
    case pending
    case downloading(receivedBytes: Int64, expectedBytes: Int64)
    case failed(_: Error)
  }

  var backgroundDownloadCompletionHandler: (() -> Void)?

  private let dataSource: BackgroundDownloaderDelegate!

  private lazy var sessionProgressesRelay = CurrentValueRelay<[SessionTaskIdentifier: Progress]>([:])

  private lazy var urlSession: URLSession = {
    let config: URLSessionConfiguration
    if RuntimeEnvironment.isRunningTests {
      config = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
    } else {
      config = URLSessionConfiguration.background(withIdentifier: "app.BoltDocs.Bolt.DocsetDownloader")
    }
    config.sessionSendsLaunchEvents = true
    config.urlCredentialStorage = nil
    if RuntimeEnvironment.isRunningTests {
      config.timeoutIntervalForResource = 15
    } else {
      config.timeoutIntervalForResource = 6 * 3600
    }
    return URLSession(configuration: config, delegate: self, delegateQueue: nil)
  }()

  init(dataSource: BackgroundDownloaderDelegate) {
    self.dataSource = dataSource
    super.init()

    // Remove unneeded tasks
    urlSession.getAllTasks { [weak self] tasks in
      guard let self = self else {
        return
      }

      let sessionIDs = tasks.map { $0.taskIdentifier }

      self.dataSource.downloaderDidUpdateSessionIDs(sessionIDs: sessionIDs)

      var sessionProgresses = self.sessionProgressesRelay.value
      for identifier in sessionIDs where sessionProgresses[identifier] == nil {
        sessionProgresses[identifier] = .pending
      }
      self.sessionProgressesRelay.accept(sessionProgresses)
    }
  }

  @discardableResult
  func startDownload(url: URL) -> SessionTaskIdentifier? {
    let backgroundTask = urlSession.downloadTask(with: url)

    let sessionID = backgroundTask.taskIdentifier
    if sessionProgressesRelay.value[sessionID] == nil {
      sessionProgressesRelay.update { progress in
        var progress = progress
        progress[sessionID] = .pending
        return progress
      }
    }

    backgroundTask.resume()

    return sessionID
  }

  func cancelDownload(forSessionID sessionID: SessionTaskIdentifier) async {
    if sessionProgressesRelay.value[sessionID] != nil {
      sessionProgressesRelay.update { progresses in
        var progresses = progresses
        progresses[sessionID] = nil
        return progresses
      }
    }
    if let task = (await urlSession.allTasks).first(where: { $0.taskIdentifier == sessionID }) {
      task.cancel()
    }
    self.dataSource.downloaderRemoveTask(forSessionID: sessionID)
  }

  func progress(forSessionID sessionID: SessionTaskIdentifier) -> AnyPublisher<Progress?, Never> {
    return sessionProgressesRelay
      .map { $0[sessionID] }
      .eraseToAnyPublisher()
  }

  func sessionProgressValue() -> [SessionTaskIdentifier: Progress] {
    return sessionProgressesRelay.value
  }

  func stopAllTasks() async {
    await urlSession.stopAllTasks()
    dataSource.downloaderRemoveAllTasks()
    sessionProgressesRelay.accept([:])
  }

  func clearCache() async {
    await stopAllTasks()
    await urlSession.reset()
  }

}

extension BackgroundDownloader: URLSessionDelegate, URLSessionDownloadDelegate {

  // MARK: - URLSessionDownloadDelegate

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error = error else {
      return
    }
    let sessionID = task.taskIdentifier
    Self.logger.info("task: \(task) didCompleteWithError: \(String(describing: error))")
    if sessionProgressesRelay.value[sessionID] != nil {
      sessionProgressesRelay.update { progress in
        var progress = progress
        progress[sessionID] = .failed(error)
        return progress
      }
    }
  }

  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    let calculatedProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

    Self.logger.info("task: \(downloadTask), progress: \(calculatedProgress)")
    sessionProgressesRelay.update { progress in
      var progress = progress
      progress[downloadTask.taskIdentifier] = .downloading(
        receivedBytes: totalBytesWritten,
        expectedBytes: totalBytesExpectedToWrite
      )
      return progress
    }
  }

  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    Self.logger.info("Finished downloading for task: \(downloadTask) at location: \(location)")

    let identifier = downloadTask.taskIdentifier

    var progresses = sessionProgressesRelay.value

    defer {
      sessionProgressesRelay.accept(progresses)
    }

    do {
      let fileManager = FileManager.default
      guard let path = dataSource.downloaderGetDestinationPath(forSessionID: downloadTask.taskIdentifier) else {
        Self.logger.warning("task: \(downloadTask) (identifier: \(downloadTask.taskIdentifier)) has no trakced identifier")
        throw Errors.undeterminedDestinationPath(sessionID: downloadTask.taskIdentifier)
      }

      let destination = URL(fileURLWithPath: path)

      if fileManager.fileExists(atPath: destination.path) {
        try fileManager.removeItem(at: destination)
      }
      let directory = destination.deletingLastPathComponent()
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
      try fileManager.moveItem(at: location, to: destination)

      dataSource.downloaderDidFinishDownload(forSessionID: downloadTask.taskIdentifier)

      progresses[identifier] = nil
    } catch {
      progresses[identifier] = .failed(error)
    }
  }

  // MARK: - URLSessionDelegate

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    Self.logger.info("urlSessionDidFinishEvents for session: \(session)")
    backgroundDownloadCompletionHandler?()
  }

}
