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

  struct SectionFooterLine {
    let icon: String
    let text: String
  }

  @Injected(\.downloadManager)
  private var downloadManager: DownloadManager

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  private var cancellables = Set<AnyCancellable>()
  private let activityStatusTracker = ActivityStatusTracker<Void, Error>()

  let supportsTarix: Bool

  @Published var downloadTarixTrigger: Void = ()
  @Published var statusResult: ActivityStatus<Void, Error> = .idle

  @Published var estimatedSizeStatusResult: Result<Int64?, Error>?

  @Published var downloadStatus: DownloadStatus = .notDownloaded
  @Published var isInstalled = false

  @Published var installsWithTarix: Bool

  @Published var installSectionFooter = [SectionFooterLine]()

  private(set) var entry: FeedEntry

  var versionText: String {
    if entry.isTrackedAsLatest {
      return "Library-FeedEntry-Docset-latestLabel".boltLocalized
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
    self.supportsTarix = entry.feed.supportsArchiveIndex
    self.installsWithTarix = supportsTarix

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

    Publishers.CombineLatest3($downloadStatus, $estimatedSizeStatusResult, $installsWithTarix)
      .map { [weak self] downloadStatus, estimatedSizeStatusResult, installsWithTarix -> [SectionFooterLine] in
        guard let self = self else {
          return []
        }
        var lines = [SectionFooterLine]()
        if case .downloaded = downloadStatus {
          lines.append(
            SectionFooterLine(
              icon: "checkmark.circle",
              text: "Library-FeedEntry-Docset-readyToInstallHint".boltLocalized
            )
          )
        } else {
          if
            let estimatedSizeStatusResult = estimatedSizeStatusResult,
            case .success(let size) = estimatedSizeStatusResult
          {
            if let size = size {
              lines.append(
                SectionFooterLine(
                  icon: "arrow.down.circle",
                  text: "Library-FeedEntry-Docset-downloadSizeHint"
                    .boltLocalized(String.formatBytes(bytes: Double(size)))
                )
              )
            } else {
              lines.append(
                SectionFooterLine(
                  icon: "rays",
                  text: "Library-FeedEntry-Docset-gettingDownloadSizeHint".boltLocalized
                )
              )
            }
          }
        }
        if supportsTarix, installsWithTarix != true {
          lines.append(
            SectionFooterLine(
              icon: "exclamationmark.triangle",
              text: "Library-FeedEntry-Docset-installWithoutArchiveIndexHint".boltLocalized
            )
          )
        }
        return lines
      }
      .assign(to: &$installSectionFooter)
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

  @State private var advancedOptionsExpanded = false
  @State private var installsAsLatest = true

  @ObservedObject private var dataSource: DataSource

  private func optionsSection() -> some View {
    DisclosureGroup(
      "Library-FeedEntry-SectionTitles-advancedOptions".boltLocalized,
      isExpanded: $advancedOptionsExpanded
    ) {
      BoltToggle(
        "Library-FeedEntry-Options-installWithArchiveIndexLabel".boltLocalized,
        isOn: $dataSource.installsWithTarix.animation(.default),
        isEnabled: dataSource.supportsTarix
      )
    }
  }

  private func tarixSection() -> some View {
    Section(header: Text("Library-FeedEntry-SectionTitles-archiveIndex".boltLocalized)) {
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
    Section("Library-FeedEntry-SectionTitles-docset".boltLocalized) {
      HStack {
        Label("\(dataSource.entry.feed.displayName)", systemImage: "text.book.closed")
          .labelStyle(ListItemLabelStyle())
          .layoutPriority(1)
        Spacer()
        Text(dataSource.versionText)
      }
    }
  }

  private func installSection() -> some View {
    Group {
      Section(footer: Group {
        let footerLines = dataSource.installSectionFooter
        if !footerLines.isEmpty {
          footerLines.enumerated().reduce(Text("")) { result, item in
            let (index, line) = item
            let lineText = Text("\(Image(systemName: line.icon)) \(line.text)")
            return index == 0 ? Text("\n\(lineText)") : Text("\(result)\n\n\(lineText)")
          }
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
            Text("Library-FeedEntry-Install-downloadButtonTitle".boltLocalized)
          case .downloading:
            Text("Library-FeedEntry-Install-cancelDownloadButtonTitle".boltLocalized)
          case .downloaded:
            Text("Library-FeedEntry-Install-installButtonTitle".boltLocalized)
          case .failed:
            Text("Library-FeedEntry-Install-retryDownloadButtonTitle".boltLocalized)
          }
        })
      }
      Section {
        if case .downloaded = dataSource.downloadStatus {
          Button(UIKitLocalizations.delete, role: .destructive) {
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
      Button("Library-FeedEntry-Install-alreadyInstalledLabel".boltLocalized) { }
        .disabled(true)
    }
  }

  var body: some View {
    Form {
      docsetSection()
      if dataSource.supportsTarix, dataSource.installsWithTarix {
        tarixSection()
      }
      if !dataSource.isInstalled {
        installSection()
      } else {
        uninstallSection()
      }
      optionsSection()
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
      usingTarix: dataSource.supportsTarix && dataSource.installsWithTarix
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
