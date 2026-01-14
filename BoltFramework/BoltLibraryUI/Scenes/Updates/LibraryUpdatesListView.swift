//
// Copyright (C) 2025 Bolt Contributors
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

import Factory

import BoltDocsets
import BoltLocalizations
import BoltTypes
import BoltUIFoundation
import BoltUtils

@MainActor
private class LibraryUpdatesListViewModel: ObservableObject, LoggerProvider {

  @Injected(\.docsetUpdateChecker)
  private var docsetUpdateChecker: DocsetUpdateChecker

  @Published var updatableEntries = [FeedEntry]()

  func fetchUpdates() async {
    updatableEntries = await docsetUpdateChecker.fetchDocsetUpdates(useCachedEntries: false)
      .map(\.feedEntry)
  }

}

public struct LibraryUpdatesListView: View {

  @Environment(\.dismissCurrentSheetModal)
  private var dismissCurrentSheetModal: DismissAction?

  @StateObject private var viewModel = LibraryUpdatesListViewModel()

  static let emptyStateImage: UIImage = BoltImageResource(named: "overview-icons/downloads", in: .module).platformImage!

  public init() { }

  public var body: some View {
    NavigationView {
      List {
        ForEach(viewModel.updatableEntries, id: \.id) { entry in
          NavigationLink(
            destination: DeferredView { LibraryFeedEntryView(entry) }
          ) {
            DownloadProgressListItemView(
              identifier: entry.id,
              title: entry.feed.displayName,
              subtitle: entry.isTrackedAsLatest ? "Library-Updates-Items-latest".boltLocalized : entry.version,
              preventsHighlight: true
            )
          }
        }
      }
      .background(Color.systemGroupedBackground)
      .navigationTitle("Library-Updates-title".boltLocalized)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(UIKitLocalizations.done, systemImage: "checkmark") {
            dismissCurrentSheetModal?()
          }
          .labelStyle(.toolbar)
        }
        if !RuntimeEnvironment.hidesUnfinishedFeatures {
          ToolbarItem(placement: .bottomBar) {
            Button("Library-Updates-updateAllButtonTitle".boltLocalized) {
              dismissCurrentSheetModal?()
            }
          }
        }
      }
    }
    .navigationViewStyle(.stack)
    .task {
      await viewModel.fetchUpdates()
    }
  }

}
