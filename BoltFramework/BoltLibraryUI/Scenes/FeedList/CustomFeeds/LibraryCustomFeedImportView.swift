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
    return DashFeedURLScheme(feedURLString: urlInput) ?? DashFeedURLScheme(urlString: urlInput)
  }

  var body: some View {
    Form {
      Section {
        TextField("Feed URL", text: $urlInput)
          .autocapitalization(.none)
          .disableAutocorrection(true)
        TextField("Feed Name", text: $name)
      }
    }
    .navigationTitle("Import Feed")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button(UIKitLocalization.cancel) {
          dismiss()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        if !isLoading {
          Button(UIKitLocalization.done) {
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
          .disabled(doneButtonDisabled)
        } else {
          ProgressView()
            .progressViewStyle(.circular)
        }
      }
    }
    .onChange(of: urlInput) { [prevInput = urlInput] newValue in
      if prevInput.isEmpty {
        self.name = feedURLScheme?.feedFileName ?? ""
      } else if newValue.isEmpty {
        self.name = ""
      }
    }
  }

}
