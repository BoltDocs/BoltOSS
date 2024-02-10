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

import Overture

public extension UIAlertController {

  static func controllerInAlertStyle(
    withTitle title: String?,
    message: String?,
    confirmAction: (String?, UIAlertAction.Style, (() -> Void)?)? = nil,
    cancelAction: (String?, (() -> Void)?)? = nil
  ) -> UIAlertController {
    return update(
      UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert
      )
    ) { alert in
      if let (title, style, action) = confirmAction {
        alert.addAction(
          UIAlertAction(title: title, style: style) { _ in
            action?()
          }
        )
      }
      if let (title, action) = cancelAction {
        alert.addAction(
          UIAlertAction(title: title, style: .cancel) { _ in
            action?()
          }
        )
      }
    }
  }

}
