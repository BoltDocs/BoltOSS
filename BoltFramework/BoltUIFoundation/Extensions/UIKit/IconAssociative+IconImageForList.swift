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
import UIKit.UIImage

import BoltServices

public extension EntryIconProvider {

  var iconImageForList: UIImage? {
    let image = iconImage
    return image.isSymbolImage ? image
    : iconImage
      .roundedCorner(
        withSize: CGSize(width: 30, height: 30),
        contentSize: CGSize(width: 18, height: 18),
        backgroundColor: .white,
        cornerRadius: 6,
        borderWidth: 0.25,
        borderColor: .gray
      )
  }

  var iconImageForInfo: UIImage? {
    return iconImage
      .roundedCorner(
        withSize: CGSize(width: 56, height: 56),
        contentSize: CGSize(width: 32, height: 32),
        backgroundColor: .white,
        cornerRadius: 8
      )
  }

}
