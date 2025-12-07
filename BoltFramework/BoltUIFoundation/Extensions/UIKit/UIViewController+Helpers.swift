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

public extension UIViewController {

  func configureNavigationBarAppearance(enforceLargeTitle: Bool) {
    guard
      let navigationBar = (navigationController?.navigationBar) ?? (self as? UINavigationController)?.navigationBar
    else {
      return
    }

    navigationBar.prefersLargeTitles = enforceLargeTitle

    navigationItem.largeTitleDisplayMode = enforceLargeTitle ? .always : .never
  }

  func embedInNavigation() -> UINavigationController {
    return UINavigationController(rootViewController: self)
  }

  func removeChild(_ childController: UIViewController, with closure: (UIView) -> Void) {
    childController.willMove(toParent: nil)
    childController.removeFromParent()
    closure(childController.view)
    childController.didMove(toParent: nil)
  }

  func addChild(_ childController: UIViewController, with closure: (UIView) -> Void) {
    childController.willMove(toParent: self)
    addChild(childController)
    closure(childController.view)
    childController.didMove(toParent: self)
  }

}
