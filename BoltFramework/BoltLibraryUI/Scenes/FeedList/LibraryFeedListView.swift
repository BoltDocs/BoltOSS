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

import SwiftUI

import BoltLocalizations
import BoltServices
import BoltUIFoundation
import BoltUtils

class RefreshActionPerformer: ObservableObject {

  enum Status: Equatable {
    case idle
    case loading
    case success
    case error(ServiceError)
  }

  @Published private(set) var status: Status = .idle

  var action: (() async throws(ServiceError) -> Void)?

  var error: ServiceError? {
    if case let .error(error) = status {
      return error
    }
    return nil
  }

  @MainActor
  func perform() async {
    guard let action = action, status != .loading else {
      return
    }
    status = .loading
    do {
      try await action()
      status = .success
    } catch {
      status = .error(error)
    }
  }

}

struct LibraryFeedListRefreshableListWrapper<Model>: View where Model: LibraryFeedListViewModel {

  @Environment(\.dismissCurrentSheetModal)
  private var dismissCurrentSheetModal: DismissAction?

  @StateObject private var model = Model()
  @StateObject private var actionPerformer = RefreshActionPerformer()

  @MainActor
  func refreshAction() async throws(ServiceError) {
    do {
      try await model.refreshFeeds()
    } catch {
      // use `catch` here to avoid compiler crash
      // https://github.com/swiftlang/swift/issues/77612
      throw error
    }
  }

  var body: some View {
    LibraryFeedListView(model: model, actionPerformer: actionPerformer)
      .navigationTitle(Model.title)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        if RuntimeEnvironment.isOS26UIEnabled {
          ToolbarItem(placement: .topBarTrailing) {
            Button(UIKitLocalizations.close, systemImage: "xmark") {
              dismissCurrentSheetModal?()
            }
          }
        } else {
          ToolbarItem(placement: .confirmationAction) {
            Button(UIKitLocalizations.done) {
              dismissCurrentSheetModal?()
            }
          }
        }
      }
      .if(Model.allowsRefresh) {
        $0.refreshable {
          await actionPerformer.perform()
        }
      }
      .onAppear {
        actionPerformer.action = refreshAction
        Task {
          await actionPerformer.perform()
        }
      }
  }

}

private struct LibraryFeedListView<Model>: View where Model: LibraryFeedListViewModel {

  @ObservedObject private var model: Model
  @ObservedObject private var actionPerformer: RefreshActionPerformer

  init(model: Model, actionPerformer: RefreshActionPerformer) {
    self.model = model
    self.actionPerformer = actionPerformer
  }

  @State private var searchText = ""

  @State private var selectedFeed: IdentifiableFeed?

  private var filteredFeeds: [Feed] {
    let result: [Feed]
    if searchText.isEmpty {
      result = model.feeds
    } else {
      let query = searchText.lowercased()
      result = model.feeds.filter { feed in
        return feed.displayName.lowercased().contains(query) ||
          feed.aliases.contains { $0.lowercased().contains(query) }
      }
    }
    return result.sorted {
      $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
    }
  }

  var body: some View {
    List {
      if actionPerformer.status == .success {
        ForEach(filteredFeeds, id: \.id) { feed in
          Button {
            selectedFeed = IdentifiableFeed(feed: feed)
          } label: {
            LibraryFeedListItemView(image: feed.iconImageForList?.image, title: feed.displayName) {
              Image(systemName: "chevron.right")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
            }
          }
          .tint(Color.primary)
        }
      }
    }
    .searchable(text: $searchText, prompt: UIKitLocalizations.search)
    .textInputAutocapitalization(.never)
    .disableAutocorrection(true)
    .overlay {
      if actionPerformer.status != .success {
        let message = actionPerformer.error == nil ?
          "Library-FeedList-loadingDocsetsHint".boltLocalized :
          "Library-FeedList-failedToLoadDocsetsHint".boltLocalized
        BoltContentUnavailableView(
          configuration: BoltContentUnavailableViewConfiguration(
            image: Model.emptyStateImage,
            imageSize: CGSize(width: 142, height: 142),
            message: message,
            shouldDisplayIndicator: actionPerformer.status == .loading,
            showsMessage: true,
            showsDetailButton: actionPerformer.error != nil,
            showsRetryButton: actionPerformer.error != nil
          ), // BoltContentUnavailableViewConfiguration
          detailAction: {
            guard case let .error(error) = actionPerformer.status else {
              return
            }
            GlobalUI.presentAlertController(
              UIAlertController.alert(
                withTitle: "Library-FeedList-failedToLoadDocsetsHint".boltLocalized,
                message: error.localizedDescription,
                confirmAction: (UIKitLocalizations.ok, .default, nil)
              )
            )
          },
          retryAction: {
            Task { await actionPerformer.perform() }
          }
        ) // BoltContentUnavailableView
      } // if
    } // overlay
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .scrollContentBackground(.hidden)
    .background(Color.systemGroupedBackground)
    .sheet(item: $selectedFeed) { identifiableFeed in
      SheetContainer {
        LibraryFeedInfoView(identifiableFeed.feed)
      }
    }
  }

}
