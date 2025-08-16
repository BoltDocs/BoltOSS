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

import BoltLibraryUI
import BoltPreferencesUI

import BoltUIFoundation

struct BoltAppNavigator {

  static func presentLibrary(forWindow window: UIWindow) {
    let homeViewController = UIHostingController(
      rootView: SheetContainer { LibraryHomeListView() }
    )
    homeViewController.modalPresentationStyle = .formSheet
    if let root = window.topViewController {
      root.present(homeViewController, animated: true)
    }
  }

  static func presentPreferences(forWindow window: UIWindow) {
    let preferencesViewController = UIHostingController(rootView: PreferencesHomeView())
    preferencesViewController.modalPresentationStyle = .formSheet
    if let root = window.topViewController {
      root.present(preferencesViewController, animated: true)
    }
  }

  static func presentDownloads(forWindow window: UIWindow) {
    let downloadsViewController = UIHostingController(
      rootView: SheetContainer { LibraryDownloadsListView() }
    )
    downloadsViewController.modalPresentationStyle = .formSheet
    if let root = window.topViewController {
      root.present(downloadsViewController, animated: true)
    }
  }

}
