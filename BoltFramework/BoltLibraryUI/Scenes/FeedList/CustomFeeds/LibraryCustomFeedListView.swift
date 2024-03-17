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
import Overture

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
      .map { feeds in
        return feeds.sorted {
          $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
      }
      .assign(to: &$feeds)
  }

  func onConfirmRenameFeed(_ feed: CustomFeed, newName: String) throws {
    guard !newName.isEmpty else {
      return
    }
    let newFeed = update(feed) {
      $0.displayName = newName
    }
    try? feedsService.updateCustomFeed(newFeed)
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
    List {
      ForEach(model.feeds, id: \.id) { feed in
        NavigationLink {
          DeferredView { FeedInfoView(feed: feed) }
        } label: {
          LibraryFeedListItemView(image: feed.iconImageForList, title: feed.displayName)
        } // NavigationLink
        .contextMenu {
          Button {
            promptRenameFeed(feed)
          } label: {
            Label(UIKitLocalization.rename, systemImage: "square.and.pencil")
          } // Button
          Button(role: .destructive) {
            promptRemoveFeed(feed)
          } label: {
            Label(UIKitLocalization.delete, systemImage: "trash")
          } // Button
        } // contextMenu
        .swipeActions {
          Button(UIKitLocalization.delete) {
            promptRemoveFeed(feed)
          } // Button
          .tint(.red)
          Button(UIKitLocalization.rename) {
            promptRenameFeed(feed)
          } // Button
          .tint(.orange)
        } // swipeActions
      } // ForEach
    } // List
    .overlay {
      if model.feeds.isEmpty {
        EmptyFeedsView(
          image: Self.emptyStateImage,
          message: "Library-ImportedFeed-List-noFeed".boltLocalized,
          shouldDisplayIndicator: false,
          showsMessage: true,
          showsRetry: false
        ) // EmptyFeedsView
      } // if
    } // overlay
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.systemGroupedBackground)
    .navigationTitle("Library-ImportedFeeds-List-title".boltLocalized)
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
    .animation(.default, value: model.feeds.map { $0.id })
  }

  private func promptRenameFeed(_ feed: CustomFeed) {
    let alertTitle = !feed.displayName.isEmpty ?
      "Library-ImportedFeeds-List-RenameAlert-renameTitleFormat".boltLocalized(feed.displayName) :
      "Library-ImportedFeeds-List-RenameAlert-renameFeedTitle".boltLocalized
    GlobalUI.presentAlertController(
      UIAlertController.inputAlert(
        withTitle: alertTitle,
        message: nil,
        initialText: feed.displayName,
        placeHolder: "Library-ImportedFeeds-List-RenameAlert-namePlaceHolder".boltLocalized,
        confirmAction: (UIKitLocalization.rename, .default, { newName in
          try? model.onConfirmRenameFeed(feed, newName: newName)
        }),
        cancelAction: (UIKitLocalization.cancel, { })
      )
    )
  }

  private func promptRemoveFeed(_ feed: CustomFeed) {
    let alertMessage = !feed.displayName.isEmpty ?
      "Library-ImportedFeeds-List-RenameAlert-removeMessageFormat".boltLocalized(feed.displayName) :
      "Library-ImportedFeeds-List-RenameAlert-removeFeedMessage".boltLocalized
    GlobalUI.presentAlertController(
      UIAlertController.alert(
        withTitle: "Library-ImportedFeeds-List-RenameAlert-removeFeedTitle".boltLocalized,
        message: alertMessage,
        confirmAction: (
          "Localizations-General-confirm".boltLocalized,
          UIAlertAction.Style.destructive, {
            try? model.onConfirmRemoveFeed(feed)
          }
        ),
        cancelAction: (UIKitLocalization.cancel, { })
      )
    )
  }

}
