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

  static func alert(
    withTitle title: String?,
    message: String?,
    confirmAction: (String?, UIAlertAction.Style, (() -> Void)?)? = nil,
    cancelAction: (String?, (() -> Void)?)? = nil
  ) -> UIAlertController {
    return alert(
      withTitle: title,
      message: message,
      confirmAlertAction: { _ -> UIAlertAction? in
        guard let (title, style, action) = confirmAction else {
          return nil
        }
        return UIAlertAction(title: title, style: style) { _ in
          action?()
        }
      },
      cancelAlertAction: { _ -> UIAlertAction? in
        guard let (title, action) = cancelAction else {
          return nil
        }
        return UIAlertAction(title: title, style: .cancel) { _ in
          action?()
        }
      }
    )
  }

  static func inputAlert(
    withTitle title: String?,
    message: String?,
    initialText: String?,
    placeHolder: String?,
    confirmAction: (String?, UIAlertAction.Style, ((String) -> Void)?)? = nil,
    cancelAction: (String?, (() -> Void)?)? = nil
  ) -> UIAlertController {
    return alert(
      withTitle: title,
      message: message,
      configureBlock: { alert in
        alert.addTextField()
        alert.textFields?.first?.text = initialText
        alert.textFields?.first?.placeholder = placeHolder
      },
      confirmAlertAction: { alert -> UIAlertAction? in
        guard let (title, style, action) = confirmAction else {
          return nil
        }
        return UIAlertAction(title: title, style: style) { _ in
          guard let textFiled = alert.textFields?.first else {
            action?("")
            return
          }
          action?(textFiled.text ?? "")
        }
      },
      cancelAlertAction: { _ -> UIAlertAction? in
        guard let (title, action) = cancelAction else {
          return nil
        }
        return UIAlertAction(title: title, style: .cancel) { _ in
          action?()
        }
      }
    )
  }

  private static func alert(
    withTitle title: String?,
    message: String?,
    configureBlock: ((UIAlertController) -> Void)? = nil,
    confirmAlertAction: ((UIAlertController) -> UIAlertAction?)? = nil,
    cancelAlertAction: ((UIAlertController) -> UIAlertAction?)? = nil
  ) -> UIAlertController {
    return update(
      UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert
      )
    ) { alert in
      configureBlock?(alert)
      if let cancelAlertAction = cancelAlertAction?(alert) {
        alert.addAction(cancelAlertAction)
      }
      if let confirmAlertAction = confirmAlertAction?(alert) {
        alert.addAction(confirmAlertAction)
        if confirmAlertAction.style != .destructive {
          alert.preferredAction = confirmAlertAction
        }
      }
    }
  }

}
