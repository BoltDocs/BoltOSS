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

struct LibraryFeedInfoView: View {

  @State private var safariSheetURL: URL?

  struct InfoSection: View {

    private var feed: Feed
    @Binding var safariSheetURL: URL?

    init(feed: Feed, safariSheetURL: Binding<URL?>) {
      self.feed = feed
      self._safariSheetURL = safariSheetURL
    }

    var body: some View {
      Section("Library-FeedInfo-SectionTitles-Docset".boltLocalized) {
        let image = feed.iconImageForList?.image
        LibraryFeedListItemView(
          image: image,
          title: feed.displayName,
          lineLimit: 2
        )
        if let author = feed.author {
          Button {
            safariSheetURL = URL(string: author.link)
          } label: {
            HStack {
              Text("Library-FeedInfo-InfoSection-contributor")
                .layoutPriority(1)
              Spacer()
              Text(author.name)
                .foregroundStyle(.secondary)
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

  }

  typealias VersionsSection = LibraryFeedInfoVersionsSection

  @Environment(\.dismissCurrentSheetModal)
  private var dismissCurrentSheetModal: DismissAction?

  @Injected(\.repositoryRegistry)
  private var repositoryRegistry: RepositoryRegistry

  private var isPlaceHolder: Bool {
    return feed.isUnavailable
  }

  private var placeHolderMessage: String {
    guard feed.isUnavailable else {
      return ""
    }
    if let unavailableMessage = feed.unavailableMessage {
      switch unavailableMessage {
      case .general:
        return "MainFeed-unavailable_general".boltLocalized(feed.displayName)
      case let .message(message):
        let localizedMessage = message.boltLocalized
        if localizedMessage != message {
          return localizedMessage
        }
      }
    }
    return "Library-FeedInfo-docsetNotAvailableHint".boltLocalized(feed.displayName)
  }

  private var feed: Feed

  init(_ feed: Feed) {
    self.feed = feed
  }

  var body: some View {
    NavigationStack {
      Form {
        if !isPlaceHolder {
          InfoSection(feed: feed, safariSheetURL: $safariSheetURL)
          VersionsSection(feed: feed)
        } else {
          Text(placeHolderMessage)
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle(feed.displayName)
      .navigationBarTitleDisplayMode(.inline)
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
      .safariSheet(url: $safariSheetURL)
    }
  }

}
