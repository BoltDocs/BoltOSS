//
// Copyright (C) 2025 Bolt Contributors
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

import BoltDatabase
import BoltLocalizations
import BoltTypes

extension HomeViewController {

  static func createDiagnosticsMenu() -> UIMenu {
    return UIMenu(
      title: "Localizations-General-diagnostics".boltLocalized,
      image: UIImage(systemName: "ladybug"),
      children: [
        UIAction(
          title: "Mock Orphan Record",
          image: UIImage(systemName: "play")
        ) { _ in
          mockOrphanRecord()
        },
      ]
    )
  }

  private static func mockOrphanRecord() {
    let docsetInstallation = DocsetInstallation(
      uuid: UUID(),
      name: "Bash",
      version: "1.0",
      installedAsLatestVersion: false,
      repository: .main
    )
    try? LibraryDatabase.shared.insertDocsetInstallation(docsetInstallation)
  }

}
