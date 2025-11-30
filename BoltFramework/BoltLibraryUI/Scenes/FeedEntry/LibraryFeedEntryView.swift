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
import SwiftUI

import Factory
import RxCombine

import BoltLocalizations
import BoltServices
import BoltUIFoundation
import BoltUtils

private final class DataSource: ObservableObject {

  enum DownloadStatus {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed
  }

  @Injected(\.downloadManager)
  private var downloadManager: DownloadManager

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  private var cancellables = Set<AnyCancellable>()
  private let activityStatusTracker = ActivityStatusTracker<Void, Error>()

  var supportsTarix: Bool {
    return entry.feed.supportsArchiveIndex
  }

  @Published var downloadTarixTrigger: Void = ()
  @Published var statusResult: ActivityStatus<Void, Error> = .idle

  @Published var estimatedSizeStatusResult: Result<Int64?, Error>?

  @Published var downloadStatus: DownloadStatus = .notDownloaded
  @Published var isInstalled = false

  var entry: FeedEntry

  var versionText: String {
    if entry.isTrackedAsLatest {
      return "Latest"
    } else {
      return entry.version
    }
  }

  var fileNameToDisplay: String {
    var name = entry.feed.displayName
    if entry.isTrackedAsLatest {
      name += " (Latest)" // XXX (Latest)
    } else {
      name += " (\(entry.version))" // XXX (x.x.x)
    }
    return name
  }

  var archivePath: String {
    FeedEntry.downloadAbsolutePath(forId: entry.id, withExtension: "tgz")
  }

  init(entry: FeedEntry) {
    self.entry = entry

    libraryDocsetsManager.installedRecordsPublisher
      .map { installations in
        return installations.contains { installation in
          return installation.name == entry.feed.id &&
            installation.version == entry.version &&
            installation.installedAsLatestVersion == entry.isTrackedAsLatest
        }
      }
      .assign(to: &$isInstalled)

    let downloadTarixFuture = Future<Void, Error>.awaitingThrowing { [downloadManager] in
      return try await downloadManager.downloadTarix(forFeedEntry: entry)
    }

    $downloadTarixTrigger
      .filter { [supportsTarix] in supportsTarix }
      .flatMap { _ in
        return downloadTarixFuture.mapToResult()
      }
      .trackActivityStatus(activityStatusTracker)
      .sink { result in
        if case let .failure(error) = result {
          Task { @MainActor in
            GlobalUI.showMessageToast(
              withErrorMessage: ErrorMessage(entity: ErrorMessageEntity.fetchEntriesFailed, nestedError: error)
            )
          }
        }
      }
      .store(in: &cancellables)

    activityStatusTracker
      .status
      .assign(to: &$statusResult)

    downloadManager.progress(forIdentifier: entry.id)
      .map { [archivePath] progress -> DownloadStatus in
        let localFileExists = {
          return FileManager.default.fileExists(
            atPath: URL(
              fileURLWithPath: archivePath
            ).path
          )
        }
        if let progress = progress {
          switch progress {
          case .pending:
            return .downloading(progress: 0.0)
          case let .downloading(receivedSize, expectedSize):
            var progress: Double = 0
            if receivedSize >= 0, expectedSize >= 0 {
              progress = Double(receivedSize) / Double(expectedSize)
            }
            return .downloading(progress: progress)
          case .completed:
            return localFileExists() ? .downloaded : .failed
          case .failed:
            return .failed
          }
        } else {
          return localFileExists() ? .downloaded : .notDownloaded
        }
      }
      .assign(to: &$downloadStatus)
  }

  @MainActor
  func fetchDocsetDownloadSize() async {
    do {
      let val = try await downloadManager.getDocsetByteSize(forFeedEntry: entry)
      estimatedSizeStatusResult = .success(val)
    } catch {
      estimatedSizeStatusResult = .failure(error)
    }
  }

  func deleteArchive() async {
    try? FileManager.default.removeItem(atPath: archivePath)
    await downloadManager.cancelDownload(forIdentifier: entry.id)
  }

}

struct LibraryFeedEntryView: View {

  @Injected(\.downloadManager)
  private var downloadManager: DownloadManager

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  @Environment(\.dismissSheetModal)
  private var dismissSheetModal: DismissAction?

  init(_ entry: FeedEntry) {
    self.dataSource = DataSource(entry: entry)
  }

  @State private var installsWithTarix = true
  @State private var installsAsLatest = true

  @ObservedObject private var dataSource: DataSource

  private func optionsSection() -> some View {
    Section(header: Text("Options")) {
      HStack {
        Text("Version")
        Spacer()
        Text(dataSource.versionText)
      }
      if dataSource.supportsTarix {
        BoltToggle("Install with Archive Index", isOn: $installsWithTarix.animation(.default))
      }
    }
  }

  private func tarixSection() -> some View {
    Section(header: Text("Archive Index")) {
      HStack {
        Label("\(dataSource.fileNameToDisplay).tarix", systemImage: "doc.text")
          .labelStyle(ListItemLabelStyle())
        Spacer()
        switch dataSource.statusResult {
        case .loading:
          ProgressView()
        case .result(let res):
          if case .success = res {
            Text(Image(systemName: "checkmark.circle"))
          } else if case .failure = res {
            Button(action: {
              dataSource.downloadTarixTrigger = ()
            }, label: {
              Text(Image(systemName: "arrow.counterclockwise"))
            })
            .buttonStyle(.borderless)
          }
        case .idle:
          Button(action: {
            dataSource.downloadTarixTrigger = ()
          }, label: {
            Text("arrow.down.circle")
          })
        }
      }
    }
  }

  private func docsetSection() -> some View {
    Section(
      header: Text("Docset"),
      footer: Group {
        if case .downloaded = dataSource.downloadStatus {
          Text("\(Image(systemName: "checkmark.circle")) Ready to Install")
        } else {
          if
            let estimatedSizeStatusResult = dataSource.estimatedSizeStatusResult,
            case .success(let size) = estimatedSizeStatusResult
          {
            if let size = size {
              Text("\(Image(systemName: "arrow.down.circle")) Download Size: \(String.formatBytes(bytes: Double(size)))")
            }
          } else {
            Text("\(Image(systemName: "rays")) Getting Download Size...")
          }
        }
      }
    ) {
      Label("\(dataSource.fileNameToDisplay).tgz", systemImage: "text.book.closed")
        .labelStyle(ListItemLabelStyle())
    }
  }

  private func installSection() -> some View {
    Group {
      Section(footer: Group {
        if dataSource.supportsTarix, installsWithTarix != true {
          Text("\(Image(systemName: "exclamationmark.triangle")) Installing docsets without a archive index (tarix) can significantly increase the size of installed docset and installation time.")
        }
      }) {
        if case let .downloading(progress) = dataSource.downloadStatus {
          ProgressView(value: progress)
            .progressViewStyle(.linear)
        }
        Button(action: {
          Task {
            switch dataSource.downloadStatus {
            case .notDownloaded:
              await startDownload(force: false)
            case .downloading:
              await cancelDownload()
            case .downloaded:
              startInstall()
            case .failed:
              await startDownload(force: true)
            }
          }
        }, label: {
          switch dataSource.downloadStatus {
          case .notDownloaded:
            Text("Download")
          case .downloading:
            Text("Cancel Download")
          case .downloaded:
            Text("Install")
          case .failed:
            Text("Retry Download")
          }
        })
      }
      Section {
        if case .downloaded = dataSource.downloadStatus {
          Button("Delete", role: .destructive) {
            Task {
              await dataSource.deleteArchive()
            }
          }
        }
      }
    }
  }

  private func uninstallSection() -> some View {
    Section {
      Button("Already Installed") { }
        .disabled(true)
    }
  }

  var body: some View {
    Form {
      optionsSection()
      if dataSource.supportsTarix, installsWithTarix {
        tarixSection()
      }
      docsetSection()
      if !dataSource.isInstalled {
        installSection()
      } else {
        uninstallSection()
      }
    }
    .task {
      await dataSource.fetchDocsetDownloadSize()
    }
    .listStyle(.insetGrouped)
    .navigationTitle(dataSource.entry.feed.displayName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(UIKitLocalizations.done, systemImage: "checkmark") {
          dismissSheetModal?()
        }
        .labelStyle(.toolbar)
      }
    }
  }

  // MARK: - Actions

  @MainActor
  private func startDownload(force: Bool) async {
    let retVal = await downloadManager.downloadDocset(forFeedEntry: dataSource.entry, force: force)
    if !retVal {
      GlobalUI.showMessageToast(
        withErrorMessage: ErrorMessage(entity: .docsetAlreadyDownloaded, nestedError: nil)
      )
    }
  }

  private func cancelDownload() async {
    await downloadManager.cancelDownload(forIdentifier: dataSource.entry.id)
  }

  private func startInstall() {
    let observable = libraryDocsetsManager.installOrUpdateDocset(
      forEntry: dataSource.entry,
      usingTarix: dataSource.supportsTarix && installsWithTarix
    )
    // swiftlint:disable:next trailing_closure
    .handleEvents(receiveCompletion: { completion in
      if case .finished = completion {
        Task {
          await downloadManager.cancelDownload(forIdentifier: dataSource.entry.id)
          dismissSheetModal?()
        }
      }
    })

    InstallationAlert(installationObservable: observable.asObservable()).startInstall()
  }

}
