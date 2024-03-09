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

import BoltLocalizations
import BoltServices
import BoltUIFoundation
import BoltUtils

private final class LibraryCustomFeedListViewModel: ObservableObject {

  @Injected(\.feedsService)
  private var feedsService: FeedsService

  @Published var feeds = [CustomFeed]()

  private var cancellables = Set<AnyCancellable>()

  init() {
    feedsService.customFeedsObservable()
      .assertNoFailure()
      .assign(to: &$feeds)
  }

  func onConfirmRemoveFeed(_ feed: CustomFeed) throws {
    try? feedsService.deleteCustomFeeds(feed)
  }

}

struct LibraryCustomFeedListView: View {

  @Environment(\.dismissLibraryHome)
  private var dismissLibraryHome: DismissAction?

  @ObservedObject private var model = LibraryCustomFeedListViewModel()

  @State private var showsImportFeedSheet = false

  static let emptyStateImage: UIImage = BoltImageResource(named: "overview-icons/custom-feed", in: .module).platformImage!

  var body: some View {
    Group {
      if !model.feeds.isEmpty {
        List {
          ForEach(model.feeds, id: \.id) { feed in
            NavigationLink {
              DeferredView { FeedInfoView(feed: feed) }
            } label: {
              LibraryFeedListItemView(image: feed.iconImageForList, title: feed.displayName)
            } // NavigationLink
            .swipeActions {
              Button(action: {
                promptRemoveFeed(feed)
              }, label: {
                Label("Delete", systemImage: "trash")
              }) // Button
              .tint(.red)
            } // swipeActions
            .tint(Color.primary)
          } // ForEach
        } // List
      } else {
        EmptyFeedsView(
          image: Self.emptyStateImage,
          message: "No Feeds",
          shouldDisplayIndicator: false,
          showsMessage: true,
          showsRetry: false
        ) // EmptyFeedsView
      } // if
    } // Group
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.systemGroupedBackground)
    .navigationTitle("Custom Feeds")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(UIKitLocalization.done) {
          dismissLibraryHome?()
        } // Button
      } // ToolbarItem
      ToolbarItemGroup(placement: .bottomBar) {
        Spacer()
        Button {
          showsImportFeedSheet.toggle()
        } label: {
          Image(systemName: "plus")
        } // Button
        .sheet(isPresented: $showsImportFeedSheet) {
          NavigationView {
            LibraryCustomFeedImportView()
          } // NavigationView
        } // sheet
      } // ToolbarItemGroup
    } // toolbar
  }

  private func promptRemoveFeed(_ feed: CustomFeed) {
    GlobalUI.presentAlertController(
      UIAlertController.alert(
        withTitle: "Uninstall",
        message: "Do you really want to remove feed \(feed.displayName)?",
        confirmAction: ("Confirm", UIAlertAction.Style.destructive, {
          try? model.onConfirmRemoveFeed(feed)
        }),
        cancelAction: (UIKitLocalization.cancel, { })
      )
    )
  }

}
