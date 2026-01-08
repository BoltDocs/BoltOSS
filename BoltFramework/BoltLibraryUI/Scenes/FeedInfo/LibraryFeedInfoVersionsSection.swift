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

import BoltDocsets
import BoltTypes
import BoltUIFoundation
import BoltUtils

struct FeedInfoVersionsSectionListModel {

  enum InstallableStatus {
    case latest
    case installed
    case updateAvailable(currentVersion: String)
    case installable
  }

  struct Item: Identifiable {
    let feedEntry: FeedEntry
    let installableStatus: InstallableStatus

    var id: String {
      return feedEntry.id
    }
  }

  var items: [Item]
  var shouldHideVersions: Bool

}

protocol FeedInfoVersionsSectionModel: ObservableObject {

  var statusResult: ActivityStatus<FeedInfoVersionsSectionListModel, Error> { get }

  var feed: Feed { get }

  var refreshTrigger: Void { get set }

}

final class LibraryFeedInfoVersionsSectionModelImp: FeedInfoVersionsSectionModel {

  private var cancellables = Set<AnyCancellable>()
  private let activityStatusTracker = ActivityStatusTracker<FeedInfoVersionsSectionListModel, Error>()

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  @Published var refreshTrigger: Void = ()
  @Published var statusResult: ActivityStatus<FeedInfoVersionsSectionListModel, Error> = .idle

  private(set) var feed: Feed

  private let installedRecordsForCurrentFeed = CurrentValueSubject<[LibraryRecord], Never>([])

  init(feed: Feed) {
    self.feed = feed

    libraryDocsetsManager.installedRecordsPublisher
      .map { records -> [LibraryRecord] in
        let mappedRecords = records.filter {
          $0.repository == feed.repository && $0.name == feed.id
        }
        return mappedRecords
      }
      .sink { [installedRecordsForCurrentFeed] mappedRecords in
        installedRecordsForCurrentFeed.send(mappedRecords)
      }
      .store(in: &cancellables)

    let fetchEntriesPublisher: () -> Future<FeedEntries, Error> = {
      return Future<[FeedEntry], Error>.awaitingThrowing {
        return try await feed.fetchEntries()
      }
    }

    let handleRefreshing: () -> AnyPublisher<Result<FeedInfoVersionsSectionListModel, Error>, Never> = { [installedRecordsForCurrentFeed] in
      return Publishers.CombineLatest(
        fetchEntriesPublisher(),
        installedRecordsForCurrentFeed
          .setFailureType(to: Error.self)
      )
      .map { feedEntries, records -> FeedInfoVersionsSectionListModel in
        let items = feedEntries.items.map { entry -> FeedInfoVersionsSectionListModel.Item in
          var installableStatus: FeedInfoVersionsSectionListModel.InstallableStatus
          if entry.isTrackedAsLatest {
            // FIXME: may contain multiple matching records here
            if let record = records.first(where: { $0.installedAsLatestVersion == true }) {
              if record.version == entry.version {
                installableStatus = .latest
              } else {
                installableStatus = .updateAvailable(currentVersion: record.version)
              }
            } else {
              installableStatus = .installable
            }
          } else {
            if records.contains(where: { $0.version == entry.version && $0.installedAsLatestVersion == false }) {
              installableStatus = .installed
            } else {
              installableStatus = .installable
            }
          }
          return FeedInfoVersionsSectionListModel.Item(feedEntry: entry, installableStatus: installableStatus)
        }
        return FeedInfoVersionsSectionListModel(
          items: items,
          shouldHideVersions: feedEntries.shouldHideVersions
        )
      }
      .eraseToAnyPublisher()
      .mapToResult()
    }

    $refreshTrigger
      .flatMap { _ in handleRefreshing() }
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
  }

}

private struct FeedInfoStaticListItem: View {

  private var title: String
  private var subtitle: String?
  private var indicatorSymbolName: String?

  init(title: String, subtitle: String? = nil, indicatorSymbolName: String? = nil) {
    self.title = title
    self.subtitle = subtitle
    self.indicatorSymbolName = indicatorSymbolName
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
        if let subtitle = subtitle {
          Text(subtitle)
            .foregroundColor(.secondary)
            .font(.system(.caption))
        }
      }
      Spacer()
      if let indicatorSymbolName = indicatorSymbolName {
        Text(Image(systemName: indicatorSymbolName))
      }
    }
  }

}

struct LibraryFeedInfoVersionsSection<ViewModel: FeedInfoVersionsSectionModel>: View {

  @StateObject private var viewModel: ViewModel

  @State private var showsAllVersions: Bool

  init(feed: Feed) where ViewModel == LibraryFeedInfoVersionsSectionModelImp {
    self.init(viewModel: LibraryFeedInfoVersionsSectionModelImp(feed: feed))
  }

  fileprivate init(viewModel: ViewModel, isPreview: Bool = false) {
    showsAllVersions = isPreview
    _viewModel = StateObject(wrappedValue: { viewModel }())
  }

  private func buildVersionsListItem(
    entryListModel: FeedInfoVersionsSectionListModel.Item,
    shouldHideVersions: Bool
  ) -> AnyView {
    let entry = entryListModel.feedEntry
    let shouldShowVersionedItem = !shouldHideVersions && showsAllVersions
    if shouldShowVersionedItem || entry.isTrackedAsLatest {
      switch entryListModel.installableStatus {
      case .installable:
        return AnyView(
          NavigationLink(
            destination: DeferredView { LibraryFeedEntryView(entry) }
          ) {
            // versions for docsets marked 'latest' should be hidden to the user
            DownloadProgressListItemView(
              identifier: entry.id,
              title: entry.isTrackedAsLatest ? "Latest" : entry.version,
              subtitle: nil, // (!entry.feed.shouldHideVersions && entry.isTrackedAsLatest) ? entry.version : nil,
              preventsHighlight: true
            )
          }
        )
      case let .updateAvailable(currentVersion):
        assert(entry.isTrackedAsLatest)
        return AnyView(
          NavigationLink(
            destination: DeferredView { LibraryFeedEntryView(entry) }
          ) {
            let subtitle = {
              var res = "Update Available"
              if RuntimeEnvironment.isInternalBuild {
                res += " (\(entry.version) / \(currentVersion))"
              }
              return res
            }()
            DownloadProgressListItemView(
              identifier: entry.id,
              title: "Latest",
              subtitle: subtitle,
              preventsHighlight: true
            )
          }
        )
      case .installed:
        assert(!entry.isTrackedAsLatest)
        return AnyView(
          FeedInfoStaticListItem(
            title: entry.version,
            subtitle: nil,
            indicatorSymbolName: "checkmark.circle"
          )
        )
      case .latest:
        assert(entry.isTrackedAsLatest)
        return AnyView(
          FeedInfoStaticListItem(
            title: "Latest",
            subtitle: "Up to date",
            indicatorSymbolName: "checkmark.circle"
          )
        )
      }
    }
    return AnyView(EmptyView())
  }

  var body: some View {
    Section(header: Text("Library-FeedInfo-SectionTitles-Versions".boltLocalized)) {
      if case .result(let result) = viewModel.statusResult {
        if case .success(let listModel) = result {
          if !listModel.shouldHideVersions {
            BoltToggle("Show All Available Versions", isOn: $showsAllVersions)
          }
          ForEach(listModel.items) { entry in
            buildVersionsListItem(
              entryListModel: entry,
              shouldHideVersions: listModel.shouldHideVersions
            )
          }
        } else {
          Button("Retry") {
            viewModel.refreshTrigger = ()
          }
        }
      } else {
        HStack(spacing: 8) {
          ProgressView()
          Text("Loading Versions…")
        }
      }
    }
  }

}

#if DEBUG

final class LibraryFeedInfoVersionsStubbedSectionModel: FeedInfoVersionsSectionModel {

  @Published var refreshTrigger: Void = ()

  @Published var statusResult: ActivityStatus<FeedInfoVersionsSectionListModel, Error> = .idle

  private(set) var feed: Feed

  init(feed: Feed, listModel: FeedInfoVersionsSectionListModel) {
    self.feed = feed
    statusResult = .result(result: .success(listModel))
  }

}

#Preview(traits: .fixedLayout(width: 480, height: 640)) {

  let feed = StubFeed(
    repository: .userContributed,
    id: "RxSwift",
    displayName: "RxSwift",
    aliases: [],
    shouldHideVersions: false,
    supportsArchiveIndex: false,
    icon: EntryIcon.providerDefault
  )

  let listItems = [
    FeedInfoVersionsSectionListModel.Item(
      feedEntry: FeedEntry(
        feed: feed,
        version: "6.7.2",
        isTrackedAsLatest: true,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      ),
      installableStatus: .installable
    ),
    FeedInfoVersionsSectionListModel.Item(
      feedEntry: FeedEntry(
        feed: feed,
        version: "6.7.1",
        isTrackedAsLatest: true,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      ),
      installableStatus: .latest
    ),
    FeedInfoVersionsSectionListModel.Item(
      feedEntry: FeedEntry(
        feed: feed,
        version: "6.7.0",
        isTrackedAsLatest: true,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      ),
      installableStatus: .updateAvailable(currentVersion: "6.7.1")
    ),
    FeedInfoVersionsSectionListModel.Item(
      feedEntry: FeedEntry(
        feed: feed,
        version: "6.6.0",
        isTrackedAsLatest: false,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      ),
      installableStatus: .installed
    ),
    FeedInfoVersionsSectionListModel.Item(
      feedEntry: FeedEntry(
        feed: feed,
        version: "6.5.0",
        isTrackedAsLatest: false,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      ),
      installableStatus: .installable
    ),
  ]

  List {
    LibraryFeedInfoVersionsSection(
      viewModel: LibraryFeedInfoVersionsStubbedSectionModel(
        feed: feed, listModel: FeedInfoVersionsSectionListModel(
          items: listItems,
          shouldHideVersions: false
        )
      ),
      isPreview: true
    )
  }
}

#endif
