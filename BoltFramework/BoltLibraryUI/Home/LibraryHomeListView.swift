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
import BoltUIFoundation
import BoltUtils

public struct LibraryHomeListView: View {

  @Environment(\.dismissCurrentSheetModal)
  private var dismissCurrentSheetModal: DismissAction?

  typealias Item = LibraryHomeListViewModel.Section.Item

  private let models = LibraryHomeListViewModel.defaultItems

  @State private var safariSheetURL: URL?

  public init() { }

  @ViewBuilder
  private func destinationView(for itemType: LibraryHomeListViewModel.ItemType) -> some View {
    switch itemType {
    case let .repository(id: identifier):
      destinationView(forRepositoryIdentifier: identifier)
    case .transfer:
      LibraryTransferView()
    case .customFeeds:
      LibraryCustomFeedListView()
    }
  }

  public var body: some View {
    NavigationView {
      List {
        ForEach(models) { section in
          Section(
            header: Text(section.header),
            footer: Group {
              if let footer = section.footer {
                Text(footer)
                  .environment(\.openURL, OpenURLAction { url in
                    safariSheetURL = url
                    return .handled
                  })
              }
            }
          ) {
            ForEach(section.items) { item in
              NavigationLink(destination: DeferredView { destinationView(for: item.itemType) }) {
                LibraryHomeListItemView(itemModel: item)
              }
            }
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Library-Home-title".boltLocalized)
      .navigationBarTitleDisplayMode(.large)
      .safariSheet(url: $safariSheetURL)
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
    }
    .navigationViewStyle(.stack)
  }

}
