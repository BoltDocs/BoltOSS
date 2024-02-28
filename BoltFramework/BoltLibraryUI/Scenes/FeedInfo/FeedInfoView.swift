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
import UIKit.UIImage

import Factory
import RxCocoa
import RxSwift

import BoltLocalizations
import BoltServices
import BoltUIFoundation
import BoltUtils

private final class DataSource: ObservableObject {

  struct FeedEntryListModel: Identifiable {
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

  private var cancellables = Set<AnyCancellable>()
  private let activityStatusTracker = ActivityStatusTracker<[FeedEntryListModel], Error>()

  @Published var refreshTrigger: Void = ()
  @Published var statusResult: ActivityStatus<[FeedEntryListModel], Error> = .idle

  private(set) var feed: Feed

  var isPlaceHolder: Bool {
    return feed.isUnavailable
  }

  var placeHolderMessage: String {
    if feed.isUnavailable {
      return feed.unavailableMessage ?? "\(feed.displayName) is currently not available."
    }
    return ""
  }

  init(feed: Feed) {
    self.feed = feed

    let fetchEntriesPublisher: () -> Future<[FeedEntry], Error> = {
      return Future<[FeedEntry], Error>.awaitingThrowing {
        return try await feed.fetchEntries()
      }
    }

    let handleRefreshing: () -> AnyPublisher<Result<[DataSource.FeedEntryListModel], Error>, Never> = {
      return Publishers.CombineLatest(
        fetchEntriesPublisher(),
        LibraryDocsetsManager.shared.installedRecords()
          .setFailureType(to: Error.self)
      )
      .map { entries -> Result<[FeedEntryListModel], Error> in
        let records = entries.1
        let res = entries.0.map { entry -> FeedEntryListModel in
          var installableStatus: FeedEntryListModel.InstallableStatus = .installable
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
          return FeedEntryListModel(feedEntry: entry, installableStatus: installableStatus)
        }
        return Result.success(res)
      }
      .catch { error -> AnyPublisher<Result<[FeedEntryListModel], Error>, Never> in
        GlobalUI.showMessageToast(
          withErrorMessage: ErrorMessage(entity: ErrorMessageEntity.fetchEntriesFailed, nestedError: error)
        )
        return Just(Result.failure(error))
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
    }

    $refreshTrigger
      .flatMap { _ in handleRefreshing() }
      .trackActivityStatus(activityStatusTracker)
      .sink { _ in }
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

struct FeedInfoView: View {

  @Environment(\.dismissLibraryHome)
  private var dismissLibraryHome: DismissAction?

  @Injected(\.repositoryRegistry)
  private var repositoryRegistry: RepositoryRegistry

  @ObservedObject private var dataSource: DataSource

  init(feed: Feed) {
    self.dataSource = DataSource(feed: feed)
  }

  private var editable: Bool {
    guard let repository = repositoryRegistry.repository(forIdentifier: dataSource.feed.repository) else {
      assertionFailure("Unrecognized feed repository")
      return false
    }
    return !repository.isPreset
  }

  @State private var showsAllVersions = false
  @State private var isEditing = false

  private func infoSection() -> some View {
    Section(
      header: Text("Feed"),
      footer: Group {
        if editable == true {
          if isEditing == true {
            Text("Edit feed name here.")
          }
        }
      }
    ) {
      HStack {
        let image = dataSource.feed.iconImageForList
        Image(uiImage: image ?? UIImage())
          .if(image?.isSymbolImage ?? false) {
            $0.renderingMode(.template)
          }
          .foregroundColor(Color.primary)
          .frame(width: 30, height: 30)
        TextField("", text: .constant(dataSource.feed.displayName))
          .disabled(!(isEditing == true && editable == true))
          .if(isEditing == true && editable == false) {
            $0.foregroundColor(Color.gray)
          }
      }
    }
  }

  private func buildVersionsListItem(entryListModel: DataSource.FeedEntryListModel) -> AnyView {
    let entry = entryListModel.feedEntry
    let shouldShowVersionedItem = !dataSource.feed.shouldHideVersions && showsAllVersions
    if shouldShowVersionedItem || entry.isTrackedAsLatest {
      switch entryListModel.installableStatus {
      case .installable:
        return AnyView(
          NavigationLink(
            destination: DeferredView { DownloadConfirmationView(feedEntry: entry) }
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
            destination: DeferredView { DownloadConfirmationView(feedEntry: entry) }
          ) {
            let subtitle = dataSource.feed.shouldHideVersions
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

  private func versionsSection() -> some View {
    return Section(header: Text("Versions")) {
      if case .result(let result) = dataSource.statusResult {
        if case .success(let allVersions) = result {
          if !dataSource.feed.shouldHideVersions {
            BoltToggle("Show All Available Versions", isOn: $showsAllVersions)
          }
          ForEach(allVersions) { entry in
            buildVersionsListItem(entryListModel: entry)
          }
        } else {
          Button("Retry") {
            dataSource.refreshTrigger = ()
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

  var body: some View {
    Form {
      if !dataSource.isPlaceHolder {
        infoSection()
        versionsSection()
      } else {
        Text(dataSource.placeHolderMessage)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle(dataSource.feed.displayName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(UIKitLocalization.done) {
          dismissLibraryHome?()
        }
      }
      if editable {
        ToolbarItemGroup(placement: .bottomBar) {
          Spacer()
          Button(action: {
            withAnimation(.default) {
              isEditing.toggle()
            }
          }, label: {
            Text(isEditing ? UIKitLocalization.done : UIKitLocalization.edit)
              .if(isEditing) {
                $0.bold()
              }
          })
        }
      }
    }
  }

}
