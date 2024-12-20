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

struct FeedInfoVersionsSectionListItem: Identifiable {

  enum InstallableStatus {
    case latest
    case installed
    case updateAvailable(currentVersion: String)
    case installable
  }

  let feedEntry: FeedEntry
  let installableStatus: InstallableStatus

  var id: String {
    return feedEntry.id
  }

}

protocol FeedInfoVersionsSectionModel: ObservableObject {

  var statusResult: ActivityStatus<[FeedInfoVersionsSectionListItem], Error> { get }

  var feed: Feed { get }

  var refreshTrigger: Void { get set }

}

final class LibraryFeedInfoVersionsSectionModelImp: FeedInfoVersionsSectionModel {

  private var cancellables = Set<AnyCancellable>()
  private let activityStatusTracker = ActivityStatusTracker<[FeedInfoVersionsSectionListItem], Error>()

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  @Published var refreshTrigger: Void = ()
  @Published var statusResult: ActivityStatus<[FeedInfoVersionsSectionListItem], Error> = .idle

  private(set) var feed: Feed

  init(feed: Feed) {
    self.feed = feed

    let fetchEntriesPublisher: () -> Future<[FeedEntry], Error> = {
      return Future<[FeedEntry], Error>.awaitingThrowing {
        return try await feed.fetchEntries()
      }
    }

    let handleRefreshing: () -> AnyPublisher<Result<[FeedInfoVersionsSectionListItem], Error>, Never> = { [libraryDocsetsManager] in
      return Publishers.CombineLatest(
        fetchEntriesPublisher(),
        libraryDocsetsManager.installedRecords()
          .setFailureType(to: Error.self)
      )
      .map { feedEntries, records -> [FeedInfoVersionsSectionListItem] in
        return feedEntries.map { entry -> FeedInfoVersionsSectionListItem in
          var installableStatus: FeedInfoVersionsSectionListItem.InstallableStatus = .installable
          for record in records {
            guard record.name == entry.feed.id else {
              continue
            }
            if record.installedAsLatestVersion, entry.isTrackedAsLatest {
              if record.version == entry.version {
                installableStatus = .latest
              } else {
                installableStatus = .updateAvailable(currentVersion: record.version)
              }
            } else if record.version == entry.version {
              installableStatus = .installed
            }
          }
          return FeedInfoVersionsSectionListItem(feedEntry: entry, installableStatus: installableStatus)
        }
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

  private func buildVersionsListItem(entryListModel: FeedInfoVersionsSectionListItem) -> AnyView {
    let entry = entryListModel.feedEntry
    let shouldShowVersionedItem = !viewModel.feed.shouldHideVersions && showsAllVersions
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
            let subtitle = viewModel.feed.shouldHideVersions
              ? "Update Available:"
              : "Update Available: \(entry.version) / \(currentVersion)"
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
    Section(header: Text("Versions")) {
      if case .result(let result) = viewModel.statusResult {
        if case .success(let allVersions) = result {
          if !viewModel.feed.shouldHideVersions {
            BoltToggle("Show All Available Versions", isOn: $showsAllVersions)
          }
          ForEach(allVersions) { entry in
            buildVersionsListItem(entryListModel: entry)
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

  @Published var statusResult: ActivityStatus<[FeedInfoVersionsSectionListItem], Error> = .idle

  private(set) var feed: Feed

  init(feed: Feed, listItems: [FeedInfoVersionsSectionListItem]) {
    self.feed = feed
    statusResult = .result(result: .success(listItems))
  }

}

@available(iOS 17.0, *)
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
    FeedInfoVersionsSectionListItem(
      feedEntry: FeedEntry(
        feed: feed,
        version: "6.7.2",
        isTrackedAsLatest: true,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      ),
      installableStatus: .installable
    ),
    FeedInfoVersionsSectionListItem(
      feedEntry: FeedEntry(
        feed: feed,
        version: "6.7.1",
        isTrackedAsLatest: true,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      ),
      installableStatus: .latest
    ),
    FeedInfoVersionsSectionListItem(
      feedEntry: FeedEntry(
        feed: feed,
        version: "6.7.0",
        isTrackedAsLatest: true,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      ),
      installableStatus: .updateAvailable(currentVersion: "6.7.1")
    ),
    FeedInfoVersionsSectionListItem(
      feedEntry: FeedEntry(
        feed: feed,
        version: "6.6.0",
        isTrackedAsLatest: false,
        isDocsetBundle: false,
        docsetLocation: ResourceLocations.stubbed
      ),
      installableStatus: .installed
    ),
    FeedInfoVersionsSectionListItem(
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
        feed: feed, listItems: listItems
      ),
      isPreview: true
    )
  }
}

#endif
