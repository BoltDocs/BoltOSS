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

import UIKit

public extension UIApplication {

  var keyWindowOfActiveScene: UIWindow? {
    return connectedScenes.firstMap { scene -> UIWindow? in
      if let scene = scene as? UIWindowScene, let window = scene.keyWindow {
        return window
      }
      return nil
    }
  }

  var allWindows: [UIWindow] {
    return connectedScenes.compactMap { scene -> UIWindow? in
      if let scene = scene as? UIWindowScene, let window = scene.keyWindow {
        return window
      }
      return nil
    }
  }

  func refreshAllWindowAppearances() {
    for window in allWindows {
      for view in window.subviews {
        view.removeFromSuperview()
        window.addSubview(view)
      }
    }
  }

}
