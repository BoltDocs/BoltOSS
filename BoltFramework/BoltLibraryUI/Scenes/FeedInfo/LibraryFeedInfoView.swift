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

  struct InfoSection: View {
    private var feed: Feed

    init(feed: Feed) { self.feed = feed }

    var body: some View {
      Section("Feed") {
        HStack {
          let image = feed.iconImageForList?.image
          Image(uiImage: image ?? UIImage())
            .if(image?.isSymbolImage ?? false) {
              $0.renderingMode(.template)
            }
            .foregroundColor(Color.primary)
            .frame(width: 30, height: 30)
          Text(feed.displayName)
        }
      }
    }
  }

  typealias VersionsSection = LibraryFeedInfoVersionsSection

  @Environment(\.dismissSheetModal)
  private var dismissSheetModal: DismissAction?

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
      let localizedMessage = unavailableMessage.boltLocalized
      if localizedMessage != feed.unavailableMessage {
        return localizedMessage
      }
    }
    return "Library-FeedsInfo-docsetNotAvailableHint".boltLocalized(feed.displayName)
  }

  private var feed: Feed

  init(_ feed: Feed) {
    self.feed = feed
  }

  var body: some View {
    Form {
      if !isPlaceHolder {
        InfoSection(feed: feed)
        VersionsSection(feed: feed)
      } else {
        Text(placeHolderMessage)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle(feed.displayName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(UIKitLocalizations.done, systemImage: "checkmark") {
          dismissSheetModal?()
        }
        .labelStyle(.toolbar)
      }
    }
  }

}
