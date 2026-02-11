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

/// https://medium.com/over-engineering/monitoring-a-folder-for-changes-in-ios-dc3f8614f902

import Foundation

public final class FolderMonitor: Sendable {

  // MARK: Properties

  /// A file descriptor for the monitored directory.
  nonisolated(unsafe) private var monitoredFolderFileDescriptor: CInt = -1

  /// A dispatch source to monitor a file descriptor created from the directory.
  nonisolated(unsafe) private var folderMonitorSource: DispatchSourceFileSystemObject?

  /// URL for the directory being monitored.
  public let url: URL

  private let folderDidChange: (@Sendable () -> Void)

  /// A dispatch queue used for sending file changes in the directory.
  private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)

  // MARK: Initializers

  public init(url: URL, folderDidChange: @escaping @Sendable () -> Void) {
    self.url = url
    self.folderDidChange = folderDidChange
  }

  deinit {
    stopMonitoring()
  }

  // MARK: Monitoring

  /// Listen for changes to the directory (if we are not already).
  @MainActor
  public func startMonitoring() {
    guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
      return
    }

    // Open the directory referenced by URL for monitoring only.
    let descriptor = open(url.path, O_EVTONLY)

    if descriptor == -1 {
      return
    }

    // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
    let dispatchSource = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: descriptor,
      eventMask: .write,
      queue: folderMonitorQueue
    )

    // Define the block to call when a file change is detected.
    dispatchSource.setEventHandler { @Sendable [weak self] in
      self?.folderDidChange()
    }

    // Define a cancel handler to ensure the directory is closed when the source is cancelled.
    dispatchSource.setCancelHandler { @Sendable [weak self] in
      guard let self = self else {
        return
      }
      Task { @MainActor in
        close(monitoredFolderFileDescriptor)
        monitoredFolderFileDescriptor = -1
        folderMonitorSource = nil
      }
    }

    // Start monitoring the directory via the source.
    dispatchSource.resume()

    folderMonitorSource = dispatchSource
    monitoredFolderFileDescriptor = descriptor
  }

  /// Stop listening for changes to the directory, if the source has been created.
  public func stopMonitoring() {
    folderMonitorSource?.cancel()
  }

}
