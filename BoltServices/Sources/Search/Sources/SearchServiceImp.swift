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
import Factory

import BoltDocsets
import BoltTypes
import BoltUtils

final class SearchServiceImp: SearchService, LoggerProvider {

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  private let docsetIndexer = DocsetIndexer(maxConcurrentTasks: 1)

  private var searchIndices = [String: DocsetSearchIndex]()

  private var cancellables = Set<AnyCancellable>()

  init() {
    libraryDocsetsManager
      .installedDocsets()
      .withPrevious([])
      .sink { [weak self] previous, current in
        guard let self = self else {
          return
        }

        let mapToDocset: (LibraryInstallationQueryResult) -> Docset? = {
          if case let .docset(docset) = $0 {
            return docset
          }
          return nil
        }

        let prevDocsets = Set(previous.compactMap(mapToDocset))
        let currentDocsets = Set(current.compactMap(mapToDocset))

        let addedDocsets = currentDocsets.subtracting(prevDocsets)

        Self.logger.info("queue to index newly added docsets: \(addedDocsets)")

        Task {
          for docset in addedDocsets {
            let searchIndex = await self.searchIndex(forDocset: docset)
            await self.queueToCreateSearchIndex(searchIndex)
          }
        }
      }
      .store(in: &cancellables)
  }

  func searchIndex(forDocsetPath docsetPath: String, identifier: String) async -> DocsetSearchIndex {
    if let index = searchIndices[docsetPath] {
      return index
    }
    let index = await DocsetSearchIndex(docsetPath: docsetPath, identifier: identifier)
    searchIndices[docsetPath] = index
    return index
  }

  func searchIndex(forDocset docset: Docset) async -> DocsetSearchIndex {
    if let index = searchIndices[docset.path] {
      return index
    }
    let index = await DocsetSearchIndex(docset: docset)
    searchIndices[docset.path] = index
    return index
  }

  func queueToCreateSearchIndex(_ index: DocsetSearchIndex) async {
    await docsetIndexer.addSearchIndexToQueue(index)
  }

}
