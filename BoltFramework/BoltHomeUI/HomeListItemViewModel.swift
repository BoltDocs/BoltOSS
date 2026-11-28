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
  var subtitle: String?
  var image: IdentifiableImage?

  var uuid: UUID

  init(queryResult: LibraryInstallationQueryResult) {
    let record = queryResult.record
    uuid = record.uuid
    subtitle = Self.subtitle(forRecord: record)
    title = record.displayName
    image = {
      switch queryResult {
      case let .docset(docset):
        return docset.iconImageForList
      case let .broken(installation):
        let symbolName = "text.book.closed"
        if let uiImage = UIImage(systemName: symbolName) {
          return IdentifiableImage(image: uiImage, id: symbolName)
        }
      }
      return nil
    }()
  }

  private static func subtitle(forRecord record: LibraryRecord) -> String {
    if record.hasNewerVersion {
      return "Home-List-Items-updateAvailable".boltLocalized
    } else if record.installedAsLatestVersion {
      return "Home-List-Items-latest".boltLocalized
    } else {
      return record.version.displayVersion
    }
  }

  func queryInstallation() -> LibraryInstallationQueryResult? {
    return libraryDocsetsManager.installedDocsets.first { $0.record.uuid == uuid }
  }

  func queryDocset() -> Docset? {
    guard let installation = queryInstallation(), case let .docset(docset) = installation else {
      return nil
    }
    return docset
  }

  // MARK: - Actions

  func deleteItem() {
    guard let record = libraryDocsetsManager.installedRecords.first(where: { $0.uuid == uuid }) else {
      return
    }
    try? libraryDocsetsManager.uninstallDocset(forRecord: record, deleteBookmarksAndHistory: true)
  }

}

extension HomeListItemViewModel: Hashable {

  static func == (lhs: Self, rhs: Self) -> Bool {
    return
      lhs.uuid == rhs.uuid &&
      lhs.title == rhs.title &&
      lhs.subtitle == rhs.subtitle &&
      lhs.image?.id == rhs.image?.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
    hasher.combine(title)
    hasher.combine(subtitle)
    hasher.combine(image?.id)
  }

}
