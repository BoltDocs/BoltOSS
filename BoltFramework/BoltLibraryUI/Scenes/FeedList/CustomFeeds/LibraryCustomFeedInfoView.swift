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
import BoltRepository
import BoltUIFoundation

import Factory
import Overture

struct LibraryCustomFeedInfoView: View {

  private (set) var feed: CustomFeed

  @Environment(\.dismiss)
  private var dismiss: DismissAction

  @Injected(\.feedsService)
  private var feedsService: FeedsService

  @State var feedName: String

  init(feed: CustomFeed) {
    self.feed = feed
    self.feedName = feed.displayName
  }

  var body: some View {
    List {
      Section(
        header:
          VStack(alignment: .center, spacing: 12) {
            Image(uiImage: feed.iconImageForInfo ?? UIImage())
          }
          .frame(maxWidth: .infinity)
          .padding(.bottom, 12)
      ) {
        TextField("", text: $feedName)
          .onSubmit {
            onTextFieldSubmit()
          }
      }
      Section("Library-ImportedFeeds-Info-feedURLSectionTitle".boltLocalized) {
        Button {
          copyURL(forFeed: feed)
        } label: {
          Text(feed.urlString)
            .foregroundColor(.primary)
            .lineLimit(1)
        }
      }
    }
    .navigationTitle(feed.displayName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(UIKitLocalization.done) {
          onTextFieldSubmit()
          dismiss()
        }
      }
    }
  }

  private func onTextFieldSubmit() {
    renameFeed(feed, newName: feedName)
  }

  private func renameFeed(_ feed: CustomFeed, newName: String) {
    guard !newName.isEmpty, newName != feed.displayName else {
      return
    }
    let newFeed = update(feed) {
      $0.displayName = newName
    }
    try? feedsService.updateCustomFeed(newFeed)
  }

  private func copyURL(forFeed feed: CustomFeed) {
    if !feed.urlString.isEmpty {
      UIPasteboard.general.string = feed.urlString
      GlobalUI.showMessageToast(
        withText: "Library-ImportedFeeds-Info-feedURLCopiedToast".boltLocalized,
        type: .success
      )
    }
  }

}
