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

extension ErrorMessageEntity {
  static let fetchFeedsFailed = ErrorMessageEntity(description: "Failed to fetch available feeds")
}

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

  @Environment(\.dismissSheetModal)
  private var dismissSheetModal: DismissAction?

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
        ToolbarItem(placement: .confirmationAction) {
          Button(UIKitLocalizations.done) {
            dismissSheetModal?()
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
          NavigationLink {
            DeferredView { LibraryFeedInfoView(feed) }
          } label: {
            LibraryFeedListItemView(image: feed.iconImageForList, title: feed.displayName)
          } // NavigationLink
          .tint(Color.primary)
        } // ForEach
      } // if
    } // List
    .searchable(text: $searchText, prompt: UIKitLocalizations.search)
    .textInputAutocapitalization(.never)
    .disableAutocorrection(true)
    .overlay {
      if actionPerformer.status != .success {
        let message = actionPerformer.error == nil ?
          "Loading Feeds" :
          "Failed to Load Feeds"
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
                withTitle: "Failed to Load Feeds",
                message: error.localizedDescription,
                confirmAction: ("OK", .default, nil)
              )
            )
          },
          retryAction: {
            Task { await actionPerformer.perform() }
          }
        ) // BoltContentUnavailableView
      } // if
    } // List
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.systemGroupedBackground)
  }

}
