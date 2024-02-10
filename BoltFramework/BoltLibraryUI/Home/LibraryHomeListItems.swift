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

import Foundation
import SwiftUI

import BoltTypes
import BoltUtils

extension LibraryHomeListViewModel {

  static let defaultItems = [
    Section(
      id: "local",
      header: "Advanced",
      items: [
        Section.Item(
          name: "Custom Feeds",
          icon: BoltImageResource(named: "overview-icons/custom-feed", in: .module),
          description: "Feeds with custom URL or imported from the web",
          itemType: .customFeeds
        ),
        Section.Item(
          name: "Install from Files",
          icon: BoltImageResource(named: "overview-icons/local", in: Bundle.module),
          description: "Install transferred docsets from files",
          itemType: .transfer
        ),
      ]
    ),
  ]

}

extension LibraryHomeListView {

  @ViewBuilder
  func destinationView(forRepositoryIdentifier identifier: RepositoryIdentifier) -> some View {
    // swiftlint:disable:previous unavailable_function
    fatalError("LibraryHomeListView: repository identifier: \(identifier) is not available.")
  }

}
