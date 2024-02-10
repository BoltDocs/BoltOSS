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

import SwiftUI
import UIKit

import BoltModuleExports
import BoltServices
import BoltUIFoundation

public struct DashFeedSchemeHandler: SchemeHandler {

  public init() { }

  public func matchToHandle(withURL url: URL) -> Bool {
    guard let scheme = DashFeedURLScheme(url: url) else {
      return false
    }
    GlobalUI.dismissAllModals {
      let feedImportViewController = UIHostingController(
        rootView: NavigationView {
          LibraryCustomFeedImportView(feedURL: scheme.feedURL)
        }
      )
      GlobalUI.presentModal(feedImportViewController, completionHandler: nil)
    }
    return true
  }

}
