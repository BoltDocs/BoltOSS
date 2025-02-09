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

import BoltTypes

final class SearchServiceImp: SearchService {

  private let docsetIndexer = DocsetIndexer(maxConcurrentTasks: 1)

  private var searchIndices = [String: DocsetSearchIndex]()

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
