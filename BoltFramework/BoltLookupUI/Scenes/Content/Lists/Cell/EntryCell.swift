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

import UIKit

import RxCocoa
import RxSwift

import BoltUIFoundation
import BoltUtils

final class EntryCell: UITableViewCell {

  var itemModel: LookupListCellItem?

  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var docsetIconImageView: UIImageView!
  @IBOutlet private weak var typeIconImageView: UIImageView!
  @IBOutlet private weak var promptLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()

    titleLabel.textColor = .label
    promptLabel.textColor = .secondaryLabel
  }

  func configure(forCellModel cellModel: LookupListCellViewModel) {
    titleLabel.text = cellModel.name
    promptLabel.text = cellModel.prompt
    if cellModel.shouldShowDisclosureIndicator {
      accessoryType = .disclosureIndicator
    } else {
      accessoryType = .none
    }
    if let image = cellModel.docsetIcon {
      docsetIconImageView.isHidden = false
      docsetIconImageView.image = image
    } else {
      docsetIconImageView.isHidden = true
    }
    if let image = cellModel.typeIcon {
      typeIconImageView.isHidden = false
      typeIconImageView.image = image
    } else {
      typeIconImageView.isHidden = true
    }
  }

}
