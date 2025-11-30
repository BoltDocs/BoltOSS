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

import Factory

import BoltLocalizations
import BoltServices
import BoltUIFoundation
import BoltUtils

struct LibraryCustomFeedImportView: View {

  @Injected(\.feedsService)
  private var feedsService: FeedsService

  @Environment(\.dismiss)
  private var dismiss: DismissAction

  init(feedURL: URL? = nil) {
    _urlInput = .init(initialValue: feedURL?.absoluteString ?? "")
    _name = .init(initialValue: feedURLScheme?.feedFileName ?? "")
  }

  @State private var urlInput = ""
  @State private var name = ""
  @State private var isLoading = false

  private var doneButtonDisabled: Bool {
    return urlInput.isEmpty || name.isEmpty || feedURLScheme == nil
  }

  private var feedURLScheme: DashFeedURLScheme? {
    return DashFeedURLScheme(urlString: urlInput)
  }

  var body: some View {
    Form {
      Section {
        TextField(
          "Library-ImportedFeeds-Import-urlPlaceHolder".boltLocalized,
          text: $urlInput
        )
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .textContentType(.URL)
        .keyboardType(.URL)
        TextField(
          "Library-ImportedFeeds-Import-nameFeedName".boltLocalized,
          text: $name
        )
      }
    }
    .navigationTitle("Library-ImportedFeeds-Import-title".boltLocalized)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button(UIKitLocalizations.cancel, systemImage: "xmark") {
          dismiss()
        }
        .labelStyle(.toolbar)
      }
      ToolbarItem(placement: .confirmationAction) {
        if !isLoading {
          Button(UIKitLocalizations.done, systemImage: "checkmark") {
            guard let scheme = feedURLScheme else {
              return
            }
            Task {
              isLoading = true
              defer {
                isLoading = false
              }
              do {
                let feed = CustomFeed(
                  entity: CustomFeedEntity(
                    name: name,
                    urlString: scheme.feedURL.absoluteString
                  )
                )
                // pre-check the feed is valid
                let _ = try await feed.fetchEntries()
                try feedsService.insertCustomFeed(feed)
                dismiss()
              } catch {
                GlobalUI.showMessageToast(withErrorMessage: ErrorMessage(entity: .failedToImportCustomFeed, nestedError: error))
              }
            }
          }
          .labelStyle(.toolbar)
          .disabled(doneButtonDisabled)
        } else {
          ProgressView()
            .progressViewStyle(.circular)
        }
      }
    }
    .onChange(of: urlInput) {
      if let newName = feedURLScheme?.feedFileName, !newName.isEmpty {
        self.name = newName
      }
    }
  }

}
