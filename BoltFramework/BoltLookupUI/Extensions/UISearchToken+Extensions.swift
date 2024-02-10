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

import Foundation
import UIKit

extension UISearchToken {

  static func imageOnlyToken(withImage image: UIImage) -> Self {
    let size = CGSize(width: 20, height: 16)
    let imageRect = CGRect(x: 4, y: 0, width: 16, height: 16)
    let image = UIGraphicsImageRenderer(size: size).image { _ in
      image.draw(in: imageRect)
    }
    return Self(icon: image, text: "\u{200B}")
  }

}
