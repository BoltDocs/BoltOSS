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

final class SafariActivity: UIActivity {

  var url: URL?

  override var activityImage: UIImage? {
    return UIImage(
      systemName: "safari",
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 21.5, weight: .regular)
    )
  }

  override var activityTitle: String? {
    return NSLocalizedString("Open in Safari", comment: "")
  }

  override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
    for item in activityItems {
      if
        let url = item as? URL,
        UIApplication.shared.canOpenURL(url)
      {
        return true
      }
    }
    return false
  }

  override func prepare(withActivityItems activityItems: [Any]) {
    for item in activityItems {
      if
        let url = item as? URL,
        UIApplication.shared.canOpenURL(url)
      {
        self.url = url
      }
    }
  }

  override func perform() {
    if let url = self.url {
      UIApplication.shared.open(url, options: [:]) { [weak self] completed in
        self?.activityDidFinish(completed)
      }
    } else {
      activityDidFinish(false)
    }
  }

}
