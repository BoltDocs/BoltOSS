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

import BoltLibraryUIResources
import BoltLocalizations
import BoltServices
import BoltUIFoundation
import BoltUserGuide
import BoltUserGuideUI
import BoltUtils

private final class LibraryCustomFeedListViewModel: ObservableObject, LoggerProvider {

  @Injected(\.feedsService)
  private var feedsService: FeedsService

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  @Published var feeds = [CustomFeed]()

  @Published var userGuideLocation: UserGuideLocation?

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

  func onConfirmRemoveFeed(_ feed: CustomFeed) {
    for record in installedRecords(for: feed) {
      do {
        try libraryDocsetsManager.uninstallDocset(forRecord: record)
      } catch {
        Self.logger.error("onConfirmRemoveFeed: \(feed), failed to uninstallDocset: \(record), error: \(error)")
        return
      }
    }
    do {
      try feedsService.deleteCustomFeed(feed)
    } catch {
      Self.logger.error("onConfirmRemoveFeed: \(feed), failed to delete custom feed with error: \(error)")
    }
  }

  func hasInstalledDocsets(for feed: CustomFeed) -> Bool {
    return !installedRecords(for: feed).isEmpty
  }

  private func installedRecords(for feed: CustomFeed) -> [LibraryRecord] {
    return libraryDocsetsManager.installedRecords.filter {
      $0.repository == feed.repository && $0.name == feed.id
    }
  }

}

struct LibraryCustomFeedListView: View {

  @Environment(\.dismissCurrentSheetModal)
  private var dismissCurrentSheetModal: DismissAction?

  @StateObject private var model = LibraryCustomFeedListViewModel()

  @State private var showsImportFeedSheet = false
  @State private var feedForFeedInfoSheet: CustomFeed?

  @State private var selectedFeed: IdentifiableFeed?

  static let emptyStateImage: UIImage = BoltImageResource(named: "overview-icons/custom-feed", in: .boltLibraryUI).platformImage!

  var body: some View {
    List {
      ForEach(model.feeds, id: \.id) { feed in
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
        .contextMenu {
          Button {
            feedForFeedInfoSheet = feed
          } label: {
            Label(BoltLocalizations.getInfo, systemImage: "info.circle")
          } // Button
          Button {
            copyURL(forFeed: feed)
          } label: {
            Label("Library-ImportedFeeds-List-copyFeedURL".boltLocalized, systemImage: "doc.on.doc")
          } // Button
          Button {
            promptRenameFeed(feed)
          } label: {
            Label(UIKitLocalizations.rename, systemImage: "square.and.pencil")
          } // Button
          Button(role: .destructive) {
            promptRemoveFeed(feed)
          } label: {
            Label(UIKitLocalizations.delete, systemImage: "trash")
          } // Button
        } // contextMenu
        .swipeActions {
          Button(UIKitLocalizations.delete) {
            promptRemoveFeed(feed)
          } // Button
          .tint(.red)
          Button(UIKitLocalizations.rename) {
            promptRenameFeed(feed)
          } // Button
          .tint(.orange)
          Button(BoltLocalizations.getInfo) {
            feedForFeedInfoSheet = feed
          } // Button
        } // swipeActions
      } // ForEach
    } // List
    .overlay {
      if model.feeds.isEmpty {
        BoltContentUnavailableView(
          configuration: BoltContentUnavailableViewConfiguration(
            image: Self.emptyStateImage,
            imageSize: CGSize(width: 142, height: 142),
            message: "Library-ImportedFeeds-List-noFeed".boltLocalized,
            shouldDisplayIndicator: false,
            showsMessage: true,
            showsDetailButton: false,
            showsRetryButton: false
          ) // BoltContentUnavailableViewConfiguration
        ) // BoltContentUnavailableView
      } // if
    } // overlay
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .scrollContentBackground(.hidden)
    .background(Color.systemGroupedBackground)
    .navigationTitle("Library-ImportedFeeds-List-title".boltLocalized)
    .navigationBarTitleDisplayMode(.large)
    .userGuideSheet(location: $model.userGuideLocation)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(action: {
          model.userGuideLocation = UserGuideLocation(path: "importing-docsets-from-feeds")
        }, label: {
          Label(
            "Library-FeedList-ToolBar-guideButtonTitle".boltLocalized,
            systemImage: "questionmark.circle"
          )
        })
        .labelStyle(.iconOnly)
      } // ToolbarItem
      ToolbarSpacer(.fixed, placement: .primaryAction)
      ToolbarItem(placement: .confirmationAction) {
        Button(UIKitLocalizations.done, systemImage: "checkmark") {
          dismissCurrentSheetModal?()
        } // Button
        .labelStyle(.toolbar)
      } // ToolbarItem
      ToolbarItemGroup(placement: .bottomBar) {
        Spacer()
        Button {
          showsImportFeedSheet.toggle()
        } label: {
          Image(systemName: "plus")
        } // Button
      } // ToolbarItemGroup
    } // toolbar
    .animation(.default, value: model.feeds.map { $0.id })
    .sheet(item: $selectedFeed) { identifiableFeed in
      SheetContainer {
        LibraryFeedInfoView(identifiableFeed.feed)
      } // SheetContainer
    } // sheet
    .sheet(isPresented: $showsImportFeedSheet) {
      SheetContainer {
        NavigationStack {
          LibraryCustomFeedImportView()
        } // NavigationView
      } // SheetContainer
    } // sheet
    .sheet(item: $feedForFeedInfoSheet) { feed in
      SheetContainer {
        NavigationStack {
          LibraryCustomFeedInfoView(feed: feed)
        } // NavigationView
      } // SheetContainer
    }
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
        confirmAction: (UIKitLocalizations.rename, .default, { newName in
          try? model.onConfirmRenameFeed(feed, newName: newName)
        }),
        cancelAction: (UIKitLocalizations.cancel, { })
      )
    )
  }

  private func promptRemoveFeed(_ feed: CustomFeed) {
    let confirmRemoveFeed: () -> Void = {
      model.onConfirmRemoveFeed(feed)
    }

    if model.hasInstalledDocsets(for: feed) {
      presentRemoveFeedWithInstalledDocsetsAlert(for: feed, onConfirm: confirmRemoveFeed)
    } else {
      presentRemoveFeedAlert(for: feed, onConfirm: confirmRemoveFeed)
    }
  }

  private func presentRemoveFeedAlert(for feed: CustomFeed, onConfirm: @escaping () -> Void) {
    let alertMessage = !feed.displayName.isEmpty ?
      "Library-ImportedFeeds-List-RemoveAlert-removeMessageFormat".boltLocalized(feed.displayName) :
      "Library-ImportedFeeds-List-RemoveAlert-removeFeedMessage".boltLocalized
    GlobalUI.presentAlertController(
      UIAlertController.alert(
        withTitle: "Library-ImportedFeeds-List-RemoveAlert-removeFeedTitle".boltLocalized,
        message: alertMessage,
        confirmAction: (BoltLocalizations.confirm, .destructive, onConfirm),
        cancelAction: (UIKitLocalizations.cancel, { })
      )
    )
  }

  private func presentRemoveFeedWithInstalledDocsetsAlert(for feed: CustomFeed, onConfirm: @escaping () -> Void) {
    let alertMessage = !feed.displayName.isEmpty ?
      "Library-ImportedFeeds-List-RemoveAlert-removeWithInstalledDocsetsMessageFormat".boltLocalized(feed.displayName) :
      "Library-ImportedFeeds-List-RemoveAlert-removeFeedWithInstalledDocsetsMessage".boltLocalized
    GlobalUI.presentAlertController(
      UIAlertController.alert(
        withTitle: "Library-ImportedFeeds-List-RemoveAlert-removeFeedTitle".boltLocalized,
        message: alertMessage,
        confirmAction: (BoltLocalizations.confirm, .destructive, onConfirm),
        cancelAction: (UIKitLocalizations.cancel, { })
      )
    )
  }

  private func copyURL(forFeed feed: CustomFeed) {
    if !feed.urlString.isEmpty {
      UIPasteboard.general.string = feed.urlString
    }
  }

}
