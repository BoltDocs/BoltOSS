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

import UIKit

import Factory

import BoltDocsets
import BoltTypes

struct HomeListItemViewModel {

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  var title: String?
  var subTitle: String?
  var image: IdentifiableImage?

  var uuid: UUID {
    return queryResult.record.uuid
  }

  var record: LibraryRecord {
    return queryResult.record
  }

  var docset: Docset? {
    switch queryResult {
    case let .docset(docset):
      return docset
    case .broken:
      return nil
    }
  }

  private var queryResult: LibraryInstallationQueryResult

  init(queryResult: LibraryInstallationQueryResult) {
    self.queryResult = queryResult
    switch queryResult {
    case let .docset(docset):
      title = docset.displayName
      subTitle = { () -> String in
        if docset.installedAsLatestVersion {
          return "Home-List-Items-latest".boltLocalized
        } else {
          return docset.version
        }
      }()
      image = docset.iconImageForList
    case let .broken(installation):
      title = installation.name
      if installation.installedAsLatestVersion {
        subTitle = installation.version
      }
      let symbolName = "text.book.closed"
      if let uiImage = UIImage(systemName: symbolName) {
        image = IdentifiableImage(image: uiImage, id: symbolName)
      }
    }
  }

  func deleteItem() {
    try? libraryDocsetsManager.uninstallDocset(forRecord: queryResult.record)
  }

}

extension HomeListItemViewModel: Hashable {

  static func == (lhs: Self, rhs: Self) -> Bool {
    return
      lhs.uuid == rhs.uuid &&
      lhs.title == rhs.title &&
      lhs.subTitle == rhs.subTitle &&
      lhs.image?.id == rhs.image?.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
    hasher.combine(title)
    hasher.combine(subTitle)
    hasher.combine(image?.id)
  }

}
