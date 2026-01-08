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

import GSMessages

import Overture

import BoltLocalizations
import BoltServices

public let kFoundationBundle = Bundle.module

public struct ErrorMessageEntity {

  public enum Level {
    case success
    case warning
    case error
  }

  public var description: String
  public var level: Level

  public init(description: String, level: Level = .error) {
    self.description = description
    self.level = level
  }

}

public struct ErrorMessage {
  public init(entity: ErrorMessageEntity, nestedError: Error?) {
    self.entity = entity
    self.nestedError = nestedError
  }

  public var entity: ErrorMessageEntity

  public let nestedError: Error?

}

@MainActor
public struct GlobalUI {

  static weak var currentAlertController: UIAlertController?

  public static func dismissCurrentAlertController(completion: (() -> Void)? = nil) {
    currentAlertController?.dismiss(animated: true, completion: completion)
    currentAlertController = nil
  }

  public static func presentAlertController(
    _ alert: UIAlertController,
    configure: ((UIAlertController) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    dismissCurrentAlertController()
    configure?(alert)
    currentAlertController = alert
    if let targetController = UIApplication.shared.keyWindowOfActiveScene?.topViewController {
      targetController.present(alert, animated: true, completion: completion)
    }
  }

  public static func dismissAllModals(completionHandler: (() -> Void)?) {
    if
      let keyWindow = UIApplication.shared.keyWindowOfActiveScene,
      let rootViewController = keyWindow.rootViewController
    {
      rootViewController.dismiss(animated: true, completion: completionHandler)
    } else {
      completionHandler?()
    }
  }

  public static func presentModal(_ controller: UIViewController, completionHandler: (() -> Void)?) {
    if
      let keyWindow = UIApplication.shared.keyWindowOfActiveScene,
      let rootViewController = keyWindow.rootViewController
    {
      rootViewController.present(controller, animated: true, completion: completionHandler)
    } else {
      completionHandler?()
    }
  }

  public static func showMessageToast(withErrorMessage errorMessage: ErrorMessage) {
    showMessageToast(
      withText: errorMessage.entity.description,
      type: with(errorMessage.entity.level) { level -> GSMessageType in
        switch level {
        case .success:
          return GSMessageType.success
        case .warning:
          return GSMessageType.warning
        case .error:
          return GSMessageType.error
        }
      }
    ) {
    #if DEBUG
      if let error = errorMessage.nestedError {
        presentAlertController(
          UIAlertController.alert(
            withTitle: errorMessage.entity.description,
            message: error.localizedDescription,
            confirmAction: (UIKitLocalizations.ok, .default, nil)
          )
        )
      }
    #endif
    }
  }

  public static func showMessageToast(
    withText text: String,
    type: GSMessageType = .warning,
    tapAction: (() -> Void)? = nil
  ) {
    guard
      let keyWindow = UIApplication.shared.keyWindowOfActiveScene,
      let topViewController = keyWindow.topViewController,
      let targetView = topViewController.view
    else {
      return
    }

    let attributedText = NSAttributedString(
      string: text,
      attributes: [
        .font: GSMessage.font,
      ]
    )

    let paddingX: CGFloat = 14
    let maxWidth = targetView.bounds.width - 20 - paddingX * 2
    let size = attributedText.boundingRect(
      with: CGSize(width: maxWidth, height: 20),
      options: .usesLineFragmentOrigin,
      context: nil
    ).size
    let marginX = (targetView.bounds.width - size.width - paddingX * 2) / 2
    let bottomMargin: CGFloat = targetView.safeAreaInsets.bottom == 0 ? 12 : 0

    GSMessage.showMessageAddedTo(
      attributedText: attributedText,
      type: type,
      options: [
        .cornerRadius(16),
        .height(32),
        .position(.bottom),
        .margin(UIEdgeInsets(top: 0, left: marginX, bottom: bottomMargin, right: marginX)),
        .padding(UIEdgeInsets(top: 6, left: paddingX, bottom: 6, right: paddingX)),
        .handleTap {
          tapAction?()
        },
      ],
      inView: targetView,
      inViewController: nil
    )
  }

}
