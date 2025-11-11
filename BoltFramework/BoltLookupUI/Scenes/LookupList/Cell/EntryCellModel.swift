//
// Copyright (C) 2023 Bolt Contributors
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

import UIKit.UIImage

import RxCocoa
import RxSwift

import BoltServices
import BoltUIFoundation

public struct LookupListCellViewModel {
  let name: String
  let prompt: String?
  let shouldShowDisclosureIndicator: Bool
  let docsetIcon: UIImage?
  let typeIcon: UIImage?
}

public protocol LookupListCellItem {

  var viewModel: LookupListCellViewModel { get }

}

struct LookupListDocsetItem: LookupListCellItem {

  let docset: Docset
  let viewModel: LookupListCellViewModel

  init(docset: Docset) {
    self.docset = docset
    viewModel = LookupListCellViewModel(
      name: docset.displayName,
      prompt: "\(docset.keyword.inAppSearch):",
      shouldShowDisclosureIndicator: true,
      docsetIcon: docset.iconImage.image,
      typeIcon: nil
    )
  }

}

struct LookupListEntryItem: LookupListCellItem {

  let docset: Docset
  let entry: Entry
  let viewModel: LookupListCellViewModel

  init(docset: Docset, entry: Entry) {
    self.docset = docset
    self.entry = entry

    let type = entry.type ?? EntryType.unknown
    viewModel = LookupListCellViewModel(
      name: entry.name,
      prompt: "",
      shouldShowDisclosureIndicator: false,
      docsetIcon: nil,
      typeIcon: type.iconImage.image
    )
  }

}

struct LookupListTypeItem: LookupListCellItem {

  let docset: Docset
  let typeCountPair: TypeCountPair
  let viewModel: LookupListCellViewModel

  init(typeCountPair: TypeCountPair, docset: Docset) {
    self.docset = docset
    self.typeCountPair = typeCountPair

    let type = typeCountPair.type ?? EntryType.unknown
    viewModel = LookupListCellViewModel(
      name: type.plural,
      prompt: String(typeCountPair.count),
      shouldShowDisclosureIndicator: true,
      docsetIcon: nil,
      typeIcon: type.iconImage.image
    )
  }

}
